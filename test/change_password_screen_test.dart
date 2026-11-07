import 'dart:async';
import 'package:address_manager/l10n/app_localizations.dart';
import 'package:address_manager/screens/change_password_screen.dart';
import 'package:address_manager/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/email_change_fakes.dart';

class _User extends EmailTestUser {
  String? updateError;
  Completer<void>? pending;
  final passwords = <String>[];
  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add('update');
    passwords.add(newPassword);
    if (pending != null) await pending!.future;
    if (updateError != null) {
      throw FirebaseAuthException(code: updateError!, message: 'INTERNAL_DETAILS');
    }
  }
}

Widget _app(Widget home, {String language = 'en'}) => MaterialApp(
  locale: Locale(language), localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales, home: home,
);

void main() {
  late _User user;
  late EmailTestAuth auth;
  setUp(() { user = _User(); auth = EmailTestAuth(user); });
  Future<void> open(WidgetTester tester, {String language = 'en'}) async {
    await tester.pumpWidget(_app(ChangePasswordScreen(auth: auth, uid: user.uid), language: language));
    await tester.pumpAndSettle();
  }
  Future<void> fill(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), i == 0 ? ' old pass ' : ' NEW pass ');
    }
  }
  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  testWidgets('Reauth precedes update, uses actual email and exact passwords, clears fields', (tester) async {
    user.address = 'actual@example.invalid';
    await open(tester);
    await fill(tester);
    final controllers = tester.widgetList<TextFormField>(find.byType(TextFormField)).map((w) => w.controller!).toList();
    await save(tester);
    expect(user.calls, ['reauth', 'update']);
    expect(user.suppliedEmail, user.address);
    expect(user.suppliedPassword, ' old pass ');
    expect(user.passwords, [' NEW pass ']);
    expect(controllers.every((c) => c.text.isEmpty), isTrue);
    expect(find.byType(TextFormField), findsNothing);
    expect(auth.currentUser, same(user));
  });

  testWidgets('Validation rejects empty, short and nonidentical passwords', (tester) async {
    await open(tester);
    await save(tester);
    expect(find.text('Enter a password.'), findsNWidgets(3));
    await fill(tester);
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await save(tester);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), ' NEW pass');
    await save(tester);
    expect(user.calls, isEmpty);
  });

  for (final condition in ['signed-out', 'different-uid', 'unverified', 'no-email', 'provider']) {
    testWidgets('Blocks unavailable account: $condition', (tester) async {
      switch (condition) {
        case 'signed-out': auth.user = null;
        case 'different-uid': auth.user = _User();
        case 'unverified': user.verified = false;
        case 'no-email': user.address = '';
        case 'provider': user.provider = 'google.com';
      }
      await open(tester);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
      expect(user.calls, isEmpty);
    });
  }

  for (final code in ['wrong-password', 'invalid-credential', 'network-request-failed', 'too-many-requests', 'user-disabled', 'requires-recent-login']) {
    testWidgets('Reauth $code never updates password', (tester) async {
      user.reauthError = code;
      await open(tester); await fill(tester); await save(tester);
      expect(user.calls, ['reauth']);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.textContaining('INTERNAL_DETAILS'), findsNothing);
    });
  }

  testWidgets('Session replacement during reauth prevents update', (tester) async {
    user.afterReauth = () => auth.user = _User();
    await open(tester); await fill(tester); await save(tester);
    expect(user.calls, ['reauth']);
  });

  for (final code in ['weak-password', 'requires-recent-login', 'too-many-requests', 'user-disabled', 'network-request-failed']) {
    testWidgets('Update $code is handled without success or retry', (tester) async {
      user.updateError = code;
      await open(tester); await fill(tester); await save(tester);
      expect(user.calls, ['reauth', 'update']);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(tester.widget<TextFormField>(find.byType(TextFormField).at(1)).controller!.text, ' NEW pass ');
      expect(find.textContaining('INTERNAL_DETAILS'), findsNothing);
      if (code == 'network-request-failed') {
        expect(find.textContaining('It may already have changed.'), findsOneWidget);
      }
    });
  }

  testWidgets('Pending operation blocks duplicate submission and closing; disposal is safe', (tester) async {
    user.pending = Completer<void>();
    await open(tester); await fill(tester);
    final submit = tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!;
    submit(); submit();
    await tester.pump();
    expect(user.passwords.length, 1);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    user.pending!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ru', 'en', 'pl', 'uk']) {
    testWidgets('Localized validation: $language', (tester) async {
      await open(tester, language: language); await save(tester);
      final loc = AppLocalizations.of(tester.element(find.byType(ChangePasswordScreen)))!;
      expect(find.text(loc.passwordRequired), findsNWidgets(3));
      expect(user.calls, isEmpty);
    });
  }

  testWidgets('Active profile opens common screen and returns without changing data', (tester) async {
    final store = EmailTestStore();
    await tester.pumpWidget(_app(UserProfileScreen(auth: auth, firestore: store)));
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(tester.element(find.byType(UserProfileScreen)))!;
    final button = find.text(loc.changePassword);
    await tester.ensureVisible(button); await tester.tap(button); await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    await tester.tap(find.text(loc.passwordBackToProfile)); await tester.pumpAndSettle();
    expect(find.byType(UserProfileScreen), findsOneWidget);
    expect(store.transactions, 0);
  });
}
