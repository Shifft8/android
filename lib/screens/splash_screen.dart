import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'main_navigation.dart';
import 'login_screen.dart'; // если у тебя есть отдельный экран входа

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
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    // ✅ Если пользователь уже авторизован → сразу в MainNavigation
    if (user != null) {
      return MainNavigation();
    }

    // ✅ Если не авторизован → показываем приветствие и кнопку входа
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(loc.welcomeMessage)),
        child: SafeArea(
          child: Center(
            child: CupertinoButton.filled(
              child: Text(loc.login),
              onPressed: () {
                Navigator.pushReplacement(
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
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.welcomeMessage)),
      body: Center(
        child: ElevatedButton(
          child: Text(loc.login),
          onPressed: () {
            Navigator.pushReplacement(
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
          },
        ),
      ),
    );
  }
}
