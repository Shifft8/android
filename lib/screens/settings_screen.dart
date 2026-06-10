import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const SettingsScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locales = const [
      Locale('en'),
      Locale('ru'),
      Locale('pl'),
      Locale('uk'),
    ];

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(loc.settings),
        ),
        child: SafeArea(
          child: ListView(
            children: [
              const SizedBox(height: 20),
              CupertinoFormSection.insetGrouped(
                header: Text(loc.darkMode),
                children: [
                  CupertinoFormRow(
                    prefix: Text(loc.darkMode),
                    child: CupertinoSwitch(
                      value: isDarkMode,
                      onChanged: onDarkModeChanged,
                    ),
                  ),
                ],
              ),
              CupertinoFormSection.insetGrouped(
                header: Text(loc.language),
                children: locales.map((locale) {
                  final isSelected = currentLocale == locale;
                  return CupertinoFormRow(
                    prefix: Text(locale.languageCode.toUpperCase()),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: isSelected
                          ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                          : const SizedBox.shrink(),
                      onPressed: () => onLocaleChanged(locale),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: Text(loc.settings)),
        body: ListView(
          children: [
            SwitchListTile(
              title: Text(loc.darkMode),
              value: isDarkMode,
              onChanged: onDarkModeChanged,
            ),
            const Divider(),
            ListTile(title: Text(loc.language)),
            ListTile(
              title: Text(loc.languageEnglish),
              trailing: currentLocale.languageCode == 'en'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => onLocaleChanged(const Locale('en')),
            ),
            ListTile(
              title: Text(loc.languageRussian),
              trailing: currentLocale.languageCode == 'ru'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => onLocaleChanged(const Locale('ru')),
            ),
            ListTile(
              title: Text(loc.languagePolish),
              trailing: currentLocale.languageCode == 'pl'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => onLocaleChanged(const Locale('pl')),
            ),
            ListTile(
              title: Text(loc.languageUkrainian),
              trailing: currentLocale.languageCode == 'uk'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => onLocaleChanged(const Locale('uk')),
            ),
          ],
        ),
      );
    }
  }
}
