import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart'; // ✅ правильный импорт
import 'screens/main_navigation.dart';
import 'screens/splash_screen.dart';

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
  Locale? _locale; // убираем жёсткий en
  bool _darkMode = false;

  void setLocale(Locale locale) => setState(() => _locale = locale);
  void setDarkMode(bool value) => setState(() => _darkMode = value);

  @override
  Widget build(BuildContext context) {
    final delegates = const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];

    final locales = const [
      Locale('en'),
      Locale('ru'),
      Locale('pl'),
      Locale('uk'),
    ];

    if (Platform.isIOS) {
      return CupertinoApp(
        debugShowCheckedModeBanner: false,
        locale: _locale, // теперь null = язык системы
        theme: CupertinoThemeData(
          brightness: _darkMode ? Brightness.dark : Brightness.light,
          primaryColor: CupertinoColors.activeBlue,
        ),
        localizationsDelegates: delegates,
        supportedLocales: locales,
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
        locale: _locale, // текущий выбранный язык
        supportedLocales: locales, // ✅ твой список
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
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
    final loc = AppLocalizations.of(context)!; // ✅ локализация доступна

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return MainNavigation(
            onLocaleChanged: onLocaleChanged,
            onDarkModeChanged: onDarkModeChanged,
            isDarkMode: isDarkMode,
            currentLocale: currentLocale,
          );
        } else {
          // Можно сделать отдельный LoginScreen, пока оставим MainNavigation
          return MainNavigation(
            onLocaleChanged: onLocaleChanged,
            onDarkModeChanged: onDarkModeChanged,
            isDarkMode: isDarkMode,
            currentLocale: currentLocale,
          );
        }
      },
    );
  }
}
