import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/stylist.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/tip/tip_response.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/widgets/tip_payment.dart';

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

class _MockProfileCubit extends MockCubit<CustomerProfileMgtState>
    implements CustomerProfileMgtCubit {}

const _kAppointment = '77';
const _kDeposit = '123';

/// Laravel's card tip `201`: nothing is paid yet.
TipResponse _cardStarted() => TipResponse.fromJson(const {
      'success': true,
      'code': 'checkout_started',
      'status': 'pending',
      'payment_method': 'card',
      'tip_amount': 30,
      'payment': {
        'deposit_id': _kDeposit,
        'checkout_id': 'chk_123',
        'redirect_url': 'https://checkout.example.test/chk_123',
        'status_url':
            'https://api.example.test/api/customer/payment/peach/123/status',
      },
    });

/// Laravel's wallet tip `200`.
TipResponse _walletTipped() => TipResponse.fromJson(const {
      'success': true,
      'code': 'tipped',
      'payment_method': 'wallet',
      'message': 'Tip sent successfully. Thank you for appreciating your '
          'stylist!',
      'tip_amount': 25.5,
      'new_wallet_balance': 74.5,
    });

/// `GET /customer/payment/peach/{deposit}/status` for a card tip.
PaymentReconciliation _tipStatus(String tipStatus, {String? status}) =>
    PaymentReconciliation.fromJson({
      'deposit_id': _kDeposit,
      'purpose': 'tip',
      'status': status ??
          (tipStatus == 'tipped' || tipStatus == 'credited_to_wallet'
              ? 'successful'
              : tipStatus == 'not_paid'
                  ? 'cancelled'
                  : 'pending'),
      'settled': tipStatus == 'tipped',
      'amount': 30,
      'currency': 'ZAR',
      'message': switch (tipStatus) {
        'tipped' => 'Payment verified. Your tip has been sent.',
        'not_paid' => 'The card payment was not completed. No tip was sent.',
        _ => 'Payment is $tipStatus.',
      },
      'tip': {
        'appointment_id': _kAppointment,
        'amount': 30,
        'status': tipStatus,
        'tipped_at': tipStatus == 'tipped' ? '2026-11-10T12:00:00+02:00' : null,
      },
    });

RemoteException _refusal(int status, String code, String message,
        [Map<String, dynamic> extra = const {}]) =>
    RemoteException.serverError(
      status,
      ServerError(message: message),
      code: code,
      responseBody: {'code': code, 'message': message, ...extra},
    );

