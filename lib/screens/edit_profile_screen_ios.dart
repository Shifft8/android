import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SnackBar, ScaffoldMessenger;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'change_password_screen_ios.dart';

class EditProfileScreenIOS extends StatefulWidget {
  const EditProfileScreenIOS({super.key});

  @override
  State<EditProfileScreenIOS> createState() => _EditProfileScreenIOSState();
}

class _EditProfileScreenIOSState extends State<EditProfileScreenIOS> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      _firstNameController.text = data['firstName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _countryController.text = data['country'] ?? '';
      _cityController.text = data['city'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorNoAuth)),
        );
      }
      return;
    }

    setState(() => _loading = true);

    final updates = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'country': _countryController.text.trim(),
      'city': _cityController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(updates, SetOptions(merge: true));

      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Profile save error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${loc.error}: $e")),
        );
      }
    } finally {
      if (context.mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(loc.editProfile)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _firstNameController,
                placeholder: loc.firstName,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _lastNameController,
                placeholder: loc.lastName,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _phoneController,
                placeholder: loc.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _countryController,
                placeholder: loc.country,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _cityController,
                placeholder: loc.city,
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _loading ? null : _saveProfile,
                child: _loading
                    ? const CupertinoActivityIndicator()
                    : Text(loc.save),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                child: Text(loc.changePassword),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => ChangePasswordScreenIOS()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
