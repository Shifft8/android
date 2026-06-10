import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';


class SettingsScreenIOS extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const SettingsScreenIOS({
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
      navigationBar: CupertinoNavigationBar(
        middle: Text(loc.settings),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(loc.language, style: CupertinoTheme.of(context).textTheme.textStyle),
            const SizedBox(height: 8),
            CupertinoSegmentedControl<String>(
              groupValue: currentLocale.languageCode,
              onValueChanged: (code) => onLocaleChanged(Locale(code)),
              children: const {
                'en': Text("EN"),
                'ru': Text("RU"),
                'pl': Text("PL"),
                'uk': Text("UK"),
              },
            ),
            const SizedBox(height: 32),
            Text(loc.darkTheme, style: CupertinoTheme.of(context).textTheme.textStyle),
            const SizedBox(height: 8),
            CupertinoSwitch(
              value: isDarkMode,
              onChanged: onDarkModeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
