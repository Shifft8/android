import 'dart:async';
import 'package:address_manager/l10n/app_localizations.dart';
import 'package:address_manager/screens/forgot_password_screen.dart';
import 'package:address_manager/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends Fake implements FirebaseAuth {
  final emails = <String>[];
  String? errorCode;
  Completer<void>? pending;

  @override
  Future<void> sendPasswordResetEmail({required String email, ActionCodeSettings? actionCodeSettings}) async {
    emails.add(email);
    if (pending != null) await pending!.future;
    if (errorCode != null) {
      throw FirebaseAuthException(code: errorCode!, message: 'INTERNAL_DETAILS');
    }
  }
}

Widget _app(Widget home, {String language = 'en'}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Login opens recovery, prefills trimmed email and returns', (tester) async {
    await tester.pumpWidget(_app(LoginScreen(
      onLocaleChanged: (_) {}, onDarkModeChanged: (_) {},
      isDarkMode: false, currentLocale: const Locale('en'),
    )));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '  person@example.com  ');
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text, 'person@example.com');
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Empty and malformed email never call Firebase', (tester) async {
    final auth = _Auth();
    await tester.pumpWidget(_app(ForgotPasswordScreen(auth: auth)));
    await tester.pumpAndSettle();
    await _submit(tester);
    expect(find.text('Enter your email address.'), findsOneWidget);
    for (final input in ['bad', 'a@@example.com', 'a@', 'a b@example.com', 'a@example..com']) {
      await tester.enterText(find.byType(TextFormField), input);
      await _submit(tester);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
    }
    expect(auth.emails, isEmpty);
  });

  for (final code in <String?>[null, 'user-not-found']) {
    testWidgets('Success and unknown account have the same neutral result: $code', (tester) async {
      final auth = _Auth()..errorCode = code;
      await tester.pumpWidget(_app(ForgotPasswordScreen(auth: auth, initialEmail: '  person@example.com  ')));
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(auth.emails, ['person@example.com']);
      expect(find.text('If an account with this email exists, check your inbox.'), findsOneWidget);
      expect(find.textContaining('INTERNAL_DETAILS'), findsNothing);
    });
  }

  for (final entry in {
    'network-request-failed': 'Connection failed. Check your network and try again.',
    'too-many-requests': 'Too many requests. Please wait and try again.',
    'internal-error': 'Unable to send the request. Please try again later.',
  }.entries) {
    testWidgets('Friendly error: ${entry.key}', (tester) async {
      final auth = _Auth()..errorCode = entry.key;
      await tester.pumpWidget(_app(ForgotPasswordScreen(auth: auth, initialEmail: 'person@example.com')));
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(find.text(entry.value), findsOneWidget);
      expect(find.textContaining('INTERNAL_DETAILS'), findsNothing);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);
    });
  }

  testWidgets('Sending blocks duplicate calls and safely completes after disposal', (tester) async {
    final auth = _Auth()..pending = Completer<void>();
    await tester.pumpWidget(_app(ForgotPasswordScreen(auth: auth, initialEmail: 'person@example.com')));
    await tester.pumpAndSettle();
    final submit = tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(auth.emails, hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    auth.pending!.completeError(FirebaseAuthException(code: 'network-request-failed'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'ru', 'pl', 'uk']) {
    testWidgets('Recovery copy is available in $language', (tester) async {
      final auth = _Auth();
      await tester.pumpWidget(_app(ForgotPasswordScreen(auth: auth, initialEmail: 'person@example.com'), language: language));
      await tester.pumpAndSettle();
      await _submit(tester);
      final context = tester.element(find.byType(ForgotPasswordScreen));
      expect(find.text(AppLocalizations.of(context)!.resetPasswordEmailSent), findsOneWidget);
      expect(auth.emails, hasLength(1));
    });
  }
}
