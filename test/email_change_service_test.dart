import 'package:address_manager/services/email_change_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/email_change_fakes.dart';

void main() {
  late EmailTestUser user;
  late EmailTestAuth auth;
  late EmailTestStore store;
  late EmailChangeService service;
  setUp(() {
    user = EmailTestUser();
    auth = EmailTestAuth(user);
    store = EmailTestStore();
    service = EmailChangeService(auth: auth, firestore: store, uid: user.uid);
  });

  test('Sending confirmation does not change Auth email or Firestore', () async {
    await service.send('new@example.invalid');
    expect(user.email, 'old@example.invalid');
    expect(store.transactions, 0);
    expect(user.sent, ['new@example.invalid']);
    await expectLater(service.send('new@example.invalid'), throwsA(isA<FirebaseAuthException>()));
    expect(user.sent, hasLength(1));
  });

  test('Recent login uses current email and exact password then sends once', () async {
    user.recentLoginRequired = true;
    await expectLater(service.send('new@example.invalid'), throwsA(isA<FirebaseAuthException>()));
    await service.send('new@example.invalid', password: '  exact password  ');
    expect(user.suppliedPassword, '  exact password  ');
    expect(user.suppliedEmail, 'old@example.invalid');
    expect(user.calls, ['send', 'reauth', 'send']);
    expect(user.sent, ['new@example.invalid']);
  });

  test('Wrong password sends nothing; non-password provider is rejected', () async {
    user.reauthError = 'wrong-password';
    await expectLater(service.send('new@example.invalid', password: 'wrong'), throwsA(isA<FirebaseAuthException>()));
    expect(user.sent, isEmpty);
    user.provider = 'google.com';
    expect(service.supportsPassword, isFalse);
    await expectLater(service.send('new@example.invalid', password: 'unused'), throwsA(isA<FirebaseAuthException>()));
    expect(user.calls, ['reauth']);
  });

  test('UID change during reauthentication prevents retry', () async {
    user.afterReauth = () => auth.user = EmailTestUser();
    await expectLater(service.send('new@example.invalid', password: 'password'), throwsA(isA<FirebaseAuthException>()));
    expect(user.sent, isEmpty);
  });

  test('Refresh reloads before forcing token refresh', () async {
    user.confirmedAddress = 'new@example.invalid';
    final refreshed = await service.refresh();
    expect(refreshed.email, 'new@example.invalid');
    expect(user.calls, ['reload', 'token']);
  });

  test('UID change during reload prevents token refresh', () async {
    user.afterReload = () => auth.user = null;
    await expectLater(service.refresh(), throwsA(isA<FirebaseAuthException>()));
    expect(user.calls, ['reload']);
    expect(store.transactions, 0);
  });

  test('Only actual verified email may sync; all other fields stay intact', () async {
    final original = Map.of(store.data!);
    await expectLater(service.syncEmail('new@example.invalid'), throwsA(isA<FirebaseAuthException>()));
    user.confirmedAddress = 'new@example.invalid';
    await service.refresh();
    expect(await service.syncEmail(user.email), isTrue);
    expect(store.updates, [{'email': 'new@example.invalid'}]);
    for (final field in original.keys.where((key) => key != 'email')) {
      expect(store.data![field], original[field]);
    }
    expect(store.paths, everyElement(user.uid));
    await service.syncEmail(user.email);
    expect(store.updates, hasLength(1));
  });

  test('Missing profile is never created; stale sync stops on account change', () async {
    store.data = null;
    expect(await service.syncEmail(user.email), isFalse);
    expect(store.data, isNull);
    store.data = {'email': 'stale@example.invalid'};
    store.afterRead = () => auth.user = null;
    await expectLater(service.syncEmail(user.email), throwsA(isA<FirebaseAuthException>()));
    expect(store.updates, isEmpty);
  });

  test('Failed sync can retry without sending another email', () async {
    user.confirmedAddress = 'new@example.invalid';
    await service.refresh();
    store.writeError = 'permission-denied';
    await expectLater(service.syncEmail(user.email), throwsA(anything));
    expect(store.data!['email'], 'old@example.invalid');
    store.writeError = null;
    await service.syncEmail(user.email);
    expect(store.data!['email'], 'new@example.invalid');
    expect(user.sent, isEmpty);
  });

  test('Unverified Auth email and failed token refresh do not authorize syncing', () async {
    user.verified = false;
    await expectLater(service.syncEmail(user.email), throwsA(isA<FirebaseAuthException>()));
    expect(store.transactions, 0);
    user.tokenError = 'user-token-expired';
    await expectLater(service.refresh(), throwsA(isA<FirebaseAuthException>()));
    expect(store.transactions, 0);
  });

  test('A second recent-login failure is returned without an automatic loop', () async {
    user.afterReauth = () => user.recentLoginRequired = true;
    await expectLater(service.send('new@example.invalid', password: 'password'), throwsA(isA<FirebaseAuthException>()));
    expect(user.calls, ['reauth', 'send']);
    expect(user.sent, isEmpty);
  });
}
