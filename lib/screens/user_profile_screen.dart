import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import '../services/email_change_service.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';



class UserProfileScreen extends StatefulWidget {
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  const UserProfileScreen({super.key, this.auth, this.firestore});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _ProfileEditor extends StatefulWidget {
  final Map<String, String> initialFields;
  final String email;
  final bool creating;
  final Future<void> Function(Map<String, String>) onSave;

  const _ProfileEditor({required this.initialFields, required this.email,
    required this.creating, required this.onSave});

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialFields.map((key, value) =>
      MapEntry(key, TextEditingController(text: value)));
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context)!;
    final fields = _controllers.map((key, controller) => MapEntry(key, controller.text.trim()));
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave(fields);
      if (!mounted) return;
      // Let PopScope rebuild before returning the confirmed save result.
      setState(() => _saving = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _profileError(context, error, loc.profileSaveError);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Widget field(String key, String label, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[key],
        enabled: !_saving,
        keyboardType: key == 'phone' ? TextInputType.phone : TextInputType.text,
        validator: key == 'name' ? (value) => value == null || value.trim().isEmpty
            ? loc.profileNameRequired : null : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(),
          prefixIcon: Icon(icon)),
      ),
    );
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.creating ? loc.profileCreate : loc.editProfile,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              field('name', loc.profileName, Icons.person),
              TextFormField(initialValue: widget.email, readOnly: true,
                decoration: InputDecoration(labelText: loc.email,
                  border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.email))),
              const SizedBox(height: 12),
              field('phone', loc.phone, Icons.phone),
              field('city', loc.city, Icons.location_city),
              field('country', loc.country, Icons.flag),
              if (_error != null) Semantics(liveRegion: true,
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _saving ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(loc.save, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text(loc.cancel)),
            ],
          ),
        )),
      ),
    );
  }
}

enum _ProfileStatus { loading, ready, missing, error, noAuth }

