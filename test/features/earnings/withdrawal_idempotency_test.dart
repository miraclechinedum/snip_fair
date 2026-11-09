import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_attempt.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_failure.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';
import 'package:snip_fair/core/utils/preferences/withdrawal_attempt_store.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';

import 'earnings_fixtures.dart';
import 'withdrawal_test_support.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

final _fnb = PaymentMethod(id: 7, bankName: 'FNB', accountNumber: '62001234');
final _absa = PaymentMethod(id: 8, bankName: 'ABSA', accountNumber: '40705678');

ApiResult<WithdrawalSubmission> _accepted(
  double amount, {
  bool replayed = false,
}) =>
    ApiResult.success(
      data: WithdrawalSubmission(amount: amount, replayed: replayed),
    );

ApiResult<WithdrawalSubmission> _failed(RemoteException error) =>
    ApiResult.failure(error: error);

RemoteException _server(int status, String message, {String? code}) =>
    RemoteException.serverError(
      status,
      ServerError(message: message),
      code: code,
    );

/// Lets the fire-and-forget balance/history refreshes finish first.
Future<void> _close(EarningsCubit cubit) async {
  await Future<void>.delayed(Duration.zero);
  await cubit.close();
}

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late _MockProfileRepository repo;

  /// Keys handed out by the injected generator, in order.
  late List<String> issuedKeys;

  /// Keys the repository was called with, in order.
  late List<String> sentKeys;

  /// Answers for successive withdrawal requests.
  late List<FutureOr<ApiResult<WithdrawalSubmission>> Function()> answers;

  late WithdrawalAttemptStore store;

  EarningsCubit newCubit({bool realKeys = false}) {
    var n = 0;
    return EarningsCubit(
      repo,
      store,
      newIdempotencyKey: realKeys
          ? null
          : () {
              final key = 'key-${++n}-0000';
              issuedKeys.add(key);
              return key;
            },
    );
  }

  setUp(() async {
    store = await stylistAttemptStore();
    repo = _MockProfileRepository();
    issuedKeys = [];
    sentKeys = [];
    answers = [];
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
      (_) async => ApiResult.success(data: CustomerWalletTransactionList()),
    );
    when(
      () => repo.requestPayout(
        any(),
        any(),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((invocation) async {
      sentKeys.add(invocation.namedArguments[#idempotencyKey] as String);
      return answers.removeAt(0)();
    });
  });

  test('1. a new withdrawal gets a fresh UUID v4 key', () async {
    final cubit = newCubit(realKeys: true);
    answers.add(() => _accepted(250.5));

    expect(await cubit.requestPayout(_fnb, 250.5), isTrue);

    expect(sentKeys.single, matches(_uuidV4));
    verify(
      () => repo.requestPayout('7', 250.5, idempotencyKey: sentKeys.single),
    ).called(1);
    await _close(cubit);
  });

  test('3. a timeout keeps the key, and the retry reuses it', () async {
    final cubit = newCubit();
    answers
      ..add(() => _failed(const RemoteException.timeoutError()))
      ..add(() => _accepted(250.5));

    expect(await cubit.requestPayout(_fnb, 250.5), isFalse);
    expect(
      cubit.state.pendingWithdrawal,
      const WithdrawalAttempt(
        idempotencyKey: 'key-1-0000',
        paymentMethodId: '7',
        amount: 250.5,
        status: WithdrawalAttemptStatus.unknown,
      ),
    );

    expect(await cubit.requestPayout(_fnb, 250.5), isTrue);

    expect(sentKeys, ['key-1-0000', 'key-1-0000']);
    expect(issuedKeys, hasLength(1), reason: 'no new key for a retry');
    expect(cubit.state.pendingWithdrawal, isNull);
    await _close(cubit);
  });

  test('3b. a lost connection keeps the key too', () async {
    final cubit = newCubit();
    answers
      ..add(() => _failed(const RemoteException.noInternetError()))
      ..add(() => _accepted(100));

    await cubit.requestPayout(_fnb, 100);
    await cubit.requestPayout(_fnb, 100);

    expect(sentKeys, ['key-1-0000', 'key-1-0000']);
    await _close(cubit);
  });

  for (final status in [500, 502, 504]) {
    test('4. a retryable $status keeps the key for the retry', () async {
      final cubit = newCubit();
      answers
        ..add(() => _failed(RemoteException.httpError(status)))
        ..add(() => _accepted(250.5));

      expect(await cubit.requestPayout(_fnb, 250.5), isFalse);
      expect(cubit.state.pendingWithdrawal?.idempotencyKey, 'key-1-0000');
      expect(await cubit.requestPayout(_fnb, 250.5), isTrue);

      expect(sentKeys, ['key-1-0000', 'key-1-0000']);
      await _close(cubit);
    });
  }

  test('a retry matches on cents: 250.5 and 250.50 are the same request',
      () async {
    final cubit = newCubit();
    answers
      ..add(() => _failed(const RemoteException.timeoutError()))
      ..add(() => _accepted(250.5));

    await cubit.requestPayout(_fnb, 250.5);
    await cubit.requestPayout(_fnb, double.parse('250.50'));

    expect(sentKeys, ['key-1-0000', 'key-1-0000']);
    await _close(cubit);
  });

  group('5. a genuinely new withdrawal gets a new key', () {
    test('after a successful one, even with the same details', () async {
      final cubit = newCubit();
      answers
        ..add(() => _accepted(250.5))
        ..add(() => _accepted(250.5));

      await cubit.requestPayout(_fnb, 250.5);
      await cubit.requestPayout(_fnb, 250.5);

      expect(sentKeys, ['key-1-0000', 'key-2-0000']);
      await _close(cubit);
    });

    for (final (what, method, amount) in [
      ('amount', _fnb, 300.0),
      ('bank account', _absa, 250.5),
    ]) {
      test('but not while an earlier one is unresolved: changed $what',
          () async {
        final cubit = newCubit();
        answers.add(() => _failed(const RemoteException.timeoutError()));

        await cubit.requestPayout(_fnb, 250.5);
        expect(await cubit.requestPayout(method, amount), isFalse);

        expect(sentKeys, ['key-1-0000'], reason: 'nothing new was sent');
        expect(issuedKeys, hasLength(1), reason: 'no replacement key');
        final error = cubit.state.requestPayoutState.error;
        expect(error, isA<WithdrawalBlockedException>());
        expect(
          (error! as WithdrawalBlockedException).reason,
          WithdrawalBlockReason.unresolvedAttempt,
        );
        // The earlier attempt is untouched.
        expect(cubit.state.pendingWithdrawal?.idempotencyKey, 'key-1-0000');
        expect(cubit.state.pendingWithdrawal?.amount, 250.5);
        await _close(cubit);
      });
    }
  });

  group('definite refusals keep the key for an identical resend', () {
    final refusals = {
      '6. 503 withdrawals disabled': _server(
        503,
        'Withdrawals are temporarily unavailable.',
        code: 'PAYOUT_REQUESTS_DISABLED',
      ),
      '8. 400 business refusal': _server(400, 'Ooops.. Insufficient balance.'),
      '10. 422 validation error':
          _server(422, 'The amount field must be greater than 10.'),
      '403 email not verified':
          _server(403, 'Please verify your email address to continue'),
      '429 throttled': RemoteException.httpError(429),
    };

    refusals.forEach((name, error) {
      test('$name: no automatic retry, same key when resent', () async {
        final cubit = newCubit();
        answers
          ..add(() => _failed(error))
          ..add(() => _accepted(250.5));

        expect(await cubit.requestPayout(_fnb, 250.5), isFalse);
        await Future<void>.delayed(Duration.zero);

        expect(sentKeys, ['key-1-0000'], reason: 'no automatic retry');
        expect(cubit.state.requestPayoutState.hasError, isTrue);
        // Kept, but not presented as an unknown outcome.
        expect(cubit.state.pendingWithdrawal?.idempotencyKey, 'key-1-0000');
        expect(
          cubit.state.pendingWithdrawal?.status,
          WithdrawalAttemptStatus.rejected,
        );
        verifyNever(repo.getEarnings);

        // The stylist resubmits the same details: same key (Laravel never
        // stored it), and a 204 finally clears it.
        expect(await cubit.requestPayout(_fnb, 250.5), isTrue);
        expect(sentKeys, ['key-1-0000', 'key-1-0000']);
        expect(cubit.state.pendingWithdrawal, isNull);
        await _close(cubit);
      });
    });

    test('a refusal followed by different details is a new attempt', () async {
      final cubit = newCubit();
      answers
        ..add(() => _failed(_server(400, 'Ooops.. Insufficient balance.')))
        ..add(() => _accepted(100));

      await cubit.requestPayout(_fnb, 250.5);
      await cubit.requestPayout(_fnb, 100);

      expect(sentKeys, ['key-1-0000', 'key-2-0000']);
      await _close(cubit);
    });
  });

  test("9. 409 is not retried with a new key behind the stylist's back",
      () async {
    final cubit = newCubit();
    answers
      ..add(
        () => _failed(
          _server(
            409,
            'Ooops.. This idempotency key was already used for a different '
            'withdrawal.',
            code: 'IDEMPOTENCY_KEY_REUSED',
          ),
        ),
      )
      ..add(() => _accepted(250.5));

    expect(await cubit.requestPayout(_fnb, 250.5), isFalse);
    await Future<void>.delayed(Duration.zero);

    expect(sentKeys, ['key-1-0000'], reason: 'exactly one request');
    expect(issuedKeys, hasLength(1), reason: 'no silent second key');
    expect(cubit.state.requestPayoutState.hasError, isTrue);
    expect(cubit.state.pendingWithdrawal, isNull);
    // History and balance are reloaded so the stylist can check them.
    verify(repo.getEarnings).called(1);
    verify(
      () => repo.getWalletTransactions(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(1);

    // Only the stylist's own next submission starts a new attempt.
    await cubit.requestPayout(_fnb, 250.5);
    expect(sentKeys, ['key-1-0000', 'key-2-0000']);
    await _close(cubit);
  });

  test('401 keeps the attempt for an identical resend after signing in',
      () async {
    final cubit = newCubit();
    answers.add(() => _failed(_server(401, 'Unauthenticated.')));

    await cubit.requestPayout(_fnb, 250.5);

    expect(
      cubit.state.pendingWithdrawal?.status,
      WithdrawalAttemptStatus.rejected,
    );
    expect(store.load(), isA<FoundWithdrawalAttempt>());
    await _close(cubit);
  });

  test('6/14. 204: attempt cleared, balance and history refreshed', () async {
    final cubit = newCubit();
    answers.add(() => _accepted(250.5));

    expect(await cubit.requestPayout(_fnb, 250.5), isTrue);

    expect(
      cubit.state.requestPayoutState.data,
      const WithdrawalSubmission(amount: 250.5),
    );
    expect(cubit.state.pendingWithdrawal, isNull);
    await Future<void>.delayed(Duration.zero);
    // Balance (from /stylist/earnings) and the first history page.
    verify(repo.getEarnings).called(1);
    verify(
      () => repo.getWalletTransactions(
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
    expect(cubit.state.transactionsState.hasSuccess, isTrue);
    await _close(cubit);
  });

  test('the idempotency key never appears in logged state', () async {
    final cubit = newCubit();
    answers.add(() => _failed(const RemoteException.timeoutError()));

    await cubit.requestPayout(_fnb, 250.5);

    expect(cubit.state.pendingWithdrawal.toString(), isNot(contains('key-1')));
    expect(cubit.state.toString(), isNot(contains('key-1')));
    await _close(cubit);
  });

  test('7. a replayed 204 is still a success, reported as a replay', () async {
    final cubit = newCubit();
    answers.add(() => _accepted(250.5, replayed: true));

    expect(await cubit.requestPayout(_fnb, 250.5), isTrue);

    expect(cubit.state.requestPayoutState.data?.replayed, isTrue);
    await _close(cubit);
  });

  test('12. repeated calls while one is in flight send one request', () async {
    final cubit = newCubit();
    final gate = Completer<ApiResult<WithdrawalSubmission>>();
    answers.add(() => gate.future);

    final first = cubit.requestPayout(_fnb, 250.5);
    final second = cubit.requestPayout(_fnb, 250.5);
    final third = cubit.requestPayout(_fnb, 999);

    expect(await second, isFalse);
    expect(await third, isFalse);
    expect(cubit.state.requestPayoutState.isLoading, isTrue);

    gate.complete(_accepted(250.5));
    expect(await first, isTrue);

    expect(sentKeys, ['key-1-0000']);
    expect(issuedKeys, hasLength(1));
    await _close(cubit);
  });
}
