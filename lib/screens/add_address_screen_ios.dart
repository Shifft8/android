import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SnackBar, ScaffoldMessenger;
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
  final _numberController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_isSaving) return;

    final loc = AppLocalizations.of(context)!;
    final street = _streetController.text.trim();
    final number = _numberController.text.trim();

    if (street.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.street}: ${loc.houseNumber}')),
      );
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorNoAuth)),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await _firestore
          .collection('users')
          .doc(uid)
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.errorAddAddress}: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _numberController,
                placeholder: loc.houseNumber,
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