void main() {
  late _MockAppointmentRepository repo;
  late _MockProfileCubit profile;
  late UpdateCreateAppointmentCubit cubit;

  setUp(() async {
    UpdateCreateAppointmentCubit.tipReconcileRetryGap = Duration.zero;
    repo = _MockAppointmentRepository();
    profile = _MockProfileCubit();
    when(() => profile.getWallet(any())).thenAnswer((_) async {});
    when(() => profile.getWalletTransactions()).thenAnswer((_) async {});
    getIt
      ..allowReassignment = true
      ..registerSingleton<CustomerProfileMgtCubit>(profile);

    cubit = UpdateCreateAppointmentCubit(repo);
    when(() => repo.getCustomerAppointmentById(_kAppointment)).thenAnswer(
      (_) async => ApiResult.success(
        data: CustomerAppointment(
          id: 77,
          status: 'completed',
          portfolioId: 3,
          stylist: Stylist(name: 'Jane Stylist'),
        ),
      ),
    );
    when(() => repo.customerFetchPortfolioById(id: any(named: 'id')))
        .thenAnswer(
      (_) async => ApiResult.success(
        data: SellerPortfolio(id: 3, userId: '8', price: 300),
      ),
    );
    when(() => repo.customerFetchStylistById(any())).thenAnswer(
      (_) async => ApiResult.failure(error: RemoteException.httpError(500)),
    );
    await cubit.fetchAppointmentById(_kAppointment);
    clearInteractions(repo);
  });

  tearDown(() async {
    await cubit.close();
    await getIt.reset();
  });

  void stubTip(
    String method,
    FutureOr<ApiResult<TipResponse>> Function() answer,
  ) {
    when(
      () => repo.tipCustomerAppointment(
        _kAppointment,
        amount: any(named: 'amount'),
        paymentMethod: method,
      ),
    ).thenAnswer((_) async => answer());
  }

  void stubStatus(List<ApiResult<PaymentReconciliation>> answers) {
    when(() => repo.reconcilePeachPayment(_kDeposit)).thenAnswer(
        (_) async => answers.length > 1 ? answers.removeAt(0) : answers.first);
  }

  /// How many tips were requested with [method] (0 when none: mocktail's
  /// `verify` throws on zero calls).
  int tipCalls(String method) {
    try {
      return verify(
        () => repo.tipCustomerAppointment(
          _kAppointment,
          amount: any(named: 'amount'),
          paymentMethod: method,
        ),
      ).callCount;
    } on TestFailure {
      return 0;
    }
  }

  /// The booking is re-fetched by the cubit; the wallet and transactions
  /// are refreshed by `TipOutcomePresenter` through the app's own cubits
  /// (covered in card_tip_recovery_test.dart) — never through a throwaway
  /// `getIt` instance.
  void expectBookingRefreshed() {
    verify(() => repo.getCustomerAppointmentById(_kAppointment)).called(1);
    verifyNever(() => profile.getWallet(any()));
  }

  Future<void> cardTipThenCheckoutClosed() async {
    stubTip('card', () => ApiResult.success(data: _cardStarted()));
    expect(
      await cubit.startTip(30, paymentMethod: 'card'),
      TipStartResult.checkoutStarted,
    );
    await cubit.onTipCheckoutClosed();
  }

  group('wallet tip', () {
    test('success: sent from the wallet, booking and wallet refreshed',
        () async {
      stubTip('wallet', () => ApiResult.success(data: _walletTipped()));

      final result = await cubit.startTip(25.5, paymentMethod: 'wallet');

      expect(result, TipStartResult.tipped);
      expect(cubit.state.tipPayment.phase, TipPaymentPhase.tipped);
      verify(
        () => repo.tipCustomerAppointment(
          _kAppointment,
          amount: 25.5,
          paymentMethod: 'wallet',
        ),
      ).called(1);
      verifyNever(() => repo.reconcilePeachPayment(any()));
      await Future<void>.delayed(Duration.zero);
      expectBookingRefreshed();
    });

    test('insufficient balance: refused with the backend balance, no card',
        () async {
      stubTip(
        'wallet',
        () => ApiResult.failure(
          error: _refusal(
            400,
            'insufficient_wallet_balance',
            'Insufficient wallet balance to send this tip.',
            {'wallet_balance': 10, 'required_amount': 25.5, 'shortfall': 15.5},
          ),
        ),
      );

      final result = await cubit.startTip(25.5, paymentMethod: 'wallet');

      expect(result, TipStartResult.insufficientBalance);
      expect(cubit.state.tipPayment.phase, TipPaymentPhase.failed);
      expect(cubit.state.tipPayment.message, contains('R10.00'));
      expect(tipCalls('card'), 0, reason: 'never switches to card');
      verifyNever(() => profile.getWallet(any()));
    });
  });

  group('card tip', () {
    test('initialization: opens Laravel\'s checkout, nothing paid yet',
        () async {
      stubTip('card', () => ApiResult.success(data: _cardStarted()));

      final result = await cubit.startTip(30, paymentMethod: 'card');

      expect(result, TipStartResult.checkoutStarted);
      final progress = cubit.state.tipPayment;
      expect(progress.phase, TipPaymentPhase.checkoutOpen);
      expect(progress.checkout?.depositId, _kDeposit);
      expect(
        progress.checkout?.redirectUrl,
        'https://checkout.example.test/chk_123',
      );
      expect(progress.checkout?.canOpenCheckout, isTrue);
      verifyNever(() => repo.reconcilePeachPayment(any()));
    });

    test('tipped: verified by Laravel, booking and wallet refreshed', () async {
      stubStatus([ApiResult.success(data: _tipStatus('tipped'))]);

      await cardTipThenCheckoutClosed();

      expect(cubit.state.tipPayment.phase, TipPaymentPhase.tipped);
      verify(() => repo.reconcilePeachPayment(_kDeposit)).called(1);
      await Future<void>.delayed(Duration.zero);
      expectBookingRefreshed();
    });

    test('pending: not success; checked again later; no second checkout',
        () async {
      stubStatus([
        ApiResult.success(data: _tipStatus('pending')),
        ApiResult.success(data: _tipStatus('pending')),
        ApiResult.success(data: _tipStatus('pending')),
        ApiResult.success(data: _tipStatus('tipped')),
      ]);

      await cardTipThenCheckoutClosed();
      expect(cubit.state.tipPayment.phase, TipPaymentPhase.pending);
      expect(cubit.state.tipPayment.checkout?.depositId, _kDeposit);
      verifyNever(() => profile.getWallet(any()));

      // Another tip while this one is unresolved is refused.
      expect(
        await cubit.startTip(30, paymentMethod: 'card'),
        TipStartResult.unresolved,
      );
      expect(tipCalls('card'), 1);

      // Check Payment Status.
      await cubit.verifyTipPayment(automatic: false);
      expect(cubit.state.tipPayment.phase, TipPaymentPhase.tipped);
    });

    test('a pending tip whose deposit failed is still only pending', () async {
      // `tip.status` decides, not the deposit `status`.
      stubStatus([
        ApiResult.success(data: _tipStatus('pending', status: 'failed')),
      ]);

      await cardTipThenCheckoutClosed();

      expect(cubit.state.tipPayment.phase, TipPaymentPhase.pending);
    });

    test('checkout could not start (502): failed, nothing charged', () async {
      stubTip(
        'card',
        () => ApiResult.failure(
          error: _refusal(
            502,
            'checkout_initialization_failed',
            'Card payment could not be started. You have not been charged.',
          ),
        ),
      );

      final result = await cubit.startTip(30, paymentMethod: 'card');

      expect(result, TipStartResult.failed);
      expect(cubit.state.tipPayment.phase, TipPaymentPhase.failed);
      expect(cubit.state.tipPayment.message, contains('not been charged'));
    });

    test('cancelled checkout → not_paid: no tip, another attempt allowed',
        () async {
      stubStatus([ApiResult.success(data: _tipStatus('not_paid'))]);

      await cardTipThenCheckoutClosed();

      expect(cubit.state.tipPayment.phase, TipPaymentPhase.notPaid);
      expect(
        cubit.state.tipPayment.message,
        'The card payment was not completed. No tip was sent.',
      );
      verifyNever(() => profile.getWallet(any()));

      // A new attempt is allowed after not_paid.
      expect(
        await cubit.startTip(30, paymentMethod: 'card'),
        TipStartResult.checkoutStarted,
      );
      expect(tipCalls('card'), 2);
    });

    test('credited_to_wallet: not a tip; wallet and history refreshed',
        () async {
      stubStatus([ApiResult.success(data: _tipStatus('credited_to_wallet'))]);

      await cardTipThenCheckoutClosed();

      final progress = cubit.state.tipPayment;
      expect(progress.phase, TipPaymentPhase.creditedToWallet);
      expect(progress.message, contains('did not receive this tip'));
      expect(progress.message, contains('added to your Snipfair wallet'));
      await Future<void>.delayed(Duration.zero);
      expectBookingRefreshed();
    });

    test('503 (Peach unreachable): unknown, kept for a later check', () async {
      stubStatus([
        ApiResult.failure(
          error: RemoteException.serverError(
            503,
            const ServerError(message: 'Payment could not yet be verified.'),
            responseBody: const {'status': 'unknown'},
          ),
        ),
      ]);

      await cardTipThenCheckoutClosed();

      expect(cubit.state.tipPayment.phase, TipPaymentPhase.unknown);
      expect(cubit.state.tipPayment.checkout?.depositId, _kDeposit);
    });

    test('disabled card tipping: refused clearly, no wallet fallback',
        () async {
      stubTip(
        'card',
        () => ApiResult.failure(
          error: _refusal(
            422,
            'payment_method_unavailable',
            'Card tipping is not available yet. Please tip from your wallet.',
          ),
        ),
      );

      final result = await cubit.startTip(30, paymentMethod: 'card');

      expect(result, TipStartResult.cardUnavailable);
      expect(
        cubit.state.tipPayment.message,
        UpdateCreateAppointmentCubit.tipCardUnavailableMessage,
      );
      expect(tipCalls('wallet'), 0, reason: 'no silent wallet fallback');
    });

    test('repeated submissions while one is in flight send one request',
        () async {
      final gate = Completer<ApiResult<TipResponse>>();
      stubTip('card', () => gate.future);

      final first = cubit.startTip(30, paymentMethod: 'card');
      final second = await cubit.startTip(30, paymentMethod: 'card');
      final third = await cubit.startTip(30, paymentMethod: 'wallet');

      expect(second, TipStartResult.busy);
      expect(third, TipStartResult.busy);
      gate.complete(ApiResult.success(data: _cardStarted()));
      expect(await first, TipStartResult.checkoutStarted);
      expect(tipCalls('card'), 1);
      expect(tipCalls('wallet'), 0);
    });
  });

  group('tip response parsing', () {
    test('wallet 200', () {
      final tip = _walletTipped();
      expect(tip.isTipped, isTrue);
      expect(tip.newWalletBalance, 74.5);
      expect(tip.checkout, isNull);
    });

    test('card 201: snake_case checkout fields', () {
      final tip = _cardStarted();
      expect(tip.isTipped, isFalse);
      expect(tip.isCheckoutStarted, isTrue);
      expect(tip.checkout?.checkoutId, 'chk_123');
      expect(tip.tipAmount, 30);
    });
  });

  group('tip sheet', () {
    late List<(double, String)> submitted;
    late Completer<(TipStartResult, String?)> answer;

    Future<void> pumpSheet(WidgetTester tester, {num? balance = 100}) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 1200 * 3)
        ..devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      submitted = [];
      answer = Completer();
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TipBottomSheet(
                  walletBalance: balance,
                  stylistName: 'Jane Stylist',
                  onSubmit: (amount, method) {
                    submitted.add((amount, method));
                    return answer.future;
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'card: confirms stylist and amount, then submits once despite taps',
        (tester) async {
      FlutterError.onError = _ignoreOverflow(FlutterError.onError);
      await pumpSheet(tester);
      await tester.tap(find.byKey(const Key('tip_quick_50')));
      await tester.tap(find.byKey(const Key('payment_method_card')));
      await tester.pump();
      expect(find.text('Pay by Card'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tip_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Send R50.00 tip?'), findsOneWidget);
      expect(
        find.textContaining('goes to Jane Stylist, paid from your card'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue to Card'));
      await tester.pump();
      // While the request runs, more taps do nothing.
      await tester.tap(find.byKey(const Key('tip_submit')),
          warnIfMissed: false);
      await tester.pump();

      expect(submitted, [(50.0, 'card')]);
      answer.complete((TipStartResult.checkoutStarted, null));
      await tester.pumpAndSettle();
    });

    testWidgets('a refusal stays in the sheet with its reason', (tester) async {
      FlutterError.onError = _ignoreOverflow(FlutterError.onError);
      await pumpSheet(tester);
      await tester.enterText(find.byType(TextField), '25.50');
      await tester.tap(find.byKey(const Key('tip_submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Tip').last);
      await tester.pump();
      answer.complete((
        TipStartResult.cardUnavailable,
        UpdateCreateAppointmentCubit.tipCardUnavailableMessage,
      ));
      await tester.pumpAndSettle();

      expect(submitted, [(25.5, 'wallet')]);
      expect(find.byKey(const Key('tip_error')), findsOneWidget);
      expect(find.byType(TipBottomSheet), findsOneWidget);
    });

    testWidgets('known low wallet balance is flagged before any request',
        (tester) async {
      FlutterError.onError = _ignoreOverflow(FlutterError.onError);
      await pumpSheet(tester, balance: 10);
      await tester.enterText(find.byType(TextField), '50');
      await tester.tap(find.byKey(const Key('tip_submit')));
      await tester.pumpAndSettle();

      expect(submitted, isEmpty);
      expect(find.textContaining('Choose Card'), findsOneWidget);
    });

    testWidgets('more than two decimals is rejected locally', (tester) async {
      FlutterError.onError = _ignoreOverflow(FlutterError.onError);
      await pumpSheet(tester);
      await tester.enterText(find.byType(TextField), '10.555');
      await tester.tap(find.byKey(const Key('tip_submit')));
      await tester.pumpAndSettle();

      expect(submitted, isEmpty);
      expect(find.byKey(const Key('tip_error')), findsOneWidget);
    });
  });

  testWidgets('TipFlow: card checkout closed → Laravel decides (tipped)',
      (tester) async {
    FlutterError.onError = _ignoreOverflow(FlutterError.onError);
    stubTip('card', () => ApiResult.success(data: _cardStarted()));
    stubStatus([ApiResult.success(data: _tipStatus('tipped'))]);
    final opened = <CheckoutPaymentData>[];
    final original = TipFlow.openCheckout;
    TipFlow.openCheckout = (context, checkout) async {
      opened.add(checkout);
      return false; // Closing checkout is not proof of anything.
    };
    addTearDown(() => TipFlow.openCheckout = original);
    tester.view
      ..physicalSize = const Size(390 * 3, 1200 * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => TipFlow.start(
                context,
                cubit: cubit,
                walletBalance: 100,
                stylistName: 'Jane Stylist',
              ),
              child: const Text('tip'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('tip'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tip_quick_20')));
    await tester.tap(find.byKey(const Key('payment_method_card')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tip_submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to Card'));
    await tester.pumpAndSettle();

    expect(opened.single.redirectUrl, 'https://checkout.example.test/chk_123');
    expect(cubit.state.tipPayment.phase, TipPaymentPhase.tipped);
    verify(
      () => repo.tipCustomerAppointment(
        _kAppointment,
        amount: 20,
        paymentMethod: 'card',
      ),
    ).called(1);
  });
}

/// The test font draws every glyph as a full em square; fixed-height dialogs
/// overflow in tests only. Overflows are ignored; other errors still fail.
FlutterExceptionHandler? _ignoreOverflow(FlutterExceptionHandler? original) {
  addTearDown(() => FlutterError.onError = original);
  return (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
}
