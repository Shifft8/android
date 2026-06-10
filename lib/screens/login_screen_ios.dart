import 'package:flutter/cupertino.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class LoginScreenIOS extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;

  const LoginScreenIOS({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(loc.loginButton)),
      child: const Center(child: Text("Форма входа")),
    );
  }
}
