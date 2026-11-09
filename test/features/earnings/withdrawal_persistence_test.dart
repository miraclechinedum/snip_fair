import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_attempt.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_failure.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/preferences/withdrawal_attempt_store.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';

import 'earnings_fixtures.dart';
import 'withdrawal_test_support.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

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

/// Preferences that can be read but not written.
class _ReadOnlyPrefs extends Fake implements SharedPreferences {
  _ReadOnlyPrefs(this._inner);

  final SharedPreferences _inner;

  @override
  String? getString(String key) => _inner.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      Future.error(StateError('disk full'));

  @override
  Future<bool> remove(String key) => Future.error(StateError('disk full'));
}

final _fnb = PaymentMethod(id: 7, bankName: 'FNB', accountNumber: '62001234');
final _absa = PaymentMethod(id: 8, bankName: 'ABSA', accountNumber: '40705678');

RemoteException _server(int status, String message, {String? code}) =>
    RemoteException.serverError(
      status,
      ServerError(message: message),
      code: code,
    );

const _conflict = RemoteException.serverError(
  409,
  ServerError(
    message: 'Ooops.. This idempotency key was already used for a different '
        'withdrawal.',
  ),
  code: 'IDEMPOTENCY_KEY_REUSED',
);

/// Lets the fire-and-forget refreshes finish first.
Future<void> _close(EarningsCubit cubit) async {
  await Future<void>.delayed(Duration.zero);
  await cubit.close();
}

