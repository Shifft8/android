// Test-only SDK doubles keep all Firestore operations in memory.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:address_manager/l10n/app_localizations.dart';
import 'package:address_manager/screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'profile-owner';
  @override
  String get email => 'auth@example.invalid';
  @override
  String get displayName => 'Auth Name';
}

class _Auth extends Fake implements FirebaseAuth {
  User? user = _User();
  @override
  User? get currentUser => user;
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
  final _Store store;
  _Ref(this.store);
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    store.reads++;
    expect(options?.source, Source.server);
    if (store.readError != null) throw store.readError!;
    return _Snapshot(store.data);
  }
}

class _Collection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final _Store store;
  _Collection(this.store);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    expect(path, 'profile-owner');
    return _Ref(store);
  }
}

class _Transaction extends Fake implements Transaction {
  final _Store store;
  _Transaction(this.store);
  Map<String, dynamic>? fields;
  bool creating = false;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> ref) async =>
      _Snapshot(store.data) as DocumentSnapshot<T>;

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    creating = true;
    fields = Map<String, dynamic>.from(data as Map);
    return this;
  }

  @override
  Transaction update(DocumentReference ref, Map<String, dynamic> data) {
    fields = Map.of(data);
    return this;
  }
}

class _Store extends Fake implements FirebaseFirestore {
  Map<String, dynamic>? data;
  Object? readError;
  Object? writeError;
  Completer<void>? pending;
  int reads = 0;
  int writes = 0;
  Map<String, dynamic>? lastFields;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'users');
    return _Collection(this);
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(Transaction) handler,
      {Duration timeout = const Duration(seconds: 30), int maxAttempts = 5}) async {
    writes++;
    final transaction = _Transaction(this);
    final result = await handler(transaction);
    if (pending != null) await pending!.future;
    if (writeError != null) throw writeError!;
    lastFields = transaction.fields;
    data = transaction.creating ? Map.of(lastFields!) : {...data!, ...lastFields!};
    return result;
  }
}

Map<String, dynamic> _existing() => {
  'name': 'Existing Name', 'phone': '123', 'city': 'Warsaw', 'country': 'Poland',
  'email': 'legacy@example.invalid', 'createdAt': Timestamp(100, 0), 'unknown': 'keep',
};

Future<void> _open(WidgetTester tester, _Store store, { _Auth? auth, String language = 'en' }) async {
  await tester.pumpWidget(MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: UserProfileScreen(auth: auth ?? _Auth(), firestore: store),
  ));
  await tester.pumpAndSettle();
}

Future<void> _edit(WidgetTester tester, {bool creating = false}) async {
  final button = find.text(creating ? 'Complete profile' : 'Edit profile');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Save');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('No session ends loading without reading Firestore', (tester) async {
    final store = _Store();
    await _open(tester, store, auth: _Auth()..user = null);
    expect(store.reads, 0);
    expect(find.text('Error: user not authorized'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Edit profile'), findsNothing);
  });

  testWidgets('Failed read disables editing and retry loads real values', (tester) async {
    final store = _Store()..data = _existing()
      ..readError = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    await _open(tester, store);
    expect(find.text('Access to this profile was denied.'), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);
    expect(store.writes, 0);
    store.readError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Existing Name'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('Update writes four fields and keeps Auth email read-only', (tester) async {
    final store = _Store()..data = _existing();
    final original = Map.of(store.data!);
    await _open(tester, store);
    expect(find.text('auth@example.invalid'), findsOneWidget);
    expect(find.text('legacy@example.invalid'), findsNothing);
    await _edit(tester);
    final email = tester.widget<TextField>(find.descendant(
      of: find.byType(TextFormField).at(1), matching: find.byType(TextField)));
    expect(email.readOnly, isTrue);
    await tester.enterText(find.byType(TextFormField).first, '  New Name  ');
    await _save(tester);
    expect(store.lastFields!.keys.toSet(), {'name', 'phone', 'city', 'country'});
    expect(store.data!['name'], 'New Name');
    for (final field in ['email', 'createdAt', 'unknown']) {
      expect(store.data![field], original[field]);
    }
    expect(find.text('Profile successfully updated!'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('Missing profile requires explicit creation with Auth email and timestamp', (tester) async {
    final store = _Store();
    await _open(tester, store);
    expect(store.writes, 0);
    expect(find.text('Your profile has not been created yet. Fill it in to continue.'), findsOneWidget);
    await _edit(tester, creating: true);
    await _save(tester);
    expect(store.data!.keys.toSet(), {'name', 'phone', 'city', 'country', 'email', 'createdAt'});
    expect(store.data!['email'], 'auth@example.invalid');
    expect(store.data!['createdAt'], isA<FieldValue>());
  });

  testWidgets('Profile created by another client is not overwritten', (tester) async {
    final store = _Store();
    await _open(tester, store);
    await _edit(tester, creating: true);
    store.data = _existing();
    await _save(tester);
    expect(store.data!['name'], 'Existing Name');
    expect(store.lastFields, isNull);
    expect(find.text('The profile changed or was removed. Cancel and reload it before saving.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  for (final code in ['permission-denied', 'unavailable']) {
    testWidgets('Write failure $code retains draft and permits retry', (tester) async {
      final store = _Store()..data = _existing()
        ..writeError = FirebaseException(plugin: 'cloud_firestore', code: code);
      await _open(tester, store);
      await _edit(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Draft');
      await _save(tester);
      expect(find.text('Profile successfully updated!'), findsNothing);
      expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text, 'Draft');
      expect(store.data!['name'], 'Existing Name');
      expect(find.text(code == 'permission-denied' ? 'Access to this profile was denied.'
          : 'Connection failed. Check your network and try again.'), findsOneWidget);
      store.writeError = null;
      await _save(tester);
      expect(store.data!['name'], 'Draft');
    });
  }

  testWidgets('Save blocks duplicate calls, back, cancel and dismissal until ack', (tester) async {
    final store = _Store()..data = _existing()..pending = Completer<void>();
    await _open(tester, store);
    await _edit(tester);
    final button = find.widgetWithText(ElevatedButton, 'Save');
    await tester.ensureVisible(button);
    final save = tester.widget<ElevatedButton>(button).onPressed!;
    save(); save();
    await tester.pump();
    expect(store.writes, 1);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancel')).onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Profile successfully updated!'), findsNothing);
    store.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Profile successfully updated!'), findsOneWidget);
  });

  testWidgets('Session change cannot save previous account draft', (tester) async {
    final store = _Store()..data = _existing();
    final auth = _Auth();
    await _open(tester, store, auth: auth);
    await _edit(tester);
    auth.user = null;
    await _save(tester);
    expect(store.writes, 0);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Profile successfully updated!'), findsNothing);
  });

  testWidgets('Deleted profile is not silently recreated by editing', (tester) async {
    final store = _Store()..data = _existing();
    await _open(tester, store);
    await _edit(tester);
    store.data = null;
    await _save(tester);
    expect(store.data, isNull);
    expect(store.lastFields, isNull);
    expect(find.text('The profile changed or was removed. Cancel and reload it before saving.'), findsOneWidget);
  });

  testWidgets('Completing a save after screen disposal is safe', (tester) async {
    final store = _Store()..data = _existing()..pending = Completer<void>();
    await _open(tester, store);
    await _edit(tester);
    final button = find.widgetWithText(ElevatedButton, 'Save');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    store.pending!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'ru', 'pl', 'uk']) {
    testWidgets('Missing profile state is localized in $language', (tester) async {
      final store = _Store();
      await _open(tester, store, language: language);
      final context = tester.element(find.byType(UserProfileScreen));
      final loc = AppLocalizations.of(context)!;
      expect(find.text(loc.profileMissing), findsOneWidget);
      expect(find.text(loc.profileCreate), findsOneWidget);
      expect(store.writes, 0);
    });
  }
}
