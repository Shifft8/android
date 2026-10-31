import 'dart:io' show Platform;

import 'package:address_manager/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const WelcomeScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final page = RegisterScreen(
      onLocaleChanged: onLocaleChanged,
      onDarkModeChanged: onDarkModeChanged,
      isDarkMode: isDarkMode,
      currentLocale: currentLocale,
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(loc.welcomeMessage)),
        child: SafeArea(
          child: Center(
            child: CupertinoButton.filled(
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => page),
              ),
              child: Text(loc.register),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.welcomeMessage)),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          ),
          child: Text(loc.register),
        ),
      ),
    );
  }
}