void main() {
  late _MockProfileRepository repo;
  late SharedPreferences prefs;

  /// Keys handed out, in order, across every cubit in a test.
  late List<String> issuedKeys;

  /// (method, amount, key) of every withdrawal request, in order.
  late List<(String, double, String)> sent;
  late List<FutureOr<ApiResult<WithdrawalSubmission>> Function()> answers;

  /// Whether `/wallet/transactions` loads.
  late bool historyLoads;

  EarningsCubit newCubit([SharedPreferences? using]) => EarningsCubit(
        repo,
        WithdrawalAttemptStore(using ?? prefs),
        newIdempotencyKey: () {
          final key = 'key-${issuedKeys.length + 1}-0000';
          issuedKeys.add(key);
          return key;
        },
      );

  WithdrawalAttempt? stored([SharedPreferences? using]) =>
      switch (WithdrawalAttemptStore(using ?? prefs).load()) {
        FoundWithdrawalAttempt(:final attempt) => attempt,
        _ => null,
      };

  setUp(() async {
    prefs = await stylistPrefs();
    repo = _MockProfileRepository();
    issuedKeys = [];
    sent = [];
    answers = [];
    historyLoads = true;
    // Lookup unavailable by default: the pre-lookup behaviour.
    when(() => repo.lookupWithdrawal(any())).thenAnswer(
      (_) async =>
          const ApiResult.failure(error: RemoteException.timeoutError()),
    );
    when(repo.getEarnings).thenAnswer(
      (_) async => ApiResult.success(
        data: StylistEarnings.fromJson(problematicEarningsResponse()),
      ),
    );
    when(
      () => repo.getWalletTransactions(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => historyLoads
          ? ApiResult.success(data: CustomerWalletTransactionList(data: []))
          : const ApiResult.failure(error: RemoteException.timeoutError()),
    );
    when(
      () => repo.requestPayout(
        any(),
        any(),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((invocation) async {
      sent.add(
        (
          invocation.positionalArguments[0] as String,
          invocation.positionalArguments[1] as double,
          invocation.namedArguments[#idempotencyKey] as String,
        ),
      );
      return answers.removeAt(0)();
    });
  });

  test('the attempt is saved before the request is sent', () async {
    final cubit = newCubit();
    WithdrawalAttempt? atSendTime;
    answers.add(() {
      atSendTime = stored();
      return const ApiResult.success(
        data: WithdrawalSubmission(amount: 250.5),
      );
    });

    await cubit.requestPayout(_fnb, 250.5);

    expect(atSendTime?.idempotencyKey, 'key-1-0000');
    expect(atSendTime?.status, WithdrawalAttemptStatus.sending);
    await _close(cubit);
  });

  test('restored after screen recreation; retried with the same key/payload',
      () async {
    final first = newCubit();
    answers
      ..add(
          () => const ApiResult.failure(error: RemoteException.timeoutError()))
      ..add(
        () =>
            const ApiResult.success(data: WithdrawalSubmission(amount: 250.5)),
      );
    await first.requestPayout(_fnb, 250.5);
    // The earnings screen is disposed.
    await _close(first);
    expect(stored()?.status, WithdrawalAttemptStatus.unknown);

    final second = newCubit();
    await second.restorePendingWithdrawal();

    expect(second.state.pendingWithdrawal?.idempotencyKey, 'key-1-0000');
    expect(second.state.pendingWithdrawal?.outcomeUnknown, isTrue);
    expect(await second.retryPendingWithdrawal(), isTrue);
    expect(sent, [
      ('7', 250.5, 'key-1-0000'),
      ('7', 250.5, 'key-1-0000'),
    ]);
    expect(issuedKeys, ['key-1-0000'], reason: 'no key for the reopen');
    await _close(second);
  });

  test('restored after an app restart; same key/payload; 204 clears storage',
      () async {
    final before = newCubit();
    answers
      ..add(() => ApiResult.failure(error: RemoteException.httpError(502)))
      ..add(
        () =>
            const ApiResult.success(data: WithdrawalSubmission(amount: 250.5)),
      );
    await before.requestPayout(_fnb, 250.5);
    await _close(before);

    // App restart: new preferences instance, new cubit, new key generator.
    final restarted = await restartPrefs(prefs);
    final after = newCubit(restarted);
    await after.restorePendingWithdrawal();

    // Submitting the same details from the form is a retry too.
    expect(await after.requestPayout(_fnb, 250.5), isTrue);

    expect(sent.last, ('7', 250.5, 'key-1-0000'));
    expect(issuedKeys, ['key-1-0000']);
    expect(after.state.pendingWithdrawal, isNull);
    expect(stored(restarted), isNull);
    expect(restarted.getString(attemptStorageKey()), isNull);
    await _close(after);
  });

  test('a request in flight when the app was killed is restored as unknown',
      () async {
    final store = WithdrawalAttemptStore(prefs);
    await store.save(
      const WithdrawalAttempt(
        idempotencyKey: 'key-9-0000',
        paymentMethodId: '7',
        amount: 120,
      ),
    );

    final cubit = newCubit(await restartPrefs(prefs));
    await cubit.restorePendingWithdrawal();

    expect(
      cubit.state.pendingWithdrawal?.status,
      WithdrawalAttemptStatus.unknown,
    );
    expect(cubit.state.pendingWithdrawal?.idempotencyKey, 'key-9-0000');
    expect(issuedKeys, isEmpty);
    await _close(cubit);
  });

  group('a new withdrawal is refused while an earlier one is unresolved', () {
    for (final (what, method, amount) in [
      ('amount', _fnb, 100.0),
      ('bank account', _absa, 250.5),
    ]) {
      test('different $what after a restart', () async {
        final before = newCubit();
        answers.add(
          () => const ApiResult.failure(error: RemoteException.timeoutError()),
        );
        await before.requestPayout(_fnb, 250.5);
        await _close(before);

        final after = newCubit(await restartPrefs(prefs));
        await after.restorePendingWithdrawal();
        expect(await after.requestPayout(method, amount), isFalse);

        expect(sent, hasLength(1), reason: 'nothing new was sent');
        expect(issuedKeys, ['key-1-0000']);
        expect(
          (after.state.requestPayoutState.error! as WithdrawalBlockedException)
              .reason,
          WithdrawalBlockReason.unresolvedAttempt,
        );
        expect(after.state.pendingWithdrawal?.idempotencyKey, 'key-1-0000');
        await _close(after);
      });
    }

    test('a refused retry stays unresolved (refusals precede the replay check)',
        () async {
      final cubit = newCubit();
      answers
        ..add(
          () => const ApiResult.failure(error: RemoteException.timeoutError()),
        )
        ..add(
          () => ApiResult.failure(
            error: _server(
              503,
              'Withdrawals are temporarily unavailable.',
              code: 'PAYOUT_REQUESTS_DISABLED',
            ),
          ),
        );

      await cubit.requestPayout(_fnb, 250.5);
      await cubit.retryPendingWithdrawal();

      expect(
        cubit.state.pendingWithdrawal?.status,
        WithdrawalAttemptStatus.unknown,
      );
      expect(stored()?.status, WithdrawalAttemptStatus.unknown);
      expect(await cubit.requestPayout(_fnb, 100), isFalse);
      expect(sent, hasLength(2));
      await _close(cubit);
    });

    test(
        'transaction history showing no withdrawal does not resolve it; it '
        'stays blocked across restarts until a retry is answered 204',
        () async {
      final cubit = newCubit();
      answers
        ..add(
          () => const ApiResult.failure(error: RemoteException.timeoutError()),
        )
        ..add(
          () => const ApiResult.success(
              data: WithdrawalSubmission(amount: 250.5)),
        );
      await cubit.requestPayout(_fnb, 250.5);
      // The post-timeout refresh shows an empty history (the request may
      // simply not have committed yet).
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.transactionsState.data!.where((t) => t.type == 'withdraw'),
        isEmpty,
      );
      expect(cubit.state.pendingWithdrawal?.isUnresolved, isTrue);
      await cubit.fetchTransactions(isInitial: true);
      expect(cubit.state.pendingWithdrawal?.isUnresolved, isTrue);
      await _close(cubit);

      final reopened = newCubit(await restartPrefs(prefs));
      await reopened.restorePendingWithdrawal();
      expect(await reopened.requestPayout(_fnb, 100), isFalse);
      expect(sent, hasLength(1));

      expect(await reopened.retryPendingWithdrawal(), isTrue);
      expect(sent.last, ('7', 250.5, 'key-1-0000'));
      expect(reopened.state.pendingWithdrawal, isNull);
      // Only now is a different withdrawal allowed, with a new key.
      answers.add(
        () => const ApiResult.success(data: WithdrawalSubmission(amount: 100)),
      );
      expect(await reopened.requestPayout(_fnb, 100), isTrue);
      expect(sent.last.$3, 'key-2-0000');
      await _close(reopened);
    });

    test('a second earnings screen cannot overwrite the pending attempt',
        () async {
      // Both screens are open; B was created before A sent anything.
      final a = newCubit();
      final b = newCubit();
      answers
        ..add(
          () => const ApiResult.failure(error: RemoteException.timeoutError()),
        )
        ..add(
          () => const ApiResult.success(
              data: WithdrawalSubmission(amount: 250.5)),
        );
      await a.requestPayout(_fnb, 250.5);

      // B: a different withdrawal is refused, nothing is sent or saved.
      expect(await b.requestPayout(_absa, 900), isFalse);
      expect(sent, hasLength(1));
      expect(stored()?.idempotencyKey, 'key-1-0000');
      expect(issuedKeys, ['key-1-0000']);

      // B: the same details are a retry of A's attempt, under A's key.
      expect(await b.requestPayout(_fnb, 250.5), isTrue);
      expect(sent.last, ('7', 250.5, 'key-1-0000'));
      expect(stored(), isNull);
      await _close(a);
      await _close(b);
    });

    test('a refused key on a retry does not drop the uncertain attempt',
        () async {
      final cubit = newCubit();
      answers
        ..add(
          () => const ApiResult.failure(error: RemoteException.timeoutError()),
        )
        ..add(
          () => ApiResult.failure(
            error: _server(
              400,
              'Ooops.. The idempotency key must be 8-100 letters.',
              code: 'IDEMPOTENCY_KEY_INVALID',
            ),
          ),
        );
      await cubit.requestPayout(_fnb, 250.5);
      await cubit.retryPendingWithdrawal();

      expect(stored()?.idempotencyKey, 'key-1-0000');
      expect(stored()?.status, WithdrawalAttemptStatus.unknown);
      await _close(cubit);
    });
  });

  group('409', () {
    test('never reported as success; resolved after the history reloads',
        () async {
      final cubit = newCubit();
      answers.add(() => const ApiResult.failure(error: _conflict));

      expect(await cubit.requestPayout(_fnb, 250.5), isFalse);

      expect(cubit.state.requestPayoutState.hasSuccess, isFalse);
      expect(cubit.state.requestPayoutState.error, _conflict);
      verify(
        () => repo.getWalletTransactions(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
      verify(repo.getEarnings).called(1);
      expect(cubit.state.pendingWithdrawal, isNull);
      expect(stored(), isNull);
      expect(sent, hasLength(1), reason: 'no automatic fresh-key retry');
      await _close(cubit);
    });

    test('a conflict is never resent, even with the same details', () async {
      historyLoads = false;
      final cubit = newCubit();
      answers.add(() => const ApiResult.failure(error: _conflict));
      await cubit.requestPayout(_fnb, 250.5);
      expect(
        cubit.state.pendingWithdrawal?.status,
        WithdrawalAttemptStatus.conflict,
      );

      expect(await cubit.requestPayout(_fnb, 250.5), isFalse);
      expect(await cubit.retryPendingWithdrawal(), isFalse);

      expect(sent, hasLength(1));
      expect(stored()?.status, WithdrawalAttemptStatus.conflict);
      await _close(cubit);
    });

    test('kept while the history cannot be reloaded, resolved on reopen',
        () async {
      historyLoads = false;
      final cubit = newCubit();
      answers.add(() => const ApiResult.failure(error: _conflict));

      await cubit.requestPayout(_fnb, 250.5);

      expect(
        cubit.state.pendingWithdrawal?.status,
        WithdrawalAttemptStatus.conflict,
      );
      expect(stored()?.status, WithdrawalAttemptStatus.conflict);
      // Still blocks a different withdrawal.
      expect(await cubit.requestPayout(_fnb, 100), isFalse);
      await _close(cubit);

      historyLoads = true;
      final reopened = newCubit(await restartPrefs(prefs));
      await reopened.restorePendingWithdrawal();

      expect(reopened.state.pendingWithdrawal, isNull);
      expect(sent, hasLength(1));
      await _close(reopened);
    });
  });

  group('corrupt or unavailable storage', () {
    test('a corrupt saved attempt blocks withdrawals and is never cleared',
        () async {
      prefs = await stylistPrefs(values: {attemptStorageKey(): '{broken'});
      final cubit = newCubit();

      await cubit.restorePendingWithdrawal();
      expect(cubit.state.pendingWithdrawalUnreadable, isTrue);

      expect(await cubit.requestPayout(_fnb, 100), isFalse);
      expect(await cubit.retryPendingWithdrawal(), isFalse);
      expect(sent, isEmpty);
      expect(issuedKeys, isEmpty, reason: 'no replacement key');
      expect(
        (cubit.state.requestPayoutState.error! as WithdrawalBlockedException)
            .reason,
        WithdrawalBlockReason.unreadableAttempt,
      );
      // Not overwritten, not removed — still blocked after a restart.
      expect(prefs.getString(attemptStorageKey()), '{broken');
      await _close(cubit);

      final restarted = await restartPrefs(prefs);
      final reopened = newCubit(restarted);
      await reopened.restorePendingWithdrawal();
      expect(reopened.state.pendingWithdrawalUnreadable, isTrue);
      expect(await reopened.requestPayout(_fnb, 100), isFalse);
      expect(sent, isEmpty);
      await _close(reopened);
    });

    test('unreadable storage blocks withdrawals; nothing is sent', () async {
      final cubit = EarningsCubit(
        repo,
        WithdrawalAttemptStore(_BrokenPrefs()),
        newIdempotencyKey: () => 'key-x-0000',
      );

      await cubit.restorePendingWithdrawal();
      expect(cubit.state.pendingWithdrawalUnreadable, isTrue);
      expect(await cubit.requestPayout(_fnb, 100), isFalse);

      expect(sent, isEmpty);
      await _close(cubit);
    });

    test('storage that cannot be written: the request is not sent unsaved',
        () async {
      final cubit = EarningsCubit(
        repo,
        WithdrawalAttemptStore(_ReadOnlyPrefs(prefs)),
        newIdempotencyKey: () => 'key-x-0000',
      );

      expect(await cubit.requestPayout(_fnb, 100), isFalse);

      expect(sent, isEmpty);
      expect(
        (cubit.state.requestPayoutState.error! as WithdrawalBlockedException)
            .reason,
        WithdrawalBlockReason.storageUnavailable,
      );
      expect(cubit.state.pendingWithdrawal, isNull);
      await _close(cubit);
    });
  });
}
