import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'main_navigation.dart';
import 'login_screen.dart';
import 'welcome_screen.dart'; // ✅ Импортируем наш красивый экран

class SplashScreen extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const SplashScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Если пользователь авторизован — сразу пускаем в главное меню
    if (user != null) {
      return MainNavigation(
        onLocaleChanged: onLocaleChanged,
        onDarkModeChanged: onDarkModeChanged,
        isDarkMode: isDarkMode,
        currentLocale: currentLocale,
      );
    }

    // 2. Если НЕ авторизован — возвращаем наш анимированный WelcomeScreen!
    return WelcomeScreen(
      onLoginPressed: () {
        // При нажатии на кнопку «Вхід» плавно открываем твой LoginScreen
        if (Platform.isIOS) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => LoginScreen(
                onLocaleChanged: onLocaleChanged,
                onDarkModeChanged: onDarkModeChanged,
                isDarkMode: isDarkMode,
                currentLocale: currentLocale,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                onLocaleChanged: onLocaleChanged,
                onDarkModeChanged: onDarkModeChanged,
                isDarkMode: isDarkMode,
                currentLocale: currentLocale,
              ),
            ),
          );
        }
      },
    );
  }
}