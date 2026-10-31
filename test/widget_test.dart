import 'package:address_manager/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English localization delegate loads app strings', () async {
    final localizations = await AppLocalizations.delegate.load(
      const Locale('en'),
    );

    expect(localizations.appTitle, 'Address Manager');
    expect(localizations.login, 'Login');
    expect(localizations.register, 'Register');
  });
}
