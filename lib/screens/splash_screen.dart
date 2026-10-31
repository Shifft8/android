import 'dart:io' show Platform;

import 'package:address_manager/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'main_navigation.dart';

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

  MainNavigation _mainNavigation() => MainNavigation(
        onLocaleChanged: onLocaleChanged,
        onDarkModeChanged: onDarkModeChanged,
        isDarkMode: isDarkMode,
        currentLocale: currentLocale,
      );

  void _openLogin(BuildContext context) {
    final page = LoginScreen(
      onLocaleChanged: onLocaleChanged,
      onDarkModeChanged: onDarkModeChanged,
      isDarkMode: isDarkMode,
      currentLocale: currentLocale,
    );

    Navigator.push(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(builder: (_) => page)
          : MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (FirebaseAuth.instance.currentUser != null) {
      return _mainNavigation();
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (Platform.isIOS)
          CupertinoButton.filled(
            onPressed: () => _openLogin(context),
            child: Text(loc.login),
          )
        else
          ElevatedButton(
            onPressed: () => _openLogin(context),
            child: Text(loc.login),
          ),
      ],
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(loc.welcomeMessage)),
        child: SafeArea(child: Center(child: content)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.welcomeMessage)),
      body: Center(child: content),
    );
  }
}
