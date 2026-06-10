import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'l10n/app_localizations.dart';


class ForgotPasswordScreenIOS extends StatefulWidget {
  const ForgotPasswordScreenIOS({super.key});

  @override
  State<ForgotPasswordScreenIOS> createState() => _ForgotPasswordScreenIOSState();
}

class _ForgotPasswordScreenIOSState extends State<ForgotPasswordScreenIOS> {
  final _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    final loc = AppLocalizations.of(context)!;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.resetPasswordEmailSent)),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${loc.error}: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(loc.forgotPassword)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _emailController,
                placeholder: loc.email,
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _resetPassword,
                child: Text(loc.resetPasswordButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
