import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class EditAddressScreenIOS extends StatefulWidget {
  final String addressId;
  final Map<String, dynamic> addressData;

  const EditAddressScreenIOS({
    super.key,
    required this.addressId,
    required this.addressData,
  });

  @override
  State<EditAddressScreenIOS> createState() => _EditAddressScreenIOSState();
}

class _EditAddressScreenIOSState extends State<EditAddressScreenIOS> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _codeController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  void _loadAddressData() {
    _streetController.text = widget.addressData['street'] ?? '';
    _houseController.text = widget.addressData['house'] ?? '';
    _codeController.text = widget.addressData['code'] ?? '';
    _latController.text = (widget.addressData['latitude'] ?? '').toString();
    _lngController.text = (widget.addressData['longitude'] ?? '').toString();
  }

  Future<void> _saveAddress() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'street': _streetController.text.trim(),
      'house': _houseController.text.trim(),
      'code': _codeController.text.trim(),
      'latitude': double.tryParse(_latController.text.trim()) ?? 0.0,
      'longitude': double.tryParse(_lngController.text.trim()) ?? 0.0,
    };

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(widget.addressId)
          .update(updates);

      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving address: $e");
    } finally {
      if (context.mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(loc.editAddress),
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
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _latController,
                placeholder: loc.latitude,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _lngController,
                placeholder: loc.longitude,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                child: _isSaving
                    ? const CupertinoActivityIndicator()
                    : Text(loc.save),
                onPressed: _isSaving ? null : _saveAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
