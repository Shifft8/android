// Test-only SDK doubles: no network, credentials storage or real email.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class EmailTestProvider extends Fake implements UserInfo {
  final String id;
  EmailTestProvider(this.id);
  @override
  String get providerId => id;
}

class EmailTestCredential extends Fake implements UserCredential {}

class EmailTestUser extends Fake implements User {
  static int _next = 0;
  @override
  final String uid = 'email-test-${_next++}';
  String address = 'old@example.invalid';
  bool verified = true;
  String provider = 'password';
  bool recentLoginRequired = false;
  String? sendError;
  String? reauthError;
  String? tokenError;
  String? confirmedAddress;
  void Function()? afterReauth;
  void Function()? afterReload;
  final sent = <String>[];
  final calls = <String>[];
  String? suppliedPassword;
  String? suppliedEmail;

  @override
  String get email => address;
  @override
  bool get emailVerified => verified;
  @override
  String get displayName => 'Test Name';
  @override
  List<UserInfo> get providerData => [EmailTestProvider(provider)];
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? settings]) async {
    calls.add('send');
    if (recentLoginRequired) throw FirebaseAuthException(code: 'requires-recent-login');
    if (sendError != null) throw FirebaseAuthException(code: sendError!, message: 'INTERNAL_DETAILS');
    sent.add(newEmail);
  }
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    calls.add('reauth');
    final passwordCredential = credential as EmailAuthCredential;
    suppliedPassword = passwordCredential.password;
    suppliedEmail = passwordCredential.email;
    if (reauthError != null) throw FirebaseAuthException(code: reauthError!);
    recentLoginRequired = false;
    afterReauth?.call();
    return EmailTestCredential();
  }
  @override
  Future<void> reload() async {
    calls.add('reload');
    if (confirmedAddress != null) address = confirmedAddress!;
    afterReload?.call();
  }
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    expect(forceRefresh, isTrue);
    calls.add('token');
    if (tokenError != null) throw FirebaseAuthException(code: tokenError!);
    return 'test-only';
  }
}

class EmailTestAuth extends Fake implements FirebaseAuth {
  User? user;
  EmailTestAuth(this.user);
  @override
  User? get currentUser => user;
  @override
  Future<void> setLanguageCode(String? code) async {}
  @override
  Future<void> signOut() async => user = null;
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? value;
  _Snapshot(this.value);
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value == null ? null : Map.of(value!);
}

class _Ref extends Fake implements DocumentReference<Map<String, dynamic>> {
  final EmailTestStore store;
  _Ref(this.store);
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async => _Snapshot(store.data);
}

class _Collection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final EmailTestStore store;
  _Collection(this.store);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    store.paths.add(path);
    return _Ref(store);
  }
}

class _Transaction extends Fake implements Transaction {
  final EmailTestStore store;
  Map<String, dynamic>? fields;
  _Transaction(this.store);
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> ref) async {
    final snapshot = _Snapshot(store.data);
    store.afterRead?.call();
    return snapshot as DocumentSnapshot<T>;
  }
  @override
  Transaction update(DocumentReference ref, Map<String, dynamic> data) {
    fields = Map.of(data);
    return this;
  }
}

class EmailTestStore extends Fake implements FirebaseFirestore {
  Map<String, dynamic>? data = {
    'email': 'old@example.invalid', 'name': 'Name', 'phone': '123',
    'city': 'Warsaw', 'country': 'Poland', 'createdAt': Timestamp(100, 0), 'unknown': 'keep',
  };
  String? writeError;
  Completer<void>? pending;
  void Function()? afterRead;
  int transactions = 0;
  final paths = <String?>[];
  final updates = <Map<String, dynamic>>[];
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'users');
    return _Collection(this);
  }
  @override
  Future<T> runTransaction<T>(Future<T> Function(Transaction) handler,
      {Duration timeout = const Duration(seconds: 30), int maxAttempts = 5}) async {
    transactions++;
    final transaction = _Transaction(this);
    final result = await handler(transaction);
    if (pending != null) await pending!.future;
    if (writeError != null) throw FirebaseException(plugin: 'cloud_firestore', code: writeError!);
    if (transaction.fields != null) {
      updates.add(transaction.fields!);
      data = {...data!, ...transaction.fields!};
    }
    return result;
  }
}
