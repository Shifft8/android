import 'package:flutter/cupertino.dart';
import 'home_screen_ios.dart';
import 'address_list_screen_ios.dart';
import 'notes/notes_screen.dart';
import 'profile_screen_ios.dart';

class MainNavigationIOS extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const MainNavigationIOS({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  State<MainNavigationIOS> createState() => _MainNavigationIOSState();
}

class _MainNavigationIOSState extends State<MainNavigationIOS> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      HomeScreenIOS(
        onLocaleChanged: widget.onLocaleChanged,
        onDarkModeChanged: widget.onDarkModeChanged,
        isDarkMode: widget.isDarkMode,
        currentLocale: widget.currentLocale,
      ),
      AddressListScreenIOS(),
      const NotesScreen(),
      ProfileScreenIOS(
        onLocaleChanged: widget.onLocaleChanged,
        onDarkModeChanged: widget.onDarkModeChanged,
        isDarkMode: widget.isDarkMode,
        currentLocale: widget.currentLocale,
      ),
    ];

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.location), label: "Addresses"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text), label: "Notes"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: "Profile"),
        ],
      ),
      tabBuilder: (context, index) => _tabs[index],
    );
  }
}
