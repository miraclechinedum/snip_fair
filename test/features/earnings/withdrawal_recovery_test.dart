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
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_lookup.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/preferences/withdrawal_attempt_store.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';

import 'earnings_fixtures.dart';
import 'withdrawal_test_support.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

final _fnb = PaymentMethod(id: 7, bankName: 'FNB', accountNumber: '62001234');

const _key = '3b241101-e2bb-4255-8caf-4136c566a962';

const _uncertain = WithdrawalAttempt(
  idempotencyKey: _key,
  paymentMethodId: '7',
  amount: 150,
  status: WithdrawalAttemptStatus.unknown,
);

WithdrawalRecord _record({
  String status = 'processing',
  bool refunded = false,
  WithdrawalRefund? refund,
}) =>
    WithdrawalRecord(
      id: 42,
      amountMinor: 15000,
      rawStatus: status,
      refunded: refunded,
      refund: refund,
      reference: 'WDR-42',
      currency: 'ZAR',
      transactionId: 881,
    );

RemoteException _server(int status, String message, {String? code}) =>
    RemoteException.serverError(
      status,
      ServerError(message: message),
      code: code,
    );

ApiResult<WithdrawalLookup> _found(WithdrawalRecord record) =>
    ApiResult.success(data: WithdrawalLookupFound(record));

const ApiResult<WithdrawalLookup> _notFound =
    ApiResult.success(data: WithdrawalLookupNotFound());

ApiResult<WithdrawalLookup> _lookupFailed(RemoteException error) =>
    ApiResult.failure(error: error);

Future<void> _close(EarningsCubit cubit) async {
  await Future<void>.delayed(Duration.zero);
  await cubit.close();
}

