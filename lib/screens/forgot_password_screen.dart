import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final FirebaseAuth? auth;

  const ForgotPasswordScreen({super.key, this.initialEmail = '', this.auth});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    setState(() { _sending = true; _message = null; });
    String message;
    try {
      await (widget.auth ?? FirebaseAuth.instance).sendPasswordResetEmail(email: email);
      message = loc.resetPasswordEmailSent;
    } on FirebaseAuthException catch (error) {
      message = switch (error.code) {
        'user-not-found' => loc.resetPasswordEmailSent,
        'invalid-email' => loc.resetEmailInvalid,
        'network-request-failed' => loc.resetNetworkError,
        'too-many-requests' => loc.resetTooManyRequests,
        _ => loc.resetRequestError,
      };
    } catch (_) {
      message = loc.resetRequestError;
    }
    if (!mounted) return;
    setState(() { _sending = false; _message = message; });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.forgotPassword)),
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_reset, size: 70, color: Colors.blue),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              enabled: !_sending,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _resetPassword(),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return loc.resetEmailRequired;
                if (!RegExp(r'^[^@\s]+@[^@\s.]+(?:\.[^@\s.]+)+$').hasMatch(email)) {
                  return loc.resetEmailInvalid;
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: loc.email,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(_message!, textAlign: TextAlign.center)),
            ],
            const SizedBox(height: 24),
            if (_sending) const CircularProgressIndicator(),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: _sending ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.resetPasswordButton),
            )),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.backToLogin)),
          ]),
        ),
      )),
    );
  }
}
