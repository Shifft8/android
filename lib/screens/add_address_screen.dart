import 'package:address_manager/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_loading) return;
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorNoAuth)),
      );
      return;
    }

    final street = _streetController.text.trim();
    final number = _numberController.text.trim();
    if (street.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorAddAddress)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add({
        'street': street,
        'number': number,
        'code': _codeController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('Failed to add address: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorAddAddress)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: loc.street),
            ),
            TextField(
              controller: _numberController,
              decoration: InputDecoration(labelText: loc.houseNumber),
            ),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: loc.code),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _saveAddress,
                    icon: const Icon(Icons.save),
                    label: Text(loc.save),
                  ),
          ],
        ),
      ),
    );
  }
}