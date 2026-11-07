import 'dart:async';
import 'package:address_manager/l10n/app_localizations.dart';
import 'package:address_manager/screens/change_email_screen.dart';
import 'package:address_manager/screens/user_profile_screen.dart';
import 'package:address_manager/services/email_change_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/email_change_fakes.dart';

Widget _app(Widget home, {String language = 'en'}) => MaterialApp(
  locale: Locale(language), localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales, home: home,
);

Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  late EmailTestUser user;
  late EmailTestAuth auth;
  late EmailTestStore store;
  late EmailChangeService service;
  setUp(() {
    user = EmailTestUser(); auth = EmailTestAuth(user); store = EmailTestStore();
    service = EmailChangeService(auth: auth, firestore: store, uid: user.uid);
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(_app(ChangeEmailScreen(service: service)));
    await tester.pumpAndSettle();
  }
  Future<void> send(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(1), '  new@example.invalid  ');
    await _tap(tester, 'Send confirmation');
  }

  testWidgets('Validation rejects blank, malformed and unchanged email', (tester) async {
    await open(tester);
    await _tap(tester, 'Send confirmation');
    expect(find.text('Enter your email address.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'bad');
    await _tap(tester, 'Send confirmation');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), user.email);
    await _tap(tester, 'Send confirmation');
    expect(find.text('Enter an email different from your current address.'), findsOneWidget);
    expect(user.sent, isEmpty);
    expect(store.transactions, 0);
  });

  testWidgets('Sent is not changed; check waits for actual Auth email and then syncs', (tester) async {
    await open(tester);
    await send(tester);
    expect(user.sent, ['new@example.invalid']);
    expect(store.transactions, 0);
    expect(find.text('Email changed and profile synchronized.'), findsNothing);
    final resend = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(resend.onPressed, isNull);
    await _tap(tester, 'I confirmed my new email');
    expect(find.text('The new email is not confirmed yet. Check your inbox and the link.'), findsOneWidget);
    expect(store.transactions, 0);
    user.confirmedAddress = 'new@example.invalid';
    await _tap(tester, 'I confirmed my new email');
    expect(store.updates, [{'email': 'new@example.invalid'}]);
    expect(find.text('Email changed and profile synchronized.'), findsOneWidget);
    expect(user.sent, hasLength(1));
  });

  testWidgets('Recent login prompts current password, keeps its whitespace and retries once', (tester) async {
    user.recentLoginRequired = true;
    await open(tester);
    await send(tester);
    expect(find.text('Enter your current password to confirm your identity.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), '  exact password  ');
    await _tap(tester, 'Send confirmation');
    expect(user.suppliedPassword, '  exact password  ');
    expect(user.suppliedEmail, 'old@example.invalid');
    expect(user.calls, ['send', 'reauth', 'send']);
    expect(user.sent, hasLength(1));
  });

  testWidgets('Non-password provider does not show password form', (tester) async {
    user.provider = 'google.com'; user.recentLoginRequired = true;
    await open(tester);
    await send(tester);
    expect(find.text('Sign in again using your account provider. Password reauthentication is not available for this account.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(user.calls, ['send']);
  });

  testWidgets('Firestore denial offers sync-only retry without another email', (tester) async {
    await open(tester);
    await send(tester);
    user.confirmedAddress = 'new@example.invalid'; store.writeError = 'permission-denied';
    await _tap(tester, 'I confirmed my new email');
    expect(find.textContaining('Your Auth email changed, but the profile could not be synchronized.'), findsOneWidget);
    expect(find.textContaining('Access to this profile was denied.'), findsOneWidget);
    expect(find.text('Email changed and profile synchronized.'), findsNothing);
    store.writeError = null;
    await _tap(tester, 'Retry profile synchronization');
    expect(user.sent, hasLength(1));
    expect(store.data!['email'], 'new@example.invalid');
    expect(find.text('Email changed and profile synchronized.'), findsOneWidget);
  });

  testWidgets('Opening profile reconciles stale email; failed sync retries independently', (tester) async {
    user.address = 'new@example.invalid'; store.writeError = 'permission-denied';
    await tester.pumpWidget(_app(UserProfileScreen(auth: auth, firestore: store)));
    await tester.pumpAndSettle();
    expect(find.text('new@example.invalid'), findsOneWidget);
    expect(find.textContaining('Your Auth email changed, but the profile could not be synchronized.'), findsOneWidget);
    expect(store.data!['email'], 'old@example.invalid');
    store.writeError = null;
    await _tap(tester, 'Retry profile synchronization');
    expect(store.data!['email'], 'new@example.invalid');
    expect(store.data!['name'], 'Name');
    expect(user.sent, isEmpty);
  });

  testWidgets('Profile without document stays missing and is not synthesized by sync', (tester) async {
    store.data = null;
    await tester.pumpWidget(_app(UserProfileScreen(auth: auth, firestore: store)));
    await tester.pumpAndSettle();
    expect(find.text('Your profile has not been created yet. Fill it in to continue.'), findsOneWidget);
    expect(store.transactions, 0);
    expect(store.data, isNull);
  });

  for (final entry in {
    'invalid-email': 'Enter a valid email address.',
    'email-already-in-use': 'This email cannot be used. Choose another address.',
    'network-request-failed': 'Connection failed. Check your network and try again.',
    'too-many-requests': 'Too many requests. Please wait and try again.',
    'expired-action-code': 'The link is expired or invalid. Request a new confirmation email.',
  }.entries) {
    testWidgets('Friendly error ${entry.key} does not expose exception details', (tester) async {
      user.sendError = entry.key;
      await open(tester);
      await send(tester);
      expect(find.text(entry.value), findsOneWidget);
      expect(find.textContaining('INTERNAL_DETAILS'), findsNothing);
      expect(store.transactions, 0);
    });
  }

  testWidgets('Duplicate taps send once and disposal cancels timer safely', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.invalid');
    final send = tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!;
    send(); send();
    await tester.pumpAndSettle();
    expect(user.sent, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Normalized address comparison writes the actual Auth value', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).at(1), 'New@Example.Invalid');
    await _tap(tester, 'Send confirmation');
    user.confirmedAddress = 'new@example.invalid';
    await _tap(tester, 'I confirmed my new email');
    expect(store.updates, [{'email': 'new@example.invalid'}]);
    expect(find.text('Email changed and profile synchronized.'), findsOneWidget);
  });

  testWidgets('Wrong password remains editable and does not send confirmation', (tester) async {
    user.recentLoginRequired = true;
    await open(tester);
    await send(tester);
    user.reauthError = 'wrong-password';
    await tester.enterText(find.byType(TextFormField).at(2), 'wrong');
    await _tap(tester, 'Send confirmation');
    expect(find.text('The current password is incorrect. Try again.'), findsOneWidget);
    expect(user.sent, isEmpty);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);
  });

  testWidgets('Session loss during reload prevents sync and offers sign out', (tester) async {
    await open(tester);
    await send(tester);
    user.afterReload = () => auth.user = null;
    await _tap(tester, 'I confirmed my new email');
    expect(find.text('Your session is no longer valid. Sign out and sign in again.'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(store.transactions, 0);
  });

  testWidgets('Confirmed sync finishes safely if auth routing disposes the page', (tester) async {
    await open(tester);
    await send(tester);
    user.confirmedAddress = 'new@example.invalid'; store.pending = Completer<void>();
    await tester.tap(find.text('I confirmed my new email'));
    await tester.pump();
    expect(store.transactions, 1);
    await tester.pumpWidget(const SizedBox());
    store.pending!.complete();
    await tester.pump();
    expect(store.data!['email'], 'new@example.invalid');
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ru', 'en', 'pl', 'uk']) {
    testWidgets('New email copy is available in $language', (tester) async {
      await tester.pumpWidget(_app(ChangeEmailScreen(service: service), language: language));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ChangeEmailScreen));
      expect(find.text(AppLocalizations.of(context)!.changeEmailTitle), findsOneWidget);
    });
  }
}
