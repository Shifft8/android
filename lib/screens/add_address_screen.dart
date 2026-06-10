import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _codeController = TextEditingController();

  bool _loading = false;

  Future<void> _saveAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .add({
      'street': _streetController.text.trim(),
      'number': _numberController.text.trim(),
      'code': _codeController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    Navigator.pop(context); // ✅ возвращаемся к списку адресов
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.addAddress)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _streetController,
              decoration: InputDecoration(labelText: loc.street ?? "Street"),
            ),
            TextField(
              controller: _numberController,
              decoration: InputDecoration(labelText: loc.houseNumber ?? "House number"),
            ),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: loc.code ?? "Intercom code"),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(loc.save, style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // ✅ цвет как на главной странице
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _saveAddress,
            ),
          ],
        ),
      ),
    );
  }
}