String _profileError(BuildContext context, Object error, String fallback) {
  final loc = AppLocalizations.of(context)!;
  if (error is FirebaseAuthException && const {
    'user-mismatch', 'no-current-user', 'user-token-expired',
    'invalid-user-token', 'user-not-found', 'user-disabled',
  }.contains(error.code)) {
    return loc.emailChangeSession;
  }
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') return loc.profilePermissionDenied;
    if (error.code == 'unavailable' || error.code == 'network-request-failed') {
      return loc.profileNetworkError;
    }
    if (error.code == 'not-found' || error.code == 'already-exists') {
      return loc.profileChanged;
    }
  }
  return fallback;
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;
  String? _loadedUid;
  _ProfileStatus _status = _ProfileStatus.loading;
  Object? _loadError;
  Object? _emailSyncError;
  bool _openingEmail = false;
  bool _openingPassword = false;
  bool _saved = false;
  String _userName = '';
  String _userPhone = '';
  String _userCountry = '';
  String _userCity = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    setState(() {
      _status = user == null ? _ProfileStatus.noAuth : _ProfileStatus.loading;
      _loadedUid = null;
      _loadError = null;
      _emailSyncError = null;
      _saved = false;
    });
    if (user == null) return;
    try {
      final emailService = EmailChangeService(auth: _auth, firestore: _firestore, uid: user.uid);
      final refreshed = await emailService.refresh();
      if (!refreshed.emailVerified) {
        if (mounted) setState(() => _status = _ProfileStatus.noAuth);
        return;
      }
      // Never treat an offline cache miss as a missing server profile.
      final doc = await _firestore.collection('users').doc(user.uid)
          .get(const GetOptions(source: Source.server));
      Object? syncError;
      if (doc.exists && refreshed.email != null && doc.data()?['email'] != refreshed.email) {
        try {
          await emailService.syncEmail(refreshed.email!);
        } on FirebaseAuthException {
          rethrow;
        } catch (error) {
          syncError = error;
        }
      }
      if (!mounted) return;
      if (_auth.currentUser?.uid != user.uid) {
        setState(() => _status = _ProfileStatus.noAuth);
        return;
      }
      final data = doc.data();
      setState(() {
        _emailSyncError = syncError;
        _userName = data?['name'] as String? ?? user.displayName ?? '';
        _userPhone = data?['phone'] as String? ?? '';
        _userCity = data?['city'] as String? ?? '';
        _userCountry = data?['country'] as String? ?? '';
        _loadedUid = user.uid;
        _status = doc.exists ? _ProfileStatus.ready : _ProfileStatus.missing;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _status = _ProfileStatus.error; _loadError = error; });
    }
  }

  Future<void> _saveProfile(Map<String, String> fields) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != _loadedUid ||
        (_status != _ProfileStatus.ready && _status != _ProfileStatus.missing)) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final ref = _firestore.collection('users').doc(user.uid);
    final creating = _status == _ProfileStatus.missing;
    // Transactions fail offline rather than leaving a queued write and a locked form.
    await _firestore.runTransaction<void>((transaction) async {
      final existing = await transaction.get(ref);
      if (creating) {
        if (existing.exists) {
          throw FirebaseException(plugin: 'cloud_firestore', code: 'already-exists');
        }
        transaction.set(ref, {
          ...fields,
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        if (!existing.exists) {
          throw FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
        }
        transaction.update(ref, fields);
      }
    });
    if (!mounted) return;
    setState(() {
      _userName = fields['name']!;
      _userPhone = fields['phone']!;
      _userCity = fields['city']!;
      _userCountry = fields['country']!;
      _status = _ProfileStatus.ready;
    });
  }

  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    final loc = AppLocalizations.of(context)!;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(loc.logoutButton),
          content: Text(loc.logoutButton),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(loc.cancel)),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(loc.logoutButton)),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await _auth.signOut();
      // RootScreen replaces the navigator and removes all user routes.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error}: $error')),
      );
    } finally {
      _loggingOut = false;
    }
  }
  Future<void> _showEditProfileSheet() async {
    if (_status != _ProfileStatus.ready && _status != _ProfileStatus.missing) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProfileEditor(
        initialFields: {
          'name': _userName, 'phone': _userPhone,
          'city': _userCity, 'country': _userCountry,
        },
        email: _auth.currentUser?.email ?? '',
        creating: _status == _ProfileStatus.missing,
        onSave: _saveProfile,
      ),
    );
    if (mounted && saved == true) setState(() => _saved = true);
  }

  Future<void> _showChangeEmail() async {
    if (_openingEmail) return;
    final user = _auth.currentUser;
    if (user == null || user.uid != _loadedUid) return;
    _openingEmail = true;
    try {
      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ChangeEmailScreen(
        service: EmailChangeService(auth: _auth, firestore: _firestore, uid: user.uid),
      )));
      if (mounted) await _loadUserProfile();
    } finally {
      _openingEmail = false;
    }
  }

  Future<void> _showChangePassword() async {
    if (_openingPassword) return;
    final user = _auth.currentUser;
    if (user == null || user.uid != _loadedUid) return;
    _openingPassword = true;
    try {
      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(
        auth: _auth, uid: user.uid,
      )));
    } finally {
      _openingPassword = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем экземпляр локализации в самом начале сборки экрана
    final localizations = AppLocalizations.of(context)!;

    if (_status == _ProfileStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_status == _ProfileStatus.error || _status == _ProfileStatus.noAuth ||
        _status == _ProfileStatus.missing) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.profile)),
        body: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_auth.currentUser?.email ?? ''),
            const SizedBox(height: 16),
            Text(_status == _ProfileStatus.noAuth ? localizations.errorNoAuth
                : _status == _ProfileStatus.missing ? localizations.profileMissing
                : _profileError(context, _loadError!, localizations.profileLoadError),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_status == _ProfileStatus.error || _status == _ProfileStatus.missing)
              ElevatedButton(onPressed: _loadUserProfile, child: Text(localizations.profileRetry)),
            if (_status == _ProfileStatus.missing)
              ElevatedButton(onPressed: _showEditProfileSheet, child: Text(localizations.profileCreate)),
            if (_status != _ProfileStatus.noAuth)
              TextButton(onPressed: _logout, child: Text(localizations.logoutButton)),
          ]),
        )),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        actions: [IconButton(onPressed: _loadUserProfile,
          tooltip: localizations.profileRetry, icon: const Icon(Icons.refresh))],
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          localizations.profile,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            if (_saved) Text(localizations.profileUpdated),
            if (_emailSyncError != null) ...[
              Text('${localizations.emailSyncFailed} ${_profileError(context, _emailSyncError!, localizations.profileSaveError)}',
                textAlign: TextAlign.center),
              TextButton(onPressed: _loadUserProfile, child: Text(localizations.emailSyncRetry)),
            ],
            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: const Icon(Icons.person, size: 55, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    _auth.currentUser?.email ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileRow(
                    Icons.phone_android,
                    localizations.phone,
                    _userPhone.isEmpty ? '—' : _userPhone,
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  _buildProfileRow(
                    Icons.flag_outlined,
                    localizations.country,
                    _userCountry,
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  _buildProfileRow(
                    Icons.location_city,
                    localizations.city,
                    _userCity.isEmpty ? '—' : _userCity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEditProfileSheet,
                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                label: Text(
                  localizations.editProfile,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _showChangeEmail,
                icon: const Icon(Icons.email_outlined),
                label: Text(localizations.changeEmailTitle),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _showChangePassword,
                icon: const Icon(Icons.lock_outline),
                label: Text(localizations.changePassword),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: Text(
                  localizations.logoutButton,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }
}
