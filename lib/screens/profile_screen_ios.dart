import 'package:flutter/cupertino.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'login_screen_ios.dart';

class ProfileScreenIOS extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const ProfileScreenIOS({
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
      navigationBar: CupertinoNavigationBar(middle: Text(loc.profile)),
      child: Center(
        child: CupertinoButton(
          child: Text(loc.logoutButton),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (_) => LoginScreenIOS(
                  onLocaleChanged: onLocaleChanged,
                  onDarkModeChanged: onDarkModeChanged,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
