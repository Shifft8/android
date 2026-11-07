import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_navigation.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart'; // ✅ Импорт экрана приветствия
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
  Locale? _locale;
  bool _darkMode = false;

  // Методы обновления состояния для проброса вниз по дереву виджетов
  void setLocale(Locale locale) => setState(() => _locale = locale);
  void setDarkMode(bool value) => setState(() => _darkMode = value);

  @override
  Widget build(BuildContext context) {
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
        home: SplashScreen(
          onLocaleChanged: setLocale,
          onDarkModeChanged: setDarkMode,
          isDarkMode: _darkMode,
          currentLocale: _locale ?? const Locale('en'),
        ),
      );
    } else {
      return MaterialApp(
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
        home: SplashScreen(
          onLocaleChanged: setLocale,
          onDarkModeChanged: setDarkMode,
          isDarkMode: _darkMode,
          currentLocale: _locale ?? const Locale('en'),
        ),
      );
    }
  }
}

// Промежуточный экран-роутер для распределения потоков авторизации Firebase
class RootScreen extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const RootScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Если пользователь уже авторизован в Firebase — сразу пускаем в главное меню приложения
        if (snapshot.hasData && snapshot.data != null) {
          return MainNavigation(
            onLocaleChanged: onLocaleChanged,
            onDarkModeChanged: onDarkModeChanged,
            isDarkMode: isDarkMode,
            currentLocale: currentLocale,
          );
        }

        // Если НЕ авторизован — показываем WelcomeScreen с красивой анимацией
        return WelcomeScreen(
          onLoginPressed: () {
            // При нажатии на кнопку «Вхід» плавно переходим на твой LoginScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(
                  onLocaleChanged: onLocaleChanged,
                  onDarkModeChanged: onDarkModeChanged,
                  isDarkMode: isDarkMode,
                  currentLocale: currentLocale,
                ),
              ),
            );
          },
        );
      },
    );
  }
}