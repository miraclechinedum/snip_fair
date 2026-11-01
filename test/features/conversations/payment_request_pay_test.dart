import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/customer_wallet.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request_pay_result.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/services/peach_deposit_reconciler.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/features/conversations/data/payment_request_attempt_store.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// In-memory [PaymentRequestAttemptStore] that survives "restarts" (new
/// cubits) within a test.
class _MemoryAttemptStore implements PaymentRequestAttemptStore {
  final Map<String, List<Map<String, dynamic>>> saved = {};

  @override
  List<PaymentRequestAttempt> load(String ownerId) => (saved[ownerId] ?? [])
      .map(PaymentRequestAttempt.tryParse)
      .whereType<PaymentRequestAttempt>()
      .toList();

  @override
  Future<void> save(String ownerId, List<PaymentRequestAttempt> attempts) async {
    saved[ownerId] = attempts.map((a) => a.toJson()).toList();
  }

  @override
  Future<void> clear(String ownerId) async => saved[ownerId] = [];
}

const _kId = 5;
const _kDeposit = '1';
const _kRedirect = 'https://checkout.example.test/chk_1';

const _checkout = CheckoutPaymentData(
  isInitialized: true,
  depositId: _kDeposit,
  checkoutId: 'chk_1',
  redirectUrl: _kRedirect,
);

PaymentReconciliation _status(String status, {bool settled = false}) =>
    PaymentReconciliation(
      depositId: _kDeposit,
      purpose: 'wallet_topup',
      status: status,
      settled: settled,
      amount: 110,
    );

ApiResult<PaymentRequestPayResult> _paid() => ApiResult.success(
      data: PaymentRequestPayResult(
        code: 'paid',
        message: 'Payment successful.',
        paymentRequest:
            PaymentRequest(id: _kId, statusRaw: 'paid', totalAmount: 150),
        newWalletBalance: 0,
      ),
    );

ApiResult<PaymentRequestPayResult> _payError(
  int status,
  String code,
  String message, [
  Map<String, dynamic> extra = const {},
]) =>
    ApiResult.failure(
      error: RemoteException.serverError(
        status,
        ServerError(message: message),
        code: code,
        responseBody: {'message': message, 'code': code, ...extra},
      ),
    );

ApiResult<PaymentRequestPayResult> _insufficient(num shortfall) => _payError(
      400,
      'insufficient_wallet_balance',
      'Insufficient wallet balance.',
      {
        'wallet_balance': 150 - shortfall,
        'required_amount': 150,
        'shortfall': shortfall,
      },
    );

const _unavailable = ApiResult<PaymentReconciliation>.failure(
  error: RemoteException.serverError(
    503,
    ServerError(message: 'Payment could not yet be verified. Please try again.'),
  ),
);

void main() {
  late _MockProfileRepository repo;
  late _MemoryAttemptStore store;
  late ConversationsCubit cubit;
  late DateTime clock;
  late List<Duration> sleeps;

  PaymentRequestPaymentProgress progress() => cubit.paymentProgressFor(_kId);

  /// Each call to the status endpoint takes the next answer; the last one
  /// repeats.
  void stubStatuses(List<ApiResult<PaymentReconciliation>> answers) {
    final queue = [...answers];
    when(() => repo.reconcilePeachPayment(_kDeposit)).thenAnswer(
      (_) async => queue.length > 1 ? queue.removeAt(0) : queue.first,
    );
  }

  void stubPay(List<ApiResult<PaymentRequestPayResult>> answers) {
    final queue = [...answers];
    when(() => repo.payPaymentRequest(_kId)).thenAnswer(
      (_) async => queue.length > 1 ? queue.removeAt(0) : queue.first,
    );
  }

  void stubTopUpOk() {
    when(() => repo.initializeWalletTopUp(amount: any(named: 'amount')))
        .thenAnswer((_) async => const ApiResult.success(data: _checkout));
  }

  void stubRequest(String status) {
    when(() => repo.getPaymentRequest(_kId)).thenAnswer(
      (_) async => ApiResult.success(
        data: PaymentRequest(id: _kId, statusRaw: status, totalAmount: 150),
      ),
    );
  }

  int statusCalls() =>
      verify(() => repo.reconcilePeachPayment(_kDeposit)).callCount;

  int topUpCalls() => verify(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      ).callCount;

  /// Opens checkout and closes it with the X, as the card does, then lets
  /// background polling run to its end (sleeps are instant, the clock fake).
  Future<CheckoutPaymentData?> payByCardThenX({num amount = 150}) async {
    final checkout = await cubit.startCardTopUp(_kId, amount: amount);
    await cubit.onCardCheckoutClosed(_kId);
    await cubit.debugPaymentPollingIdle();
    return checkout;
  }

  ConversationsCubit newCubit() => ConversationsCubit(repo, attemptStore: store);

  setUp(() {
    clock = DateTime(2026, 11, 1, 12);
    sleeps = [];
    ConversationsCubit.paymentPollSleep = (duration) async {
      sleeps.add(duration);
      clock = clock.add(duration);
    };
    ConversationsCubit.paymentClock = () => clock;
    repo = _MockProfileRepository();
    store = _MemoryAttemptStore();
    cubit = newCubit();
    stubRequest('accepted');
  });

  tearDown(() async {
    await cubit.debugPaymentPollingIdle();
    await cubit.close();
  });

  group('checkout closed with the X', () {
    test('successful status continues to /pay', () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('successful'))]);
      stubPay([_paid()]);

      await payByCardThenX();

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(statusCalls(), 1);
      verify(() => repo.payPaymentRequest(_kId)).called(1);
    });

    test('pending keeps the deposit and offers Check Payment Status',
        () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('pending'))]);

      await payByCardThenX();

      expect(progress().phase, PaymentRequestPaymentPhase.topUpPending);
      expect(progress().phase.isBusy, isFalse);
      expect(progress().depositId, _kDeposit);
      verifyNever(() => repo.payPaymentRequest(any()));
    });

    test('unknown keeps the deposit and is never success', () async {
      stubTopUpOk();
      stubStatuses([_unavailable]);

      await payByCardThenX();

      expect(progress().phase, PaymentRequestPaymentPhase.topUpUnknown);
      expect(progress().phase.isBusy, isFalse);
      expect(progress().depositId, _kDeposit);
      verifyNever(() => repo.payPaymentRequest(any()));
    });

    test('failed releases the attempt for a new checkout', () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('failed'))]);

      await payByCardThenX();

      expect(progress().phase, PaymentRequestPaymentPhase.failed);
      expect(progress().depositId, isNull);
      expect(statusCalls(), 1);
      expect(await cubit.startCardTopUp(_kId, amount: 150), isNotNull);
    });

    test('cancelled releases the attempt for a new checkout', () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('cancelled'))]);

      await payByCardThenX();

      expect(progress().phase, PaymentRequestPaymentPhase.cancelled);
      expect(await cubit.startCardTopUp(_kId, amount: 150), isNotNull);
    });

    test('a status check that hangs does not keep the card busy', () async {
      ConversationsCubit.paymentStatusCheckTimeout =
          const Duration(milliseconds: 20);
      addTearDown(
        () => ConversationsCubit.paymentStatusCheckTimeout =
            const Duration(seconds: 15),
      );
      final hung = Completer<ApiResult<PaymentReconciliation>>();
      stubTopUpOk();
      when(() => repo.reconcilePeachPayment(_kDeposit))
          .thenAnswer((_) => hung.future);

      await cubit.startCardTopUp(_kId, amount: 150);
      await cubit.onCardCheckoutClosed(_kId);

      expect(progress().phase, PaymentRequestPaymentPhase.topUpUnknown);
      expect(progress().phase.isBusy, isFalse);
      expect(progress().depositId, _kDeposit);
      hung.complete(_unavailable);
    });

    test('repeated close callbacks run one verification', () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('successful'))]);
      stubPay([_paid()]);
      await cubit.startCardTopUp(_kId, amount: 150);

      await Future.wait([
        cubit.onCardCheckoutClosed(_kId),
        cubit.onCardCheckoutClosed(_kId),
        cubit.onCardCheckoutClosed(_kId),
      ]);
      await cubit.debugPaymentPollingIdle();

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(statusCalls(), 1);
      verify(() => repo.payPaymentRequest(_kId)).called(1);
    });

    test('an unresolved attempt refuses a new checkout', () async {
      stubTopUpOk();
      stubStatuses([_unavailable]);
      await payByCardThenX();

      expect(await cubit.startCardTopUp(_kId, amount: 150), isNull);
      expect(progress().message, contains('Check Payment Status'));
      expect(topUpCalls(), 1);
    });

    test('404 from the status endpoint ends the attempt', () async {
      stubTopUpOk();
      stubStatuses([
        const ApiResult.failure(
          error: RemoteException.serverError(
            404,
            ServerError(message: 'Payment not found'),
          ),
        ),
      ]);

      await payByCardThenX();

      expect(progress().phase, PaymentRequestPaymentPhase.failed);
      expect(progress().depositId, isNull);
    });
  });

  group('background polling', () {
    test('follows the back-off and stops at the maximum duration', () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('pending'))]);

      await payByCardThenX();

      // Quick check after the X, then the background schedule.
      expect(sleeps, ConversationsCubit.paymentStatusPolling.delays);
      expect(statusCalls(), 1 + sleeps.length);
      final total = sleeps.fold(Duration.zero, (sum, d) => sum + d);
      expect(
        total <= ConversationsCubit.paymentStatusPolling.maxDuration,
        isTrue,
      );
      // The deposit is preserved after the window ends.
      expect(progress().phase, PaymentRequestPaymentPhase.topUpPending);
      expect(progress().depositId, _kDeposit);
    });

    test('a shorter maximum duration cuts the schedule', () async {
      final original = ConversationsCubit.paymentStatusPolling;
      ConversationsCubit.paymentStatusPolling = const PeachPollSchedule(
        delays: [
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
          Duration(seconds: 15),
        ],
        maxDuration: Duration(seconds: 10),
      );
      addTearDown(() => ConversationsCubit.paymentStatusPolling = original);
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('pending'))]);

      await payByCardThenX();

      expect(sleeps, const [Duration(seconds: 2), Duration(seconds: 4)]);
      expect(statusCalls(), 3);
    });

    test('a late success during polling continues to /pay', () async {
      stubTopUpOk();
      stubStatuses([
        _unavailable,
        ApiResult.success(data: _status('pending')),
        ApiResult.success(data: _status('successful')),
      ]);
      stubPay([_paid()]);

      await payByCardThenX();

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(statusCalls(), 3);
      verify(() => repo.payPaymentRequest(_kId)).called(1);
    });

    test('status calls never overlap', () async {
      var inFlight = 0;
      var maxInFlight = 0;
      final gate = Completer<void>();
      stubTopUpOk();
      when(() => repo.reconcilePeachPayment(_kDeposit)).thenAnswer((_) async {
        inFlight++;
        maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
        await gate.future;
        inFlight--;
        return ApiResult.success(data: _status('pending'));
      });

      await cubit.startCardTopUp(_kId, amount: 150);
      final closed = cubit.onCardCheckoutClosed(_kId);
      // A manual check while the first request is still running.
      final manual = cubit.checkCardPaymentStatus(_kId);
      await Future<void>.delayed(Duration.zero);
      expect(maxInFlight, 1);
      gate.complete();
      await Future.wait([closed, manual]);
      await cubit.debugPaymentPollingIdle();
      expect(maxInFlight, 1);
    });

    test('manual Check Payment Status works after polling ends', () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('pending'))]);
      await payByCardThenX();
      final before = statusCalls();

      stubStatuses([ApiResult.success(data: _status('successful'))]);
      stubPay([_paid()]);
      await cubit.checkCardPaymentStatus(_kId);

      expect(before, greaterThan(0));
      expect(progress().phase, PaymentRequestPaymentPhase.successful);
    });

    test('pausing stops polling; resume re-checks and resumes', () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('pending'))]);
      await cubit.startCardTopUp(_kId, amount: 150);
      cubit.pausePaymentStatusPolling();
      await cubit.onCardCheckoutClosed(_kId);
      await cubit.debugPaymentPollingIdle();
      // Paused: only the quick check ran.
      expect(statusCalls(), 1);
      expect(sleeps, isEmpty);

      stubStatuses([ApiResult.success(data: _status('successful'))]);
      stubPay([_paid()]);
      await cubit.recheckUnresolvedPayments();
      await cubit.debugPaymentPollingIdle();

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
    });

    test('resume re-checks only unresolved attempts', () async {
      stubPay([_paid()]);
      await cubit.payFromWallet(_kId);
      clearInteractions(repo);

      await cubit.recheckUnresolvedPayments();

      verifyNever(() => repo.reconcilePeachPayment(any()));
    });
  });

  group('top-up amount', () {
    test('Card tops up the amount it is given (the full request)', () async {
      stubTopUpOk();
      await cubit.startCardTopUp(_kId, amount: 150);
      verify(() => repo.initializeWalletTopUp(amount: 150)).called(1);
    });

    test('a zero or negative amount never starts a top-up', () async {
      expect(await cubit.startCardTopUp(_kId, amount: 0), isNull);
      expect(await cubit.startCardTopUp(_kId, amount: -5), isNull);
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
    });

    test('a short wallet records the backend shortfall, charges nothing',
        () async {
      stubPay([_insufficient(110)]);

      await cubit.payFromWallet(_kId);

      expect(progress().phase, PaymentRequestPaymentPhase.awaitingWalletFunds);
      expect(progress().shortfall, 110);
      expect(progress().walletBalance, 40);
      expect(progress().requiredAmount, 150);
      expect(progress().message, contains('110.00'));
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
    });

    test('adding funds tops up exactly the backend shortfall', () async {
      stubPay([_insufficient(110)]);
      await cubit.payFromWallet(_kId);
      stubTopUpOk();

      final checkout =
          await cubit.startCardTopUp(_kId, amount: progress().shortfall!);

      expect(checkout, isNotNull);
      verify(() => repo.initializeWalletTopUp(amount: 110)).called(1);
    });
  });

  group('insufficient balance after a card top-up', () {
    Future<void> verifiedTopUpThen(
      List<ApiResult<PaymentRequestPayResult>> payAnswers,
    ) async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('successful'))]);
      stubPay(payAnswers);
      await payByCardThenX();
    }

    test('shows the actual shortfall and that the request is unpaid',
        () async {
      await verifiedTopUpThen([_insufficient(40)]);

      expect(progress().phase, PaymentRequestPaymentPhase.awaitingWalletFunds);
      expect(progress().shortfall, 40);
      expect(progress().message, contains('money is in your wallet'));
      expect(progress().message, contains('not paid yet'));
      expect(progress().message, contains('40.00'));
      expect(cubit.getCachedPaymentRequest(_kId)?.isPaid ?? false, isFalse);
    });

    test('Retry Payment calls /pay only — no new top-up', () async {
      await verifiedTopUpThen([_insufficient(40), _paid()]);
      final topUps = topUpCalls();

      await cubit.payFromWallet(_kId);

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(topUps, 1);
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
      verify(() => repo.payPaymentRequest(_kId)).called(2);
    });

    test('network failure keeps the money-in-wallet state for a retry',
        () async {
      await verifiedTopUpThen([
        const ApiResult.failure(error: RemoteException.timeoutError()),
        _paid(),
      ]);

      expect(
        progress().phase,
        PaymentRequestPaymentPhase.topUpSucceededPaymentPending,
      );
      expect(progress().depositId, _kDeposit);
      expect(await cubit.startCardTopUp(_kId, amount: 150), isNull);

      await cubit.payFromWallet(_kId);
      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(topUpCalls(), 1);
    });

    test('payment_failed (rolled back) is retryable from the wallet', () async {
      await verifiedTopUpThen([
        _payError(500, 'payment_failed',
            'Payment failed. You have not been charged. Please try again.'),
      ]);

      expect(
        progress().phase,
        PaymentRequestPaymentPhase.topUpSucceededPaymentPending,
      );
      expect(progress().message, contains('You have not been charged'));
    });

    test('already_paid confirmed by the request is success', () async {
      stubRequest('paid');
      await verifiedTopUpThen([
        _payError(400, 'already_paid',
            'This payment request has already been paid.'),
      ]);

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
    });
  });

  group('wallet /pay', () {
    test('paid only when the response code is "paid"', () async {
      stubPay([_paid()]);
      final seqBefore = cubit.state.paymentRequestUpdateSeq;

      await cubit.payFromWallet(_kId);

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(cubit.getCachedPaymentRequest(_kId)!.isPaid, isTrue);
      expect(cubit.state.paymentRequestUpdateSeq, greaterThan(seqBefore));
    });

    test('a 200 without code "paid" is not a payment', () async {
      stubPay([
        ApiResult.success(
          data: PaymentRequestPayResult(
            paymentRequest: PaymentRequest(id: _kId, statusRaw: 'paid'),
          ),
        ),
      ]);

      await cubit.payFromWallet(_kId);

      expect(progress().phase, PaymentRequestPaymentPhase.failed);
      expect(cubit.getCachedPaymentRequest(_kId)?.isPaid ?? false, isFalse);
    });

    test('already_paid the request does not confirm is not success',
        () async {
      stubPay([
        _payError(400, 'already_paid',
            'This payment request has already been paid.'),
      ]);
      stubRequest('accepted');

      await cubit.payFromWallet(_kId);

      expect(progress().phase, PaymentRequestPaymentPhase.failed);
    });

    for (final (status, code, message) in [
      (400, 'payment_request_not_payable', 'This payment request cannot be paid.'),
      (400, 'payment_request_expired', 'This payment request cannot be paid.'),
      (403, 'not_payer', 'Only the payer can pay this payment request.'),
      (409, 'card_payment_in_progress', 'A card payment for this request is still in progress.'),
      (422, 'payment_method_unavailable', 'Card payment is not available yet. Please pay from your wallet.'),
      (500, 'payment_failed', 'Payment failed. You have not been charged. Please try again.'),
    ]) {
      test('$code shows the backend message', () async {
        stubPay([_payError(status, code, message)]);

        await cubit.payFromWallet(_kId);

        expect(progress().phase, PaymentRequestPaymentPhase.failed);
        expect(progress().message, message);
      });
    }

    test('a busy phase refuses a second /pay', () async {
      final pending = Completer<ApiResult<PaymentRequestPayResult>>();
      when(() => repo.payPaymentRequest(_kId))
          .thenAnswer((_) => pending.future);

      final first = cubit.payFromWallet(_kId);
      expect(cubit.beginPaymentRequestPayment(_kId), isFalse);
      await cubit.payFromWallet(_kId);
      expect(await cubit.startCardTopUp(_kId, amount: 150), isNull);

      pending.complete(_paid());
      await first;
      verify(() => repo.payPaymentRequest(_kId)).called(1);
    });
  });

  group('persistence', () {
    const owner = '310';

    test('an unresolved attempt survives a restart and is re-checked',
        () async {
      await cubit.restorePaymentAttempts(ownerId: owner);
      stubTopUpOk();
      stubStatuses([_unavailable]);
      await payByCardThenX();
      expect(store.saved[owner], hasLength(1));
      expect(store.saved[owner]!.single['deposit_id'], _kDeposit);
      // Nothing sensitive: only ids, stage and time.
      expect(
        store.saved[owner]!.single.keys,
        unorderedEquals(['request_id', 'deposit_id', 'stage', 'updated_at']),
      );
      await cubit.close();

      // Restart.
      clearInteractions(repo);
      cubit = newCubit();
      stubStatuses([ApiResult.success(data: _status('successful'))]);
      stubPay([_paid()]);
      await cubit.restorePaymentAttempts(ownerId: owner);
      await cubit.debugPaymentPollingIdle();

      expect(statusCalls(), 1);
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
      verify(() => repo.payPaymentRequest(_kId)).called(1);
      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(store.saved[owner], isEmpty);
    });

    test('killed after the top-up succeeded: resumes /pay, no new charge',
        () async {
      await cubit.restorePaymentAttempts(ownerId: owner);
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('successful'))]);
      stubPay([const ApiResult.failure(error: RemoteException.timeoutError())]);
      await payByCardThenX();
      expect(store.saved[owner]!.single['stage'], 'verified');
      await cubit.close();

      clearInteractions(repo);
      cubit = newCubit();
      stubStatuses([
        ApiResult.success(data: _status('successful', settled: false)),
      ]);
      stubPay([_paid()]);
      await cubit.restorePaymentAttempts(ownerId: owner);
      await cubit.debugPaymentPollingIdle();

      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
      expect(progress().phase, PaymentRequestPaymentPhase.successful);
    });

    test('a restored pending attempt never starts a checkout', () async {
      await store.save(owner, [
        PaymentRequestAttempt(
          requestId: _kId,
          depositId: _kDeposit,
          verified: false,
          updatedAt: clock,
        ),
      ]);
      stubStatuses([ApiResult.success(data: _status('pending'))]);

      await cubit.restorePaymentAttempts(ownerId: owner);
      await cubit.debugPaymentPollingIdle();

      expect(progress().phase, PaymentRequestPaymentPhase.topUpPending);
      expect(progress().depositId, _kDeposit);
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
      verifyNever(() => repo.payPaymentRequest(any()));
    });

    test('completed, failed and cancelled attempts are cleared', () async {
      for (final status in ['failed', 'cancelled']) {
        await cubit.restorePaymentAttempts(ownerId: owner);
        stubTopUpOk();
        stubStatuses([ApiResult.success(data: _status(status))]);
        await payByCardThenX();
        expect(store.saved[owner], isEmpty, reason: status);
      }
      stubStatuses([ApiResult.success(data: _status('successful'))]);
      stubPay([_paid()]);
      await payByCardThenX();
      expect(store.saved[owner], isEmpty);
    });

    test('malformed and expired records are discarded', () async {
      store.saved[owner] = [
        {'request_id': 'five', 'deposit_id': 1},
        {'nonsense': true},
        PaymentRequestAttempt(
          requestId: 6,
          depositId: '2',
          verified: false,
          updatedAt: clock.subtract(const Duration(days: 30)),
        ).toJson(),
      ];

      await cubit.restorePaymentAttempts(ownerId: owner);

      expect(cubit.state.paymentProgress, isEmpty);
      expect(store.saved[owner], isEmpty);
      verifyNever(() => repo.reconcilePeachPayment(any()));
    });

    test('logout clears persisted and in-memory attempts', () async {
      await cubit.restorePaymentAttempts(ownerId: owner);
      stubTopUpOk();
      stubStatuses([_unavailable]);
      await payByCardThenX();
      expect(store.saved[owner], hasLength(1));

      cubit.onLogout();
      await Future<void>.delayed(Duration.zero);

      expect(store.saved[owner], isEmpty);
      expect(cubit.state.paymentProgress, isEmpty);
      expect(progress().phase, PaymentRequestPaymentPhase.idle);
    });

    test("one customer's attempts never appear for another", () async {
      await store.save('A', [
        PaymentRequestAttempt(
          requestId: _kId,
          depositId: _kDeposit,
          verified: false,
          updatedAt: clock,
        ),
      ]);

      await cubit.restorePaymentAttempts(ownerId: 'B');

      expect(cubit.state.paymentProgress, isEmpty);
      verifyNever(() => repo.reconcilePeachPayment(any()));
      expect(store.saved['A'], hasLength(1));
    });
  });

  group('push updates', () {
    test('two pushes for the same request both refresh it', () async {
      await cubit.onPaymentRequestPush('5');
      final first = cubit.state.paymentRequestUpdateSeq;

      stubRequest('paid');
      await cubit.onPaymentRequestPush(_kId);

      expect(cubit.state.paymentRequestUpdateSeq, first + 1);
      expect(cubit.getCachedPaymentRequest(_kId)!.isPaid, isTrue);
    });
  });

  group('request checks and messages', () {
    test('payNowBlocker', () {
      expect(
        cubit.payNowBlocker(
          PaymentRequest(id: _kId, statusRaw: 'accepted', totalAmount: 300),
        ),
        isNull,
      );
      expect(
        cubit.payNowBlocker(
          PaymentRequest(id: _kId, statusRaw: 'accepted', totalAmount: 0),
        ),
        contains('no amount to pay'),
      );
      expect(
        cubit.payNowBlocker(
          PaymentRequest(
            id: _kId,
            statusRaw: 'accepted',
            totalAmount: 300,
            canPay: false,
          ),
        ),
        'This payment request can no longer be paid.',
      );
    });

    test('wallet balance load returns null, not zero, on failure', () async {
      when(repo.getWallet).thenAnswer(
        (_) async =>
            const ApiResult.failure(error: RemoteException.timeoutError()),
      );
      expect(await cubit.loadWalletBalanceForPayment(), isNull);
      when(repo.getWallet).thenAnswer(
        (_) async => ApiResult.success(data: CustomerWallet(balance: 250.5)),
      );
      expect(await cubit.loadWalletBalanceForPayment(), 250.5);
    });

    test('top-up 404 and 5xx stay generic; 4xx refusals are shown', () {
      String message(int status, String text) =>
          ConversationsCubit.topUpFailureMessage(
            RemoteException.serverError(status, ServerError(message: text)),
          );
      expect(
        message(404, 'The route could not be found.'),
        ConversationsCubit.paymentStartFailedMessage,
      );
      expect(
        message(500, 'SQLSTATE internal'),
        ConversationsCubit.paymentStartFailedMessage,
      );
      expect(
        message(422, 'The amount field must be greater than 0.'),
        'The amount field must be greater than 0.',
      );
    });
  });

  group('checkout-close diagnosis regressions', () {
    setUp(() {
      // Generous, so a hung status future would show up as `topUpUnknown`.
      ConversationsCubit.paymentStatusCheckTimeout =
          const Duration(seconds: 5);
    });
    tearDown(() {
      ConversationsCubit.paymentStatusCheckTimeout =
          const Duration(seconds: 15);
    });

    test('a status request completes and releases its slot', () async {
      // Regression: the shared status request awaited itself (an arrow
      // `whenComplete` returned the removed future), so every check hit the
      // UI cap as "unknown" and later checks reused the dead request.
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('pending'))]);
      await cubit.startCardTopUp(_kId, amount: 50);
      cubit.pausePaymentStatusPolling();

      final watch = Stopwatch()..start();
      await cubit.onCardCheckoutClosed(_kId);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(progress().phase, PaymentRequestPaymentPhase.topUpPending);

      await cubit.checkCardPaymentStatus(_kId);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(statusCalls(), 2);
    });

    test('repeated manual checks reuse the original deposit only', () async {
      stubTopUpOk();
      stubStatuses([ApiResult.success(data: _status('pending'))]);
      await cubit.startCardTopUp(_kId, amount: 50);
      cubit.pausePaymentStatusPolling();
      await cubit.onCardCheckoutClosed(_kId);

      for (var i = 0; i < 3; i++) {
        await cubit.checkCardPaymentStatus(_kId);
        expect(progress().depositId, _kDeposit);
        expect(progress().phase, PaymentRequestPaymentPhase.topUpPending);
      }

      // 1 after the X + 3 manual, all for deposit 1.
      expect(statusCalls(), 4);
      verifyNever(
        () => repo.reconcilePeachPayment(any(that: isNot(_kDeposit))),
      );
      expect(topUpCalls(), 1);
      verifyNever(() => repo.payPaymentRequest(any()));
    });

    // The app cannot see what happened inside the Peach page; its behaviour
    // depends only on the status response for the original deposit.
    for (final (scenario, answer, expected, pays) in [
      (
        'X before choosing a payment method',
        ApiResult<PaymentReconciliation>.success(data: _status('pending')),
        PaymentRequestPaymentPhase.topUpPending,
        false,
      ),
      (
        'X after choosing Card, before paying',
        ApiResult<PaymentReconciliation>.success(data: _status('pending')),
        PaymentRequestPaymentPhase.topUpPending,
        false,
      ),
      (
        'X after the payment was submitted (webhook credited first)',
        ApiResult<PaymentReconciliation>.success(
          data: _status('successful', settled: false),
        ),
        PaymentRequestPaymentPhase.successful,
        true,
      ),
      (
        'status endpoint answers 503',
        _unavailable,
        PaymentRequestPaymentPhase.topUpUnknown,
        false,
      ),
      (
        'status body says "unknown" with HTTP 200',
        ApiResult<PaymentReconciliation>.success(data: _status('unknown')),
        PaymentRequestPaymentPhase.topUpPending,
        false,
      ),
    ]) {
      test(scenario, () async {
        stubTopUpOk();
        stubStatuses([answer]);
        stubPay([_paid()]);
        await cubit.startCardTopUp(_kId, amount: 50);
        cubit.pausePaymentStatusPolling();

        await cubit.onCardCheckoutClosed(_kId);

        expect(progress().phase, expected);
        if (pays) {
          verify(() => repo.payPaymentRequest(_kId)).called(1);
        } else {
          verifyNever(() => repo.payPaymentRequest(any()));
          expect(progress().depositId, _kDeposit);
        }
        // One top-up only: status verification never creates another.
        expect(topUpCalls(), 1);
      });
    }
  });
}
