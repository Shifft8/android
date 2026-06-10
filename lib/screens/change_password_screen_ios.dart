import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class ChangePasswordScreenIOS extends StatefulWidget {
  const ChangePasswordScreenIOS({super.key});

  @override
  State<ChangePasswordScreenIOS> createState() => _ChangePasswordScreenIOSState();
}

class _ChangePasswordScreenIOSState extends State<ChangePasswordScreenIOS> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  Future<void> _changePassword() async {
    final loc = AppLocalizations.of(context)!;

    if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.passwordsDoNotMatch)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.passwordChangedSuccess)),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${loc.error}: ${e.message}")),
      );
    } finally {
      if (context.mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(loc.changePassword)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _oldPasswordController,
                placeholder: loc.oldPassword,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _newPasswordController,
                placeholder: loc.newPassword,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _confirmPasswordController,
                placeholder: loc.confirmPassword,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_loading) const CupertinoActivityIndicator(),
              CupertinoButton.filled(
                onPressed: _loading ? null : _changePassword,
                child: Text(loc.changePasswordButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
