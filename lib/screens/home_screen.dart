import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'user_profile_screen.dart';
import 'settings_screen.dart';
import 'address_list_screen.dart';
import 'add_address_screen.dart';
import 'notes_screen.dart';
import 'add_note_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const HomeScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final items = [
      {
        'label': loc.profile,
        'icon': Icons.person,
        'builder': () => UserProfileScreen()
      },
      {
        'label': loc.settings,
        'icon': Icons.settings,
        'builder': () => SettingsScreen(
          onLocaleChanged: onLocaleChanged,
          onDarkModeChanged: onDarkModeChanged,
          isDarkMode: isDarkMode,
          currentLocale: currentLocale,
        )
      },
      {
        'label': loc.addresses,
        'icon': Icons.home,
        'builder': () => AddressListScreen()
      },
      {
        'label': loc.addAddress,
        'icon': Icons.add_home,
        'builder': () => AddAddressScreen()
      },
      {
        'label': loc.notes,
        'icon': Icons.note,
        'builder': () => NotesScreen(
          onLocaleChanged: onLocaleChanged,
          onDarkModeChanged: onDarkModeChanged,
          isDarkMode: isDarkMode,
          currentLocale: currentLocale,
        )
      },
      {
        'label': loc.addNote,
        'icon': Icons.note_add,
        'builder': () => const AddNoteScreen()
      },
    ];

    Widget buildTile(Map<String, dynamic> item) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => (item['builder'] as Widget Function())()),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'] as IconData, size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(item['label'] as String, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Adresownik')),
      backgroundColor: const Color(0xFFEAF4FF),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: items.map(buildTile).toList(),
        ),
      ),
    );
  }
}
