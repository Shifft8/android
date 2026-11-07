import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_navigation.dart';
import 'screens/email_verification_screen.dart';
import 'screens/login_screen.dart';   // ✅ Импорт твоего экрана авторизации

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AddressManagerApp());
}

class AddressManagerApp extends StatefulWidget {
  const AddressManagerApp({super.key});

  @override
  State<AddressManagerApp> createState() => _AddressManagerAppState();
}

class _AddressManagerAppState extends State<AddressManagerApp> {
  late final Stream<User?> _users = FirebaseAuth.instance.userChanges();
  bool _authBusy = false;
  String? _authError;
  Locale? _locale;
  bool _darkMode = false;

  // Методы обновления состояния для проброса вниз по дереву виджетов
  void setLocale(Locale locale) => setState(() => _locale = locale);
  void setDarkMode(bool value) => setState(() => _darkMode = value);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _users,
      builder: (context, snapshot) => _buildApp(
        context,
        _authBusy ? null : snapshot.data,
        snapshot.connectionState == ConnectionState.waiting,
      ),
    );
  }

  Widget _buildApp(BuildContext context, User? user, bool waiting) {
    // Общие делегаты локализации для iOS и Android
    const delegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];

    // Список поддерживаемых приложением языков
    const locales = [
      Locale('en'),
      Locale('ru'),
      Locale('pl'),
      Locale('uk'),
    ];

    final currentAppLocale = _locale;

    if (Platform.isIOS) {
      return CupertinoApp(
        key: ValueKey('${user?.uid}:${user?.emailVerified}'),
        debugShowCheckedModeBanner: false,
        locale: currentAppLocale,
        theme: CupertinoThemeData(
          brightness: _darkMode ? Brightness.dark : Brightness.light,
          primaryColor: CupertinoColors.activeBlue,
        ),
        localizationsDelegates: delegates,
        supportedLocales: locales,
        localeResolutionCallback: (deviceLocale, supportedLocales) {
          if (_locale != null) return _locale;
          if (deviceLocale != null && locales.contains(Locale(deviceLocale.languageCode))) {
            return deviceLocale;
          }
          return const Locale('en');
        },
        home: RootScreen(
          user: user,
          waiting: waiting,
          onAuthBusyChanged: (busy) => setState(() => _authBusy = busy),
          onAuthError: (error) => _authError = error,
          authError: _authError,
          onLocaleChanged: setLocale,
          onDarkModeChanged: setDarkMode,
          isDarkMode: _darkMode,
          currentLocale: _locale ?? const Locale('en'),
        ),
      );
    } else {
      return MaterialApp(
        key: ValueKey('${user?.uid}:${user?.emailVerified}'),
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        locale: currentAppLocale,
        supportedLocales: locales,
        localizationsDelegates: delegates,
        localeResolutionCallback: (deviceLocale, supportedLocales) {
          if (_locale != null) return _locale;
          if (deviceLocale != null && locales.contains(Locale(deviceLocale.languageCode))) {
            return deviceLocale;
          }
          return const Locale('en');
        },
        home: RootScreen(
          user: user,
          waiting: waiting,
          onAuthBusyChanged: (busy) => setState(() => _authBusy = busy),
          onAuthError: (error) => _authError = error,
          authError: _authError,
          onLocaleChanged: setLocale,
          onDarkModeChanged: setDarkMode,
          isDarkMode: _darkMode,
          currentLocale: _locale ?? const Locale('en'),
        ),
      );
    }
  }
}

// Auth changes replace the app navigator, including all protected routes.
class RootScreen extends StatelessWidget {
  final String? authError;
  final ValueChanged<String?> onAuthError;
  final User? user;
  final bool waiting;
  final ValueChanged<bool> onAuthBusyChanged;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const RootScreen({
    super.key,
    this.authError,
    required this.onAuthError,
    required this.user,
    required this.waiting,
    required this.onAuthBusyChanged,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    if (waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final currentUser = user;
    if (currentUser == null) {
      return LoginScreen(
        onAuthError: onAuthError,
        onAuthBusyChanged: onAuthBusyChanged,
        onLocaleChanged: onLocaleChanged,
        onDarkModeChanged: onDarkModeChanged,
        isDarkMode: isDarkMode,
        currentLocale: currentLocale,
      );
    }
    if (!currentUser.emailVerified) {
      return EmailVerificationScreen(user: currentUser, initialMessage: authError);
    }
    return MainNavigation(
      onLocaleChanged: onLocaleChanged,
      onDarkModeChanged: onDarkModeChanged,
      isDarkMode: isDarkMode,
      currentLocale: currentLocale,
    );
  }
}
