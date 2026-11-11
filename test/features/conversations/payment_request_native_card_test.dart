import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/customer_wallet.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request_card_payment.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request_pay_result.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/payment_request_card.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/features/conversations/data/payment_request_attempt_store.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

class _MemoryAttemptStore implements PaymentRequestAttemptStore {
  final saved = <String, List<PaymentRequestAttempt>>{};

  @override
  List<PaymentRequestAttempt> load(String ownerId) => saved[ownerId] ?? [];

  @override
  Future<void> save(
          String ownerId, List<PaymentRequestAttempt> attempts) async =>
      saved[ownerId] = [...attempts];

  @override
  Future<void> clear(String ownerId) async => saved.remove(ownerId);
}

const _kId = 9;
const _kPayment = '31';

PaymentRequest _request(String status) => PaymentRequest(
      id: _kId,
      title: 'Extra products',
      statusRaw: status,
      totalAmount: 300,
      canPay: status == 'accepted',
    );

PaymentRequestCardCheckout _checkout({bool reused = false}) =>
    PaymentRequestCardCheckout.fromJson({
      'message': reused ? 'Card checkout resumed.' : 'Card checkout started.',
      'status': 'pending',
      'payment_method': 'card',
      'payment': {
        'payment_id': _kPayment,
        'checkout_id': 'chk_31',
        'redirect_url': 'https://checkout.example.test/chk_31',
        'reused': reused,
      },
    });

PaymentRequestCardPaymentStatus _status(
  String paymentStatus, {
  bool paid = false,
  String? message,
  String requestStatus = 'accepted',
}) =>
    PaymentRequestCardPaymentStatus(
      paymentId: _kPayment,
      paymentStatus: paymentStatus,
      paid: paid,
      paymentRequestStatus: requestStatus,
      message: message,
      paymentRequest: _request(requestStatus),
    );

RemoteException _refusal(
  int status,
  String code,
  String message, [
  Map<String, dynamic> extra = const {},
]) =>
    RemoteException.serverError(
      status,
      ServerError(message: message),
      code: code,
      responseBody: {'code': code, 'message': message, ...extra},
    );

