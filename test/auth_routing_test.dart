import 'package:address_manager/l10n/app_localizations.dart';
import 'package:address_manager/main.dart';
import 'package:address_manager/screens/email_verification_screen.dart';
import 'package:address_manager/screens/login_screen.dart';
import 'package:address_manager/screens/main_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {
  _User(this.emailVerified);
  @override
  final bool emailVerified;
  @override
  String get uid => 'routing-test';
  @override
  String get email => 'test@example.invalid';
  int sent = 0;
  bool fail = false;
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    sent++;
    if (fail) throw FirebaseAuthException(code: 'network-request-failed');
  }
}

void main() {
  testWidgets('Root denies main navigation until email is verified', (tester) async {
    for (final user in <User?>[null, _User(false), _User(true)]) {
      Widget? selected;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
        selected = RootScreen(
          user: user,
          waiting: false,
          onAuthBusyChanged: (_) {},
          onAuthError: (_) {},
          onLocaleChanged: (_) {},
          onDarkModeChanged: (_) {},
          isDarkMode: false,
          currentLocale: const Locale('en'),
        ).build(context);
        return const SizedBox();
      })));
      if (user == null) {
        expect(selected, isA<LoginScreen>());
      } else if (!user.emailVerified) {
        expect(selected, isA<EmailVerificationScreen>());
      } else {
        expect(selected, isA<MainNavigation>());
      }
    }
  });

  testWidgets('Resend throttles attempts and reports network failure', (tester) async {
    final user = _User(false)..fail = true;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: EmailVerificationScreen(user: user),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resend email'));
    await tester.pumpAndSettle();
    expect(user.sent, 1);
    expect(find.text('Connection failed. Check your network and try again.'), findsOneWidget);
    final resend = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Resend email (60)'));
    expect(resend.onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
