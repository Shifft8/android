import 'package:flutter/cupertino.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'register_screen_ios.dart';

class WelcomeScreenIOS extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const WelcomeScreenIOS({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(loc.welcome)),
      child: Center(
        child: CupertinoButton.filled(
          child: Text(loc.registerButton),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => RegisterScreenIOS(
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

