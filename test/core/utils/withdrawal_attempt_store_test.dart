import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_attempt.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';
import 'package:snip_fair/core/utils/preferences/withdrawal_attempt_store.dart';

import '../../features/earnings/withdrawal_test_support.dart';

/// Preferences whose platform storage is broken: every call throws.
class _BrokenPrefs extends Fake implements SharedPreferences {
  @override
  String? getString(String key) => throw StateError('storage unavailable');

  @override
  Future<bool> setString(String key, String value) =>
      Future.error(StateError('storage unavailable'));

  @override
  Future<bool> remove(String key) =>
      Future.error(StateError('storage unavailable'));
}

const _attempt = WithdrawalAttempt(
  idempotencyKey: '3b241101-e2bb-4255-8caf-4136c566a962',
  paymentMethodId: '7',
  amount: 250.5,
  status: WithdrawalAttemptStatus.unknown,
);

WithdrawalAttempt? _found(StoredWithdrawalAttempt result) =>
    result is FoundWithdrawalAttempt ? result.attempt : null;

void main() {
  test('round-trips key, amount, method and status', () async {
    final prefs = await stylistPrefs();
    final store = WithdrawalAttemptStore(prefs);

    expect(store.load(), isA<NoStoredWithdrawalAttempt>());
    expect(await store.save(_attempt), isTrue);

    expect(_found(store.load()), _attempt);
    expect(prefs.getString(attemptStorageKey()), contains('"v":1'));
    expect(
        prefs.getString(attemptStorageKey()), contains('"amount_cents":25050'));
  });

  test('survives an app restart (a fresh preferences instance)', () async {
    final before = await stylistPrefs();
    await WithdrawalAttemptStore(before).save(_attempt);

    final after = await restartPrefs(before);

    expect(_found(WithdrawalAttemptStore(after).load()), _attempt);
  });

  test('is scoped to the signed-in user', () async {
    final prefs = await stylistPrefs();
    await WithdrawalAttemptStore(prefs).save(_attempt);

    // Another stylist signs in on the same device.
    final other = await stylistPrefs(
      userId: 99,
      values: {attemptStorageKey(): prefs.getString(attemptStorageKey())!},
    );

    expect(
      WithdrawalAttemptStore(other).load(),
      isA<NoStoredWithdrawalAttempt>(),
    );
  });

  test('clear removes the attempt', () async {
    final store = WithdrawalAttemptStore(await stylistPrefs());
    await store.save(_attempt);

    expect(await store.clear(), isTrue);

    expect(store.load(), isA<NoStoredWithdrawalAttempt>());
  });

  group('corrupt data is reported, never treated as "nothing pending"', () {
    final corrupt = {
      'not JSON': '{oops',
      'not an object': '[1, 2]',
      'missing key': '{"v":1,"method":"7","amount_cents":100,'
          '"status":"unknown"}',
      'malformed key': '{"v":1,"key":"bad key!","method":"7",'
          '"amount_cents":100,"status":"unknown"}',
      'non-integer amount': '{"v":1,"key":"3b241101-e2bb-4255-8caf-'
          '4136c566a962","method":"7","amount_cents":"100",'
          '"status":"unknown"}',
      'non-numeric method': '{"v":1,"key":"3b241101-e2bb-4255-8caf-'
          '4136c566a962","method":"FNB","amount_cents":100,'
          '"status":"unknown"}',
      'zero amount': '{"v":1,"key":"3b241101-e2bb-4255-8caf-4136c566a962",'
          '"method":"7","amount_cents":0,"status":"unknown"}',
    };

    corrupt.forEach((name, raw) {
      test(name, () async {
        final store = WithdrawalAttemptStore(
          await stylistPrefs(values: {attemptStorageKey(): raw}),
        );

        expect(store.load(), isA<UnreadableWithdrawalAttempt>());
      });
    });
  });

  group('an intact key and payload are recovered, never lost', () {
    final salvageable = {
      'another version': '{"v":2,"key":"3b241101-e2bb-4255-8caf-'
          '4136c566a962","method":"7","amount_cents":25050,'
          '"status":"rejected"}',
      'unknown status': '{"v":1,"key":"3b241101-e2bb-4255-8caf-'
          '4136c566a962","method":"7","amount_cents":25050,'
          '"status":"paid"}',
      'missing status': '{"v":1,"key":"3b241101-e2bb-4255-8caf-'
          '4136c566a962","method":7,"amount_cents":25050}',
    };

    salvageable.forEach((name, raw) {
      test('$name: recovered as unknown (the most cautious status)', () async {
        final store = WithdrawalAttemptStore(
          await stylistPrefs(values: {attemptStorageKey(): raw}),
        );

        expect(_found(store.load()), _attempt);
      });
    });
  });

  test('clear with a key only removes that attempt', () async {
    final store = WithdrawalAttemptStore(await stylistPrefs());
    await store.save(_attempt);

    expect(await store.clear(idempotencyKey: 'another-key-0000'), isFalse);
    expect(_found(store.load()), _attempt);

    expect(
      await store.clear(idempotencyKey: _attempt.idempotencyKey),
      isTrue,
    );
    expect(store.load(), isA<NoStoredWithdrawalAttempt>());
  });

  test('unavailable storage: load is unreadable, save and clear fail',
      () async {
    final store = WithdrawalAttemptStore(_BrokenPrefs());

    expect(store.load(), isA<UnreadableWithdrawalAttempt>());
    expect(await store.save(_attempt), isFalse);
    expect(await store.clear(), isFalse);
  });

  test('without a signed-in user nothing is saved', () async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
    final store = WithdrawalAttemptStore(await SharedPreferences.getInstance());

    expect(await store.save(_attempt), isFalse);
    expect(store.load(), isA<NoStoredWithdrawalAttempt>());
  });

  test('logout clears the session but keeps the unresolved attempt', () async {
    final prefs = await stylistPrefs(
      values: {SharedPrefKey.accessToken: 'secret-token'},
    );
    await WithdrawalAttemptStore(prefs).save(_attempt);

    await LocalKeyStorage(prefs).clearData();

    expect(prefs.getString(SharedPrefKey.accessToken), isNull);
    expect(prefs.getString(SharedPrefKey.currentUser), isNull);
    expect(prefs.getString(attemptStorageKey()), isNotNull);

    // The same stylist signs back in: the attempt is there again.
    await prefs.setString(
      SharedPrefKey.currentUser,
      '{"id":$testStylistId}',
    );
    expect(_found(WithdrawalAttemptStore(prefs).load()), _attempt);
  });

  test('the idempotency key never appears in toString', () {
    expect(_attempt.toString(), isNot(contains('3b241101')));
  });
}
