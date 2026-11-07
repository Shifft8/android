import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart'; // Добавили импорт локализации

class AddressFormScreen extends StatefulWidget {
  final String? docId;
  final String? initialStreet;
  final String? initialHouseNumber;
  final String? initialCode;

  const AddressFormScreen({
    super.key,
    this.docId,
    this.initialStreet,
    this.initialHouseNumber,
    this.initialCode,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late TextEditingController _streetController;
  late TextEditingController _houseController;
  late TextEditingController _codeController;
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.docId != null;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(text: widget.initialStreet ?? '');
    _houseController = TextEditingController(text: widget.initialHouseNumber ?? '');
    _codeController = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Инициализируем локализацию
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          isEditing ? localizations.editAddress : localizations.addAddress,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildInputField(
                controller: _streetController,
                label: localizations.street,
                hint: isEditing ? '' : 'Enter street name', // Подсказку можно оставить на английском или пустой
                icon: Icons.location_on,
                validationMessage: localizations.error, // Универсальная ошибка при пустом поле
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _houseController,
                label: localizations.houseNumber,
                hint: 'e.g., 12 or 61a',
                icon: Icons.home,
                validationMessage: localizations.error,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _codeController,
                label: localizations.code,
                hint: 'e.g., 200#2020',
                icon: Icons.vpn_key,
                validationMessage: localizations.error,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final String? uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) throw Exception(localizations.errorNoAuth);

                      final Map<String, dynamic> addressData = {
                        'street': _streetController.text.trim(),
                        'houseNumber': _houseController.text.trim(),
                        'code': _codeController.text.trim(),
                        'userId': uid,
                        'timestamp': FieldValue.serverTimestamp(),
                      };

                      if (isEditing) {
                        await FirebaseFirestore.instance
                            .collection('addresses')
                            .doc(widget.docId)
                            .update(addressData);
                      } else {
                        await FirebaseFirestore.instance
                            .collection('addresses')
                            .add(addressData);
                      }

                      if (mounted) Navigator.pop(context); // закрыть спиннер
                      if (mounted) Navigator.pop(context); // уйти обратно на список

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(localizations.added),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) Navigator.pop(context); // закрыть спиннер при ошибке
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${localizations.error}: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  localizations.save,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String validationMessage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: (value) => value == null || value.trim().isEmpty ? validationMessage : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue),
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          hintStyle: const TextStyle(color: Colors.black26),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: OutlineInputBorder().borderSide.copyWith(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
    );
  }
}