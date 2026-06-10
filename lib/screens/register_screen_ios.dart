import 'package:flutter/cupertino.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'main_navigation_ios.dart';

class RegisterScreenIOS extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const RegisterScreenIOS({
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
      navigationBar: CupertinoNavigationBar(middle: Text(loc.registerButton)),
      child: Center(
        child: CupertinoButton.filled(
          child: Text(loc.registerButton),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (_) => MainNavigationIOS(
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