void main() {
  late _MockProfileRepository repo;
  late ConversationsCubit cubit;
  late List<FutureOr<ApiResult<PaymentRequestCardPaymentStatus>> Function()>
      statuses;

  setUp(() {
    var clock = DateTime(2026, 11, 10, 12);
    ConversationsCubit.paymentPollSleep = (d) async => clock = clock.add(d);
    ConversationsCubit.paymentClock = () => clock;
    repo = _MockProfileRepository();
    cubit = ConversationsCubit(repo, attemptStore: _MemoryAttemptStore());
    statuses = [];

    when(() => repo.getPaymentRequest(_kId)).thenAnswer(
      (_) async => ApiResult.success(data: _request('accepted')),
    );
    when(() => repo.startPaymentRequestCardCheckout(_kId))
        .thenAnswer((_) async => ApiResult.success(data: _checkout()));
    when(() => repo.getPaymentRequestCardPaymentStatus(_kId, any())).thenAnswer(
        (_) async =>
            statuses.length > 1 ? statuses.removeAt(0)() : statuses.first());
  });

  tearDown(() async {
    await cubit.debugPaymentPollingIdle();
    await cubit.close();
  });

  PaymentRequestPaymentProgress progress() => cubit.paymentProgressFor(_kId);

  Future<void> cardAttemptThenCheckoutClosed() async {
    expect(await cubit.startCardCheckout(_kId), isNotNull);
    await cubit.onCardCheckoutClosed(_kId);
  }

  int checkoutsStarted() {
    try {
      return verify(() => repo.startPaymentRequestCardCheckout(_kId)).callCount;
    } on TestFailure {
      return 0;
    }
  }

  group('wallet', () {
    test('wallet payment success: paid and the request refreshed', () async {
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => ApiResult.success(
          data: PaymentRequestPayResult(
            code: 'paid',
            paymentRequest: _request('paid'),
            newWalletBalance: 200,
          ),
        ),
      );

      await cubit.payFromWallet(_kId);

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(cubit.getCachedPaymentRequest(_kId)?.isPaid, isTrue);
      verifyNever(() => repo.startPaymentRequestCardCheckout(any()));
    });

    test('insufficient wallet balance: the backend shortfall, no charge',
        () async {
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => ApiResult.failure(
          error: _refusal(
            400,
            'insufficient_wallet_balance',
            'Insufficient wallet balance.',
            {'wallet_balance': 100, 'required_amount': 300, 'shortfall': 200},
          ),
        ),
      );

      await cubit.payFromWallet(_kId);

      expect(progress().phase, PaymentRequestPaymentPhase.awaitingWalletFunds);
      expect(progress().shortfall, 200);
      verifyNever(() => repo.startPaymentRequestCardCheckout(any()));
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
    });

    test('a card attempt still in progress blocks the wallet: check it',
        () async {
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => ApiResult.failure(
          error: _refusal(
            409,
            'card_payment_in_progress',
            'A card payment for this request is still in progress.',
            {
              'payment': {
                'payment_id': _kPayment,
                'payment_method': 'card',
                'status': 'pending',
              },
            },
          ),
        ),
      );
      statuses.add(
        () => ApiResult.success(
          data: _status('successful', paid: true, requestStatus: 'paid'),
        ),
      );

      await cubit.payFromWallet(_kId);
      expect(progress().phase, PaymentRequestPaymentPhase.topUpUnknown);
      expect(progress().cardPaymentId, _kPayment);

      await cubit.checkCardPaymentStatus(_kId);
      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      verify(() => repo.payPaymentRequest(_kId)).called(1);
    });
  });

  group('card', () {
    test('initialization: Laravel\'s checkout, nothing paid yet', () async {
      final checkout = await cubit.startCardCheckout(_kId);

      expect(checkout?.paymentId, _kPayment);
      expect(
        checkout?.toCheckoutData().redirectUrl,
        'https://checkout.example.test/chk_31',
      );
      expect(progress().phase, PaymentRequestPaymentPhase.checkoutOpen);
      expect(progress().cardPaymentId, _kPayment);
      verifyNever(() => repo.payPaymentRequest(any()));
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
      verifyNever(() => repo.getPaymentRequestCardPaymentStatus(any(), any()));
    });

    test('successful verification: paid: true only, request refreshed',
        () async {
      statuses.add(
        () => ApiResult.success(
          data: _status(
            'successful',
            paid: true,
            requestStatus: 'paid',
            message: 'Payment verified. The payment request has been paid.',
          ),
        ),
      );

      await cardAttemptThenCheckoutClosed();

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(
        progress().message,
        'Payment verified. The payment request has been paid.',
      );
      verify(() => repo.getPaymentRequestCardPaymentStatus(_kId, _kPayment))
          .called(1);
      expect(cubit.getCachedPaymentRequest(_kId)?.isPaid, isTrue);
      expect(cubit.state.lastUpdatedPaymentRequestId, _kId);
    });

    test('"successful" without paid: true is not success', () async {
      statuses.add(() => ApiResult.success(data: _status('successful')));

      await cardAttemptThenCheckoutClosed();

      expect(progress().phase, PaymentRequestPaymentPhase.topUpPending);
      expect(progress().cardPaymentId, _kPayment);
    });

    test('pending: not success; kept; no second checkout; paid later',
        () async {
      statuses
        ..add(() => ApiResult.success(data: _status('pending')))
        ..add(
          () => ApiResult.success(
            data: _status('successful', paid: true, requestStatus: 'paid'),
          ),
        );

      await cardAttemptThenCheckoutClosed();
      // The first check said pending; background polling continues.
      await cubit.debugPaymentPollingIdle();

      expect(progress().phase, PaymentRequestPaymentPhase.successful);
      expect(checkoutsStarted(), 1);
    });

    test('pending: a new card payment is refused until checked', () async {
      statuses.add(() => ApiResult.success(data: _status('pending')));
      await cardAttemptThenCheckoutClosed();
      cubit.pausePaymentStatusPolling();

      expect(await cubit.startCardCheckout(_kId), isNull);
      expect(progress().message, contains('Check Payment Status first'));
      expect(checkoutsStarted(), 1);
      // Nor from the wallet.
      await cubit.payFromWallet(_kId);
      verifyNever(() => repo.payPaymentRequest(any()));
    });

    test('failed: not paid; Pay Now may start a new card payment', () async {
      statuses.add(
        () => ApiResult.success(
          data: _status(
            'failed',
            message: 'The card payment was not completed. '
                'You have not been charged.',
          ),
        ),
      );

      await cardAttemptThenCheckoutClosed();

      expect(progress().phase, PaymentRequestPaymentPhase.failed);
      expect(progress().message, contains('not been charged'));
      expect(await cubit.startCardCheckout(_kId), isNotNull);
      expect(checkoutsStarted(), 2);
    });

    test('cancelled checkout: cancelled, never success', () async {
      statuses.add(() => ApiResult.success(data: _status('cancelled')));

      await cardAttemptThenCheckoutClosed();

      expect(progress().phase, PaymentRequestPaymentPhase.cancelled);
      expect(cubit.getCachedPaymentRequest(_kId)?.isPaid, isFalse);
    });

    test('requires_refund: not paid, Laravel\'s explanation shown', () async {
      statuses.add(
        () => ApiResult.success(
          data: _status(
            'requires_refund',
            message: 'Your card was charged but this request could not be '
                'paid. Snipfair support will refund you.',
          ),
        ),
      );

      await cardAttemptThenCheckoutClosed();

      expect(progress().phase, PaymentRequestPaymentPhase.failed);
      expect(progress().message, contains('will refund you'));
    });

    test('503 (Peach unreachable): unknown, the attempt is kept', () async {
      statuses.add(
        () => ApiResult.failure(
          error: RemoteException.serverError(
            503,
            const ServerError(
              message: 'The card payment has not been confirmed yet.',
            ),
          ),
        ),
      );

      await cardAttemptThenCheckoutClosed();
      cubit.pausePaymentStatusPolling();

      expect(progress().phase, PaymentRequestPaymentPhase.topUpUnknown);
      expect(progress().cardPaymentId, _kPayment);
    });

    test('disabled card payment: explained, nothing else started', () async {
      when(() => repo.startPaymentRequestCardCheckout(_kId)).thenAnswer(
        (_) async => ApiResult.failure(
          error: _refusal(
            422,
            'payment_method_unavailable',
            'Card payment is not available yet. Please pay from your wallet.',
          ),
        ),
      );

      expect(await cubit.startCardCheckout(_kId), isNull);

      expect(progress().phase, PaymentRequestPaymentPhase.cardUnavailable);
      expect(progress().message, ConversationsCubit.cardUnavailableMessage);
      verifyNever(() => repo.payPaymentRequest(any()));
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
    });

    test('an unresolved earlier attempt is checked, not replaced', () async {
      when(() => repo.startPaymentRequestCardCheckout(_kId)).thenAnswer(
        (_) async => ApiResult.failure(
          error: _refusal(
            409,
            'card_payment_unresolved',
            'A previous card payment for this request has not been resolved.',
            {
              'payment': {
                'payment_id': '30',
                'payment_method': 'card',
                'status': 'pending',
              },
            },
          ),
        ),
      );
      statuses.add(() => ApiResult.success(data: _status('cancelled')));

      expect(await cubit.startCardCheckout(_kId), isNull);

      verify(() => repo.getPaymentRequestCardPaymentStatus(_kId, '30'))
          .called(1);
      expect(progress().phase, PaymentRequestPaymentPhase.cancelled);
    });

    test('duplicate taps: one checkout request', () async {
      final gate = Completer<ApiResult<PaymentRequestCardCheckout>>();
      when(() => repo.startPaymentRequestCardCheckout(_kId))
          .thenAnswer((_) => gate.future);

      final first = cubit.startCardCheckout(_kId);
      expect(cubit.beginPaymentRequestPayment(_kId), isFalse);
      expect(await cubit.startCardCheckout(_kId), isNull);
      gate.complete(ApiResult.success(data: _checkout()));
      expect(await first, isNotNull);

      expect(checkoutsStarted(), 1);
    });

    test('a resumed checkout reuses Laravel\'s attempt', () async {
      when(() => repo.startPaymentRequestCardCheckout(_kId)).thenAnswer(
        (_) async => ApiResult.success(data: _checkout(reused: true)),
      );

      final checkout = await cubit.startCardCheckout(_kId);

      expect(checkout?.reused, isTrue);
      expect(progress().cardPaymentId, _kPayment);
    });

    test('an unresolved attempt survives a restart and is re-checked',
        () async {
      final store = _MemoryAttemptStore();
      final first = ConversationsCubit(repo, attemptStore: store);
      await first.restorePaymentAttempts(ownerId: 'customer-1');
      statuses.add(() => ApiResult.success(data: _status('pending')));
      expect(await first.startCardCheckout(_kId), isNotNull);
      await first.onCardCheckoutClosed(_kId);
      first.pausePaymentStatusPolling();
      await first.close();
      expect(store.load('customer-1').single.cardPaymentId, _kPayment);

      statuses
        ..clear()
        ..add(
          () => ApiResult.success(
            data: _status('successful', paid: true, requestStatus: 'paid'),
          ),
        );
      final restarted = ConversationsCubit(repo, attemptStore: store);
      await restarted.restorePaymentAttempts(ownerId: 'customer-1');

      expect(
        restarted.paymentProgressFor(_kId).phase,
        PaymentRequestPaymentPhase.successful,
      );
      expect(store.load('customer-1'), isEmpty);
      await restarted.debugPaymentPollingIdle();
      await restarted.close();
    });
  });

  testWidgets('Pay Now → Card opens Laravel\'s checkout; paid only on paid',
      (tester) async {
    final profile = CustomerProfileMgtCubit(repo);
    final app = _MockAppCubit();
    when(() => app.state).thenReturn(
      const AppState.authenticated(user: User(role: 'customer')),
    );
    when(repo.getWallet).thenAnswer(
      (_) async => ApiResult.success(data: CustomerWallet(balance: 500)),
    );
    when(() => repo.getWalletTransactions(page: any(named: 'page'))).thenAnswer(
      (_) async => ApiResult.success(data: CustomerWalletTransactionList()),
    );
    statuses.add(
      () => ApiResult.success(
        data: _status('successful', paid: true, requestStatus: 'paid'),
      ),
    );
    final opened = <CheckoutPaymentData>[];
    final original = PaymentRequestCard.openCheckout;
    PaymentRequestCard.openCheckout = (context, checkout) async {
      opened.add(checkout);
      return false; // Closed with the X: not proof of anything.
    };
    addTearDown(() => PaymentRequestCard.openCheckout = original);
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider<AppCubit>.value(value: app),
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: profile),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PaymentRequestCard(paymentRequestId: _kId),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay Now'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const Key('payment_method_card')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('payment_request_method_continue')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(opened.single.redirectUrl, 'https://checkout.example.test/chk_31');
    verifyNever(() => repo.payPaymentRequest(any()));
    expect(progress().phase, PaymentRequestPaymentPhase.successful);
    expect(find.text('Paid'), findsWidgets);
    await profile.close();
  });
}
