import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class EditAddressScreen extends StatefulWidget {
  final String docId;
  final String initialStreet; // Передаем старое название улицы
  final String initialCode;   // Передаем старый код

  const EditAddressScreen({
    super.key,
    required this.docId,
    required this.initialStreet,
    required this.initialCode,
  });

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  late TextEditingController _streetController;
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    // ✅ Автоматически заполняем поля старыми данными при открытии экрана
    _streetController = TextEditingController(text: widget.initialStreet);
    _codeController = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _streetController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Делаем страницу темнее, чтобы белые поля ввода выделялись (как на добавлении)
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Редактировать адрес',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Поле ввода: Улица (в стиле Google поиска)
            _buildGoogleInputField(
              controller: _streetController,
              label: 'Улица и номер дома',
              hint: 'Введите адрес',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),

            // Поле ввода: Код (с ключиком и цифровой раскладкой)
            _buildGoogleInputField(
              controller: _codeController,
              label: 'Код',
              hint: 'Введите код',
              keyboardType: TextInputType.visiblePassword,
              icon: Icons.vpn_key_outlined,
            ),
            const SizedBox(height: 40),

            // Кнопка Сохранить изменения
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Здесь будет твоя логика обновления данных в Firebase Firestore по widget.docId

                Navigator.pop(context); // Возвращаемся назад после сохранения
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Изменения сохранены!')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Сохранить', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Скругление под стиль Google
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Универсальный метод для создания полей ввода с закруглениями и тенями
  Widget _buildGoogleInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          hintStyle: const TextStyle(color: Colors.black26),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

          // ✅ ВОТ ТУТ ИСПРАВЛЕНО: убираем внешнюю стандартную рамку правильно
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // <--- Было InputBorder.none, теперь всё чётко!
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
