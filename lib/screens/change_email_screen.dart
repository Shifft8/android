import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import '../services/email_change_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  final EmailChangeService service;
  const ChangeEmailScreen({super.key, required this.service});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  Timer? _timer;
  bool _busy = false;
  bool _needsPassword = false;
  bool _sessionLost = false;
  String? _expectedEmail;
  String? _confirmedEmail;
  String? _message;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      if (widget.service.auth.currentUser?.uid != widget.service.uid) {
        _sessionLost = true;
        _message = loc.emailChangeSession;
        return;
      }
      switch (error.code) {
        case 'requires-recent-login':
          if (_needsPassword) {
            _sessionLost = true;
            _message = loc.emailChangeSession;
          } else if (widget.service.supportsPassword) {
            _needsPassword = true;
            _message = loc.emailChangeReauth;
          } else {
            _sessionLost = true;
            _message = loc.emailChangeProvider;
          }
        case 'unsupported-provider':
          _sessionLost = true;
          _message = loc.emailChangeProvider;
        case 'invalid-email':
          _message = loc.resetEmailInvalid;
        case 'email-already-in-use':
          _message = loc.emailChangeInUse;
        case 'wrong-password':
        case 'invalid-credential':
          _message = loc.emailChangeWrongPassword;
        case 'network-request-failed':
          _message = loc.resetNetworkError;
        case 'too-many-requests':
          _message = loc.resetTooManyRequests;
        case 'expired-action-code':
        case 'invalid-action-code':
          _message = loc.emailChangeExpired;
        case 'user-mismatch':
        case 'user-not-found':
        case 'user-disabled':
        case 'invalid-user-token':
        case 'user-token-expired':
          _sessionLost = true;
          _message = loc.emailChangeSession;
        default:
          _message = loc.emailChangeGeneric;
      }
    } catch (error) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        _message = _confirmedEmail == null
            ? loc.emailChangeGeneric
            : '${loc.emailSyncFailed}${error is FirebaseException && error.code == 'permission-denied'
                ? ' ${loc.profilePermissionDenied}' : ''}';
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _send() {
    if (_busy || !_formKey.currentState!.validate()) return;
    final email = _expectedEmail ?? _email.text.trim();
    final password = _needsPassword ? _password.text : null;
    _perform(() async {
      await widget.service.auth.setLanguageCode(Localizations.localeOf(context).languageCode);
      await widget.service.send(email, password: password);
      if (!mounted) return;
      _expectedEmail = email;
      _needsPassword = false;
      _password.clear();
      _message = AppLocalizations.of(context)!.emailChangeSent;
    });
  }

  void _check() {
    if (_expectedEmail == null) return;
    final expected = _expectedEmail!;
    _perform(() async {
      final user = await widget.service.refresh();
      if (user.email?.toLowerCase() != expected.toLowerCase() || !user.emailVerified) {
        if (mounted) _message = AppLocalizations.of(context)!.emailChangePending;
        return;
      }
      _confirmedEmail = user.email;
      // Finish syncing even if the auth router has disposed this page.
      final exists = await widget.service.syncEmail(user.email!);
      if (!mounted) return;
      _synced = true;
      _message = exists ? AppLocalizations.of(context)!.emailChangeSuccess
          : AppLocalizations.of(context)!.emailSyncMissing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final current = widget.service.auth.currentUser;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.changeEmailTitle), leading: BackButton(
          onPressed: _busy ? () {} : () => Navigator.pop(context))),
        body: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(key: ValueKey(current?.email), initialValue: current?.email ?? '',
              readOnly: true, decoration: InputDecoration(labelText: loc.email,
                border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.email))),
            const SizedBox(height: 16),
            TextFormField(controller: _email, readOnly: _expectedEmail != null,
              enabled: !_busy && !_sessionLost, keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(labelText: loc.newEmail, border: const OutlineInputBorder()),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return loc.resetEmailRequired;
                if (!RegExp(r'^[^@\s]+@[^@\s.]+(?:\.[^@\s.]+)+$').hasMatch(email)) return loc.resetEmailInvalid;
                if (_expectedEmail == null && email.toLowerCase() == current?.email?.toLowerCase()) return loc.emailChangeSame;
                return null;
              }),
            if (_needsPassword) ...[
              const SizedBox(height: 16),
              TextFormField(controller: _password, obscureText: true,
                enabled: !_busy, autocorrect: false, enableSuggestions: false,
                decoration: InputDecoration(labelText: loc.oldPassword, border: const OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? loc.emailChangeReauth : null),
            ],
            if (_message != null) ...[
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(_message!, textAlign: TextAlign.center)),
            ],
            const SizedBox(height: 24),
            if (_busy) const CircularProgressIndicator(),
            if (_confirmedEmail == null)
              ElevatedButton(onPressed: _busy || _sessionLost || widget.service.secondsToResend > 0 ? null : _send,
                child: Text('${_expectedEmail == null ? loc.emailChangeSend : loc.emailChangeResend}'
                    '${widget.service.secondsToResend > 0 ? ' (${widget.service.secondsToResend})' : ''}')),
            if (_expectedEmail != null && !_synced)
              TextButton(onPressed: _busy || _sessionLost ? null : _check,
                child: Text(_confirmedEmail == null ? loc.emailChangeCheck : loc.emailSyncRetry)),
            if (_sessionLost)
              TextButton(onPressed: _busy ? null : () => _perform(widget.service.auth.signOut),
                child: Text(loc.logoutButton)),
          ])),
        )),
      ),
    );
  }
}
