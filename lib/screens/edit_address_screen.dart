import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class EditAddressScreen extends StatefulWidget {
  final String docId; // ID документа адреса в Firestore

  const EditAddressScreen({super.key, required this.docId});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _codeController = TextEditingController();

  bool _loading = false;

  Future<void> _loadAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(widget.docId)
        .get();

    final data = doc.data();
    if (data != null) {
      _streetController.text = data['street'] ?? '';
      _numberController.text = data['number'] ?? '';
      _codeController.text = data['code'] ?? '';
    }
  }

  Future<void> _saveAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(widget.docId)
        .update({
      'street': _streetController.text.trim(),
      'number': _numberController.text.trim(),
      'code': _codeController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    Navigator.pop(context); // ✅ возвращаемся к списку адресов
  }

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.edit)),
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
                backgroundColor: Colors.blue, // ✅ тот же цвет, что на главной
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
