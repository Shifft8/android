import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailChangeService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final String uid;
  // shortcut: cooldown lasts for this process; Firebase enforces server limits across restarts.
  static final Map<String, DateTime> _attempts = {};
  bool _sending = false;

  EmailChangeService({required this.auth, required this.firestore, required this.uid});

  User requireUser() {
    final current = auth.currentUser;
    if (current == null || current.uid != uid) {
      throw FirebaseAuthException(code: 'user-mismatch');
    }
    return current;
  }

  bool get supportsPassword => requireUser().providerData.any((provider) => provider.providerId == 'password');

  int get secondsToResend {
    final last = _attempts[uid];
    return last == null ? 0 : (60 - DateTime.now().difference(last).inSeconds).clamp(0, 60);
  }

  Future<void> send(String newEmail, {String? password}) async {
    if (_sending || secondsToResend > 0) {
      throw FirebaseAuthException(code: 'too-many-requests');
    }
    _sending = true;
    try {
      if (password != null) {
        if (!supportsPassword || requireUser().email == null) {
          throw FirebaseAuthException(code: 'unsupported-provider');
        }
        await requireUser().reauthenticateWithCredential(EmailAuthProvider.credential(
          email: requireUser().email!, password: password,
        ));
        requireUser(); // Recheck the UID after reauthentication.
      }
      _attempts[uid] = DateTime.now();
      try {
        await requireUser().verifyBeforeUpdateEmail(newEmail);
      } on FirebaseAuthException catch (error) {
        // Reauthentication is not a sent email; allow the one explicit retry now.
        if (error.code == 'requires-recent-login') _attempts.remove(uid);
        rethrow;
      }
      requireUser();
    } finally {
      _sending = false;
    }
  }

  Future<User> refresh() async {
    await requireUser().reload();
    final refreshed = requireUser();
    await refreshed.getIdToken(true);
    return requireUser();
  }

  Future<bool> syncEmail(String email) async {
    void checkSession() {
      if (requireUser().email != email || !requireUser().emailVerified) {
        throw FirebaseAuthException(code: 'user-mismatch');
      }
    }
    checkSession();
    final ref = firestore.collection('users').doc(uid);
    return firestore.runTransaction<bool>((transaction) async {
      checkSession();
      final doc = await transaction.get(ref);
      checkSession();
      if (!doc.exists) return false;
      if (doc.data()?['email'] != email) transaction.update(ref, {'email': email});
      return true;
    });
  }
}
