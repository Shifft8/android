import 'package:flutter/cupertino.dart';

class EditAddressScreenIOS extends StatefulWidget {
  final String street;
  final String house;
  final String code;

  const EditAddressScreenIOS({
    super.key,
    required this.street,
    required this.house,
    required this.code,
  });

  @override
  State<EditAddressScreenIOS> createState() => _EditAddressScreenIOSState();
}

class _EditAddressScreenIOSState extends State<EditAddressScreenIOS> {
  late TextEditingController streetController;
  late TextEditingController houseController;
  late TextEditingController codeController;

  @override
  void initState() {
    super.initState();
    streetController = TextEditingController(text: widget.street);
    houseController = TextEditingController(text: widget.house);
    codeController = TextEditingController(text: widget.code);
  }

  @override
  void dispose() {
    streetController.dispose();
    houseController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, {
      'street': streetController.text,
      'house': houseController.text,
      'code': codeController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Редактировать адрес'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Улица'),
            CupertinoTextField(
              controller: streetController,
              placeholder: 'Введите улицу',
            ),
            const SizedBox(height: 12),
            const Text('Дом'),
            CupertinoTextField(
              controller: houseController,
              placeholder: 'Введите номер дома',
            ),
            const SizedBox(height: 12),
            const Text('Код домофона'),
            CupertinoTextField(
              controller: codeController,
              placeholder: 'Введите код',
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              child: const Text('Сохранить'),
              onPressed: _save,
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
