import 'package:flutter/cupertino.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'profile_screen_ios.dart';

class HomeScreenIOS extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const HomeScreenIOS({
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
      navigationBar: const CupertinoNavigationBar(middle: Text("Home")),
      child: Center(
        child: CupertinoButton(
          child: Text(loc.profile),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => ProfileScreenIOS(
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
