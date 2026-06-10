import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // для SnackBar
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class AddAddressScreenIOS extends StatefulWidget {
  const AddAddressScreenIOS({super.key});

  @override
  State<AddAddressScreenIOS> createState() => _AddAddressScreenIOSState();
}

class _AddAddressScreenIOSState extends State<AddAddressScreenIOS> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveAddress() async {
    final uid = _auth.currentUser?.uid;
    final loc = AppLocalizations.of(context)!;

    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorNoAuth)),
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final newAddress = {
      'street': _streetController.text.trim(),
      'house': _houseController.text.trim(),
      'code': _codeController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .add(newAddress);

      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Ошибка добавления адреса: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${loc.errorAddAddress}: $e")),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(loc.addAddress),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _streetController,
                placeholder: loc.street,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _houseController,
                placeholder: loc.house,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _codeController,
                placeholder: loc.code,
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _isSaving ? null : _saveAddress,
                child: _isSaving
                    ? const CupertinoActivityIndicator()
                    : Text(loc.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