void main() {
  late _MockProfileRepository repo;
  late SharedPreferences prefs;
  late List<String> issuedKeys;
  late List<(String, double, String)> sent;
  late List<String> lookedUp;
  late List<FutureOr<ApiResult<WithdrawalSubmission>> Function()> answers;
  late List<FutureOr<ApiResult<WithdrawalLookup>> Function()> lookups;

  EarningsCubit newCubit([SharedPreferences? using]) => EarningsCubit(
        repo,
        WithdrawalAttemptStore(using ?? prefs),
        newIdempotencyKey: () {
          final key = 'new-key-${issuedKeys.length + 1}';
          issuedKeys.add(key);
          return key;
        },
      );

  WithdrawalAttempt? stored([SharedPreferences? using]) =>
      switch (WithdrawalAttemptStore(using ?? prefs).load()) {
        FoundWithdrawalAttempt(:final attempt) => attempt,
        _ => null,
      };

  /// An unresolved attempt saved by an earlier run, then an app restart.
  Future<EarningsCubit> restartWithSaved(WithdrawalAttempt attempt) async {
    await WithdrawalAttemptStore(prefs).save(attempt);
    prefs = await restartPrefs(prefs);
    return newCubit();
  }

  setUp(() async {
    prefs = await stylistPrefs();
    repo = _MockProfileRepository();
    issuedKeys = [];
    sent = [];
    lookedUp = [];
    answers = [];
    lookups = [];
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
      (_) async =>
          ApiResult.success(data: CustomerWalletTransactionList(data: [])),
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
    when(() => repo.lookupWithdrawal(any())).thenAnswer((invocation) async {
      lookedUp.add(invocation.positionalArguments[0] as String);
      return lookups.removeAt(0)();
    });
  });

  test('restore after an app restart looks up the stored key; found resolves',
      () async {
    final cubit = await restartWithSaved(_uncertain);
    lookups.add(() => _found(_record()));

    await cubit.restorePendingWithdrawal();

    expect(lookedUp, [_key]);
    expect(cubit.state.recoveredWithdrawal, _record());
    expect(cubit.state.pendingWithdrawal, isNull);
    expect(stored(), isNull);
    expect(sent, isEmpty, reason: 'a found withdrawal is never resent');
    expect(issuedKeys, isEmpty, reason: 'no key is generated to look up');
    // Balance and history are reloaded.
    await Future<void>.delayed(Duration.zero);
    verify(repo.getEarnings).called(1);
    // Resolved: a new withdrawal may now be started, with a new key.
    answers.add(
      () => const ApiResult.success(data: WithdrawalSubmission(amount: 20)),
    );
    expect(await cubit.requestPayout(_fnb, 20), isTrue);
    expect(sent.single, ('7', 20.0, 'new-key-1'));
    await _close(cubit);
  });

  test('a request in flight when the app was killed is looked up too',
      () async {
    final cubit = await restartWithSaved(
      _uncertain.withStatus(WithdrawalAttemptStatus.sending),
    );
    lookups.add(() => _found(_record(status: 'pending')));

    await cubit.restorePendingWithdrawal();

    expect(lookedUp, [_key]);
    expect(cubit.state.pendingWithdrawal, isNull);
    await _close(cubit);
  });

  group('every client-safe status resolves the attempt', () {
    for (final status in [
      'pending',
      'processing',
      'paid',
      'failed',
      'under_review',
      'reversed',
      'closed',
      'something_new',
    ]) {
      test(status, () async {
        final cubit = await restartWithSaved(_uncertain);
        lookups.add(() => _found(_record(status: status)));

        await cubit.restorePendingWithdrawal();

        expect(cubit.state.recoveredWithdrawal?.rawStatus, status);
        expect(stored(), isNull);
        expect(sent, isEmpty);
        await _close(cubit);
      });
    }
  });

  test('a refunded withdrawal carries its refund', () async {
    final cubit = await restartWithSaved(_uncertain);
    const refund = WithdrawalRefund(
      transactionId: 990,
      reference: 'WDR-42-REFUND',
      amount: 150,
    );
    lookups.add(
      () => _found(_record(status: 'failed', refunded: true, refund: refund)),
    );

    await cubit.restorePendingWithdrawal();

    expect(cubit.state.recoveredWithdrawal?.refunded, isTrue);
    expect(cubit.state.recoveredWithdrawal?.refund, refund);
    await _close(cubit);
  });

  group('404: nothing recorded yet', () {
    test('never permission for a fresh attempt; nothing is sent by itself',
        () async {
      final cubit = await restartWithSaved(_uncertain);
      lookups.add(() => _notFound);

      await cubit.restorePendingWithdrawal();

      expect(
        cubit.state.withdrawalRecovery,
        WithdrawalRecoveryStatus.notFound,
      );
      expect(cubit.state.pendingWithdrawal, _uncertain);
      expect(stored(), _uncertain);
      expect(sent, isEmpty);
      // A different withdrawal is still refused.
      expect(await cubit.requestPayout(_fnb, 20), isFalse);
      expect(
        (cubit.state.requestPayoutState.error! as WithdrawalBlockedException)
            .reason,
        WithdrawalBlockReason.unresolvedAttempt,
      );
      expect(sent, isEmpty);
      expect(issuedKeys, isEmpty);
      await _close(cubit);
    });

    test('then retry sends the original request once: same key and payload',
        () async {
      final cubit = await restartWithSaved(_uncertain);
      lookups.add(() => _notFound);
      answers.add(
        () => const ApiResult.success(data: WithdrawalSubmission(amount: 150)),
      );

      await cubit.restorePendingWithdrawal();
      expect(await cubit.retryPendingWithdrawal(), isTrue);

      expect(sent, [('7', 150.0, _key)]);
      expect(issuedKeys, isEmpty);
      expect(stored(), isNull);
      verify(
        () => repo.requestPayout(any(), any(), idempotencyKey: _key),
      ).called(1);
      await _close(cubit);
    });

    test('a resend that times out again stays unresolved, same key', () async {
      final cubit = await restartWithSaved(_uncertain);
      lookups
        ..add(() => _notFound)
        ..add(() => _found(_record()));
      answers.add(
        () => const ApiResult.failure(error: RemoteException.timeoutError()),
      );

      await cubit.restorePendingWithdrawal();
      await cubit.retryPendingWithdrawal();
      expect(stored()?.idempotencyKey, _key);
      expect(stored()?.outcomeUnknown, isTrue);

      // Checking again finds it: resolved without a second send.
      await cubit.checkPendingWithdrawal();
      expect(cubit.state.pendingWithdrawal, isNull);
      expect(sent, hasLength(1));
      expect(lookedUp, [_key, _key]);
      await _close(cubit);
    });
  });

  group('lookup cannot answer: the attempt stays, blocked', () {
    final cases = <String, (RemoteException, WithdrawalRecoveryStatus)>{
      '503 busy': (
        _server(
          503,
          'Ooops.. Your withdrawal is still being processed.',
          code: 'WITHDRAWAL_LOOKUP_BUSY',
        ),
        WithdrawalRecoveryStatus.busy,
      ),
      'network timeout': (
        const RemoteException.timeoutError(),
        WithdrawalRecoveryStatus.unavailable,
      ),
      'no connection': (
        const RemoteException.noInternetError(),
        WithdrawalRecoveryStatus.unavailable,
      ),
      '500': (
        RemoteException.httpError(500),
        WithdrawalRecoveryStatus.unavailable,
      ),
      '401 session expired': (
        _server(401, 'Unauthenticated.'),
        WithdrawalRecoveryStatus.unavailable,
      ),
      '403 forbidden': (
        _server(403, 'Forbidden.'),
        WithdrawalRecoveryStatus.forbidden,
      ),
      '422 invalid key': (
        _server(
          422,
          'Ooops.. The idempotency key must be 8-100 letters.',
          code: 'IDEMPOTENCY_KEY_INVALID',
        ),
        WithdrawalRecoveryStatus.unavailable,
      ),
    };

    cases.forEach((name, failure) {
      test(name, () async {
        final cubit = await restartWithSaved(_uncertain);
        lookups.add(() => _lookupFailed(failure.$1));

        await cubit.restorePendingWithdrawal();

        expect(cubit.state.withdrawalRecovery, failure.$2);
        expect(cubit.state.pendingWithdrawal, _uncertain);
        expect(stored(), _uncertain, reason: 'preserved on the device');
        expect(await cubit.requestPayout(_fnb, 20), isFalse);
        expect(sent, isEmpty, reason: 'nothing is sent automatically');
        expect(issuedKeys, isEmpty, reason: 'no replacement key');
        await _close(cubit);
      });
    });

    test('busy, then checking again finds it', () async {
      final cubit = await restartWithSaved(_uncertain);
      lookups
        ..add(
          () => _lookupFailed(
            _server(503, 'busy', code: 'WITHDRAWAL_LOOKUP_BUSY'),
          ),
        )
        ..add(() => _found(_record(status: 'paid')));

      await cubit.restorePendingWithdrawal();
      expect(cubit.state.withdrawalRecovery, WithdrawalRecoveryStatus.busy);
      await cubit.checkPendingWithdrawal();

      expect(
          cubit.state.recoveredWithdrawal?.status, WithdrawalRecordStatus.paid);
      expect(cubit.state.pendingWithdrawal, isNull);
      expect(lookedUp, [_key, _key]);
      expect(sent, isEmpty);
      await _close(cubit);
    });
  });

  test('a stored conflict is resolved by the lookup, never resent', () async {
    final cubit = await restartWithSaved(
      _uncertain.withStatus(WithdrawalAttemptStatus.conflict),
    );
    lookups.add(() => _found(_record()));

    await cubit.restorePendingWithdrawal();

    expect(cubit.state.recoveredWithdrawal, _record());
    expect(stored(), isNull);
    expect(sent, isEmpty);
    await _close(cubit);
  });

  test('a rejected attempt (never recorded) is not looked up', () async {
    final cubit = await restartWithSaved(
      _uncertain.withStatus(WithdrawalAttemptStatus.rejected),
    );

    await cubit.restorePendingWithdrawal();

    expect(lookedUp, isEmpty);
    expect(cubit.state.pendingWithdrawal?.status,
        WithdrawalAttemptStatus.rejected);
    await _close(cubit);
  });

  test('checks while one is running, or while sending, do not overlap',
      () async {
    final cubit = await restartWithSaved(_uncertain);
    final gate = Completer<ApiResult<WithdrawalLookup>>();
    lookups.add(() => gate.future);

    final restoring = cubit.restorePendingWithdrawal();
    await Future<void>.delayed(Duration.zero);
    await cubit.checkPendingWithdrawal();
    await cubit.checkPendingWithdrawal();
    expect(lookedUp, hasLength(1));

    gate.complete(_found(_record()));
    await restoring;
    expect(cubit.state.pendingWithdrawal, isNull);
    await _close(cubit);
  });
}
