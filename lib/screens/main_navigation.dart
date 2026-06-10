import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart'; // ✅ правильный импорт

class MainNavigation extends StatefulWidget {
  final void Function(Locale)? onLocaleChanged;
  final void Function(bool)? onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const MainNavigation({
    super.key,
    this.onLocaleChanged,
    this.onDarkModeChanged,
    this.isDarkMode = false,
    this.currentLocale = const Locale('en'),
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late Locale _locale;
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _locale = widget.currentLocale;
    _darkMode = widget.isDarkMode;
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
    widget.onLocaleChanged?.call(locale);
  }

  void _setDarkMode(bool value) {
    setState(() => _darkMode = value);
    widget.onDarkModeChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onLocaleChanged: _setLocale,
        onDarkModeChanged: _setDarkMode,
        isDarkMode: _darkMode,
        currentLocale: _locale,
      ),
      NotesScreen(
        onLocaleChanged: _setLocale,
        onDarkModeChanged: _setDarkMode,
        isDarkMode: _darkMode,
        currentLocale: _locale,
      ),
      const UserProfileScreen(), // ✅ заменили ProfileScreen
      SettingsScreen(
        onLocaleChanged: _setLocale,
        onDarkModeChanged: _setDarkMode,
        isDarkMode: _darkMode,
        currentLocale: _locale,
      ),
    ];

    if (Platform.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: CupertinoColors.systemGrey6,
          activeColor: CupertinoColors.activeBlue,
          inactiveColor: CupertinoColors.inactiveGray,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text), label: "Notes"),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: "Profile"),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: "Settings"),
          ],
        ),
        tabBuilder: (context, index) => screens[index],
      );
    } else {
      return Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.grey[200],
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          ],
        ),
      );
    }
  }
}

