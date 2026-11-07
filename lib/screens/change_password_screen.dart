import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  final FirebaseAuth auth;
  final String uid;
  const ChangePasswordScreen({super.key, required this.auth, required this.uid});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _success = false;
  String? _message;

  User _requireUser() {
    final user = widget.auth.currentUser;
    if (user == null || user.uid != widget.uid || user.email == null || user.email!.isEmpty) {
      throw FirebaseAuthException(code: 'user-mismatch');
    }
    if (!user.emailVerified) throw FirebaseAuthException(code: 'email-not-verified');
    if (!user.providerData.any((provider) => provider.providerId == 'password')) {
      throw FirebaseAuthException(code: 'unsupported-provider');
    }
    return user;
  }

  String _authMessage(AppLocalizations loc, String code, {bool updateStarted = false}) => switch (code) {
    'wrong-password' || 'invalid-credential' => loc.emailChangeWrongPassword,
    'weak-password' || 'password-does-not-meet-requirements' => loc.passwordWeak,
    'requires-recent-login' => loc.passwordRecentLogin,
    'network-request-failed' => updateStarted ? loc.passwordChangeUncertain : loc.resetNetworkError,
    'too-many-requests' => loc.resetTooManyRequests,
    'unsupported-provider' => loc.passwordProviderUnavailable,
    'email-not-verified' => loc.passwordEmailUnverified,
    'user-mismatch' || 'user-disabled' || 'user-not-found' || 'invalid-user-token' || 'user-token-expired'
      => loc.emailChangeSession,
    _ => updateStarted ? loc.passwordChangeUncertain : loc.passwordChangeFailed,
  };

  Future<void> _save() async {
    if (_busy || _success || !_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context)!;
    final currentPassword = _current.text;
    final newPassword = _newPassword.text;
    setState(() { _busy = true; _message = null; });
    bool updateStarted = false;
    try {
      final user = _requireUser();
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(
        email: user.email!, password: currentPassword,
      ));
      final currentUser = _requireUser();
      updateStarted = true;
      await currentUser.updatePassword(newPassword);
      if (!mounted) return;
      _current.clear();
      _newPassword.clear();
      _confirmation.clear();
      _requireUser();
      setState(() { _success = true; _message = loc.passwordChangedSuccess; });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _message = _authMessage(loc, error.code, updateStarted: updateStarted));
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = updateStarted ? loc.passwordChangeUncertain : loc.passwordChangeFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    String? unavailable;
    try {
      _requireUser();
    } on FirebaseAuthException catch (error) {
      unavailable = _authMessage(loc, error.code);
    }
    Widget field(TextEditingController controller, String label, String? Function(String?) validator,
        {bool last = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_busy && unavailable == null,
        obscureText: true, autocorrect: false, enableSuggestions: false,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: last ? (_) => _save() : null,
        validator: validator,
        decoration: InputDecoration(labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.lock_outline), filled: true, fillColor: Theme.of(context).cardColor),
      ),
    );
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.changePassword), leading: BackButton(
          onPressed: _busy ? () {} : () => Navigator.pop(context))),
        body: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!_success) ...[
              field(_current, loc.oldPassword,
                (value) => value == null || value.isEmpty ? loc.passwordRequired : null),
              field(_newPassword, loc.newPassword, (value) {
                if (value == null || value.isEmpty) return loc.passwordRequired;
                // Firebase remains authoritative for the project's stronger password policy.
                return value.length < 6 ? loc.passwordTooShort : null;
              }),
              field(_confirmation, loc.confirmPassword, (value) {
                if (value == null || value.isEmpty) return loc.passwordRequired;
                return value != _newPassword.text ? loc.passwordsDoNotMatch : null;
              }, last: true),
            ],
            if (_message != null || unavailable != null)
              Semantics(liveRegion: true,
                child: Text(_message ?? unavailable!, textAlign: TextAlign.center)),
            const SizedBox(height: 24),
            if (_busy) const CircularProgressIndicator(),
            if (!_success) SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: _busy || unavailable != null ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(loc.changePasswordButton),
            )),
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(loc.passwordBackToProfile)),
          ])),
        )),
      ),
    );
  }
}
