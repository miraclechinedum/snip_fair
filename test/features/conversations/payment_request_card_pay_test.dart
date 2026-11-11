import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/customer_wallet.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request_pay_result.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/payment_request_card.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/payment_request_method_sheet.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

const _kId = 9;

PaymentRequestPayResult _paidResult() => PaymentRequestPayResult(
      code: 'paid',
      message: 'Payment successful.',
      paymentRequest: PaymentRequest(
        id: _kId,
        title: 'Extra products',
        statusRaw: 'paid',
        totalAmount: 300,
      ),
    );

/// Pay Now shows an indeterminate spinner while the sheet is open, so
/// `pumpAndSettle` would never return; advance past the sheet animation.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Iterable<CustomButton> _buttonsIn(Iterable<Element> elements) =>
    elements.map((element) => element.widget).whereType<CustomButton>();

void main() {
  late _MockProfileRepository repo;
  late ConversationsCubit conversationsCubit;
  late CustomerProfileMgtCubit profileCubit;
  late _MockAppCubit appCubit;

  void stubRequest(PaymentRequest pr) {
    when(() => repo.getPaymentRequest(_kId))
        .thenAnswer((_) async => ApiResult.success(data: pr));
  }

  Finder snackText(String text) => find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(text),
      );

  void expectNoPaymentStarted() {
    verifyNever(() => repo.payPaymentRequest(any()));
    verifyNever(() => repo.initializeWalletTopUp(amount: any(named: 'amount')));
  }

  void expectLoadingCleared() {
    expect(find.text('Pay Now'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The cubit-level pay slot is released for the next attempt.
    expect(conversationsCubit.beginPaymentRequestPayment(_kId), isTrue);
  }

  setUp(() {
    var clock = DateTime(2026, 11, 1, 12);
    ConversationsCubit.paymentPollSleep = (d) async => clock = clock.add(d);
    ConversationsCubit.paymentClock = () => clock;
    repo = _MockProfileRepository();
    conversationsCubit = ConversationsCubit(repo);
    profileCubit = CustomerProfileMgtCubit(repo);
    appCubit = _MockAppCubit();

    when(() => appCubit.state).thenReturn(
      const AppState.authenticated(user: User(role: 'customer')),
    );
    stubRequest(
      PaymentRequest(
        id: _kId,
        title: 'Extra products',
        statusRaw: 'accepted',
        totalAmount: 300,
        canPay: true,
      ),
    );
    when(repo.getWallet).thenAnswer(
      (_) async => ApiResult.success(data: CustomerWallet(balance: 500)),
    );
    when(() => repo.getWalletTransactions(page: any(named: 'page'))).thenAnswer(
      (_) async => ApiResult.success(data: CustomerWalletTransactionList()),
    );
    // The backend's current state: native card payment for requests is off
    // (`PEACH_PAYMENT_REQUEST_CARD_ENABLED`). The wallet top-up route is
    // then only taken when the customer chooses it.
    when(() => repo.startPaymentRequestCardCheckout(_kId)).thenAnswer(
      (_) async => const ApiResult.failure(
        error: RemoteException.serverError(
          422,
          ServerError(
            message: 'Card payment is not available yet. '
                'Please pay from your wallet.',
          ),
          code: 'payment_method_unavailable',
        ),
      ),
    );
  });

  /// Card → Continue; Laravel says card payment is unavailable, so the
  /// customer explicitly picks "Add Funds by Card, then Pay" and confirms.
  Future<void> chooseCardThenTopUpRoute(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('payment_method_card')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('payment_request_method_continue')));
    await _settle(tester);
    verify(() => repo.startPaymentRequestCardCheckout(_kId)).called(1);
    verifyNever(() => repo.initializeWalletTopUp(amount: any(named: 'amount')));
    // The same explanation stays on the card; let its snackbar go first.
    ScaffoldMessenger.of(tester.element(find.byType(PaymentRequestCard)))
        .hideCurrentSnackBar();
    await _settle(tester);
    await tester.ensureVisible(
      find.byKey(const Key('payment_request_topup_and_pay')),
    );
    await tester.tap(find.byKey(const Key('payment_request_topup_and_pay')));
    await _settle(tester);
    expect(
      find.byKey(const Key('payment_request_topup_consent')),
      findsOneWidget,
    );
    await tester.tap(find.text('Add Funds & Pay'));
    await _settle(tester);
  }

  tearDown(() async {
    await conversationsCubit.close();
    await profileCubit.close();
  });

  Future<void> pumpCard(WidgetTester tester, {bool settle = true}) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider<AppCubit>.value(value: appCubit),
            BlocProvider.value(value: conversationsCubit),
            BlocProvider.value(value: profileCubit),
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
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('Pay Now opens the wallet / card method selection',
      (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Pay Now'));
    await _settle(tester);

    expect(find.byType(PaymentRequestMethodSheet), findsOneWidget);
    expect(find.byKey(const Key('payment_method_wallet')), findsOneWidget);
    expect(find.byKey(const Key('payment_method_card')), findsOneWidget);
    // Fresh balance is fetched before the choice is offered.
    verify(repo.getWallet).called(1);
    // Choosing a method is not paying.
    verifyNever(() => repo.payPaymentRequest(any()));
  });

  testWidgets('dismissing the sheet clears loading without paying',
      (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Pay Now'));
    await _settle(tester);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    expect(find.byType(PaymentRequestMethodSheet), findsNothing);
    expect(find.text('Pay Now'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    verifyNever(() => repo.payPaymentRequest(any()));
    verifyNever(() => repo.initializeWalletTopUp(amount: any(named: 'amount')));
    // The pay slot is released for the next attempt.
    expect(conversationsCubit.beginPaymentRequestPayment(_kId), isTrue);
  });

  testWidgets('repeated taps open a single selection', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Pay Now'));
    await tester.tap(find.text('Pay Now'), warnIfMissed: false);
    await _settle(tester);

    expect(find.byType(PaymentRequestMethodSheet), findsOneWidget);
    verify(repo.getWallet).called(1);
  });

  testWidgets('short wallet defaults to card and flags the shortfall',
      (tester) async {
    when(repo.getWallet).thenAnswer(
      (_) async => ApiResult.success(data: CustomerWallet(balance: 100)),
    );
    await pumpCard(tester);

    await tester.tap(find.text('Pay Now'));
    await _settle(tester);
    expect(
      find.byKey(const Key('payment_request_wallet_shortfall')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('payment_method_wallet')));
    await _settle(tester);
    expect(
      find.byKey(const Key('payment_request_wallet_shortfall')),
      findsOneWidget,
    );
  });

  group('wallet balance', () {
    testWidgets('failed balance request still opens the options',
        (tester) async {
      when(repo.getWallet).thenAnswer(
        (_) async =>
            const ApiResult.failure(error: RemoteException.timeoutError()),
      );
      await pumpCard(tester);

      await tester.tap(find.text('Pay Now'));
      await _settle(tester);

      expect(find.byType(PaymentRequestMethodSheet), findsOneWidget);
      expect(find.text('Balance unavailable'), findsOneWidget);
      expect(
        find.byKey(const Key('payment_request_wallet_unavailable')),
        findsOneWidget,
      );
      expectNoPaymentStarted();
    });

    testWidgets('unknown balance lets /pay judge the wallet payment',
        (tester) async {
      when(repo.getWallet).thenAnswer(
        (_) async =>
            const ApiResult.failure(error: RemoteException.timeoutError()),
      );
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => const ApiResult.failure(
          error: RemoteException.serverError(
            400,
            ServerError(message: 'Insufficient wallet balance.'),
          ),
        ),
      );
      await pumpCard(tester);

      await tester.tap(find.text('Pay Now'));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('payment_method_wallet')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('payment_request_method_continue')));
      await _settle(tester);

      verify(() => repo.payPaymentRequest(_kId)).called(1);
      expect(snackText('Insufficient wallet balance.'), findsOneWidget);
      expectLoadingCleared();
    });
  });

  group('payment request data', () {
    Future<void> expectBlocked(
      WidgetTester tester,
      PaymentRequest pr,
      String message,
    ) async {
      stubRequest(pr);
      await pumpCard(tester);

      await tester.tap(find.text('Pay Now'));
      await _settle(tester);

      expect(find.byType(PaymentRequestMethodSheet), findsNothing);
      expect(snackText(message), findsOneWidget);
      verifyNever(repo.getWallet);
      expectNoPaymentStarted();
      expectLoadingCleared();
    }

    testWidgets('missing amount is reported, not opened', (tester) async {
      await expectBlocked(
        tester,
        PaymentRequest(id: _kId, statusRaw: 'accepted'),
        'This payment request has no amount to pay. '
            'Please ask your stylist to send it again.',
      );
    });

    testWidgets('zero amount is reported, not opened', (tester) async {
      await expectBlocked(
        tester,
        PaymentRequest(id: _kId, statusRaw: 'accepted', totalAmount: 0),
        'This payment request has no amount to pay. '
            'Please ask your stylist to send it again.',
      );
    });

    testWidgets('backend can_pay=false is reported, not opened',
        (tester) async {
      await expectBlocked(
        tester,
        PaymentRequest(
          id: _kId,
          statusRaw: 'accepted',
          totalAmount: 300,
          canPay: false,
        ),
        'This payment request can no longer be paid.',
      );
    });

    testWidgets('can_pay absent from the payload does not block',
        (tester) async {
      stubRequest(
        PaymentRequest(id: _kId, statusRaw: 'accepted', totalAmount: 300),
      );
      await pumpCard(tester);

      await tester.tap(find.text('Pay Now'));
      await _settle(tester);

      expect(find.byType(PaymentRequestMethodSheet), findsOneWidget);
    });
  });

  testWidgets('exception before the sheet clears loading and explains',
      (tester) async {
    when(repo.getWallet).thenThrow(StateError('boom'));
    await pumpCard(tester);

    await tester.tap(find.text('Pay Now'));
    await _settle(tester);

    expect(find.byType(PaymentRequestMethodSheet), findsNothing);
    expect(
      snackText("We couldn't open payment options. Please try again."),
      findsOneWidget,
    );
    expectNoPaymentStarted();
    expectLoadingCleared();
  });

  group('wallet payment', () {
    Future<void> payWithWallet(WidgetTester tester) async {
      await pumpCard(tester);
      await tester.tap(find.text('Pay Now'));
      await _settle(tester);
      // Balance 500 covers 300, so Wallet is preselected.
      await tester.tap(find.byKey(const Key('payment_request_method_continue')));
      await _settle(tester);
    }

    testWidgets('pays once and shows the request as paid', (tester) async {
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => ApiResult.success(data: _paidResult()),
      );

      await payWithWallet(tester);

      verify(() => repo.payPaymentRequest(_kId)).called(1);
      verifyNever(() => repo.initializeWalletTopUp(amount: any(named: 'amount')));
      expect(find.text('Pay Now'), findsNothing);
      expect(snackText('Payment successful.'), findsOneWidget);
    });

    testWidgets('server failure shows the backend message', (tester) async {
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => const ApiResult.failure(
          error: RemoteException.serverError(
            500,
            ServerError(
              message:
                  'Payment failed. You have not been charged. Please try again.',
            ),
          ),
        ),
      );

      await payWithWallet(tester);

      expect(
        snackText(
          'Payment failed. You have not been charged. Please try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Action failed. Please try again.'), findsNothing);
      expectLoadingCleared();
    });

    testWidgets('unreachable server says so', (tester) async {
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => ApiResult.failure(
          error: RemoteException.unexpectedError('connectionError'),
        ),
      );

      await payWithWallet(tester);

      expect(
        snackText(
          "We couldn't reach Snipfair. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expectLoadingCleared();
    });
  });

  group('card payment start failures', () {
    Future<void> payWithCard(WidgetTester tester) async {
      await pumpCard(tester);
      await tester.tap(find.text('Pay Now'));
      await _settle(tester);
      await chooseCardThenTopUpRoute(tester);
    }

    void stubTopUpFailure(RemoteException error) {
      when(() => repo.initializeWalletTopUp(amount: any(named: 'amount')))
          .thenAnswer((_) async => ApiResult.failure(error: error));
    }

    testWidgets('404 shows the safe generic message', (tester) async {
      stubTopUpFailure(
        const RemoteException.serverError(
          404,
          ServerError(
            message: 'The route api/customer/payment/topup could not be found.',
          ),
        ),
      );

      await payWithCard(tester);

      verify(() => repo.initializeWalletTopUp(amount: 300)).called(1);
      expect(
        snackText('Unable to start payment. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('could not be found'), findsNothing);
      verifyNever(() => repo.payPaymentRequest(any()));
      expectLoadingCleared();
    });

    testWidgets('5xx shows the safe generic message', (tester) async {
      stubTopUpFailure(
        const RemoteException.serverError(
          500,
          ServerError(message: 'SQLSTATE[42S02] internal detail'),
        ),
      );

      await payWithCard(tester);

      expect(
        snackText('Unable to start payment. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('SQLSTATE'), findsNothing);
      expectLoadingCleared();
    });

    testWidgets('a backend refusal is shown to the customer', (tester) async {
      stubTopUpFailure(
        const RemoteException.serverError(
          400,
          ServerError(message: 'Bookings are paused for maintenance.'),
        ),
      );

      await payWithCard(tester);

      expect(snackText('Bookings are paused for maintenance.'), findsOneWidget);
      verifyNever(() => repo.payPaymentRequest(any()));
      expectLoadingCleared();
    });
  });

  group('payment progress on the card', () {
    const checkout = CheckoutPaymentData(
      isInitialized: true,
      depositId: '77',
      redirectUrl: 'https://checkout.example.test/chk_77',
    );

    void stubTopUp() {
      when(() => repo.initializeWalletTopUp(amount: any(named: 'amount')))
          .thenAnswer((_) async => const ApiResult.success(data: checkout));
    }

    void stubStatus(ApiResult<PaymentReconciliation> answer) {
      when(() => repo.reconcilePeachPayment('77'))
          .thenAnswer((_) async => answer);
    }

    // The test font draws every glyph as a full em square, so the
    // 20-character "Check Payment Status" label (booking uses the same one)
    // is ~2x wider than in the real font and overflows a phone-width card by
    // a few points. Render this group's text slightly smaller.
    setUp(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher
          .textScaleFactorTestValue = 0.9;
    });
    tearDown(
      TestWidgetsFlutterBinding.instance.platformDispatcher
          .clearTextScaleFactorTestValue,
    );

    /// Runs a card attempt through the cubit (as the card does) before the
    /// card is built — the card must render whatever phase it finds.
    Future<void> cardAttempt(WidgetTester tester) => tester.runAsync(() async {
          await conversationsCubit.startCardTopUp(_kId, amount: 300);
          await conversationsCubit.onCardCheckoutClosed(_kId);
          await conversationsCubit.debugPaymentPollingIdle();
        });

    testWidgets('a rebuilt card shows an unresolved payment and checks it',
        (tester) async {
      stubTopUp();
      stubStatus(
        const ApiResult.failure(
          error: RemoteException.serverError(
            503,
            ServerError(message: 'Payment could not yet be verified.'),
          ),
        ),
      );
      await cardAttempt(tester);
      await pumpCard(tester);

      expect(find.text('Pay Now'), findsNothing);
      expect(
        find.byKey(const Key('payment_request_check_status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('payment_request_progress_note')),
        findsOneWidget,
      );

      stubStatus(
        const ApiResult.success(
          data: PaymentReconciliation(status: 'successful', settled: false),
        ),
      );
      when(() => repo.payPaymentRequest(_kId))
          .thenAnswer((_) async => ApiResult.success(data: _paidResult()));

      await tester.tap(find.byKey(const Key('payment_request_check_status')));
      await _settle(tester);

      expect(find.byType(PaymentRequestMethodSheet), findsNothing);
      verify(() => repo.payPaymentRequest(_kId)).called(1);
      verify(() => repo.initializeWalletTopUp(amount: 300)).called(1);
      expect(find.text('Pay Now'), findsNothing);
      expect(
        find.byKey(const Key('payment_request_check_status')),
        findsNothing,
      );
      expect(snackText('Payment successful.'), findsOneWidget);
    });

    testWidgets('money in the wallet offers Retry Payment, not a new charge',
        (tester) async {
      stubTopUp();
      stubStatus(
        const ApiResult.success(
          data: PaymentReconciliation(status: 'successful', settled: true),
        ),
      );
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async =>
            const ApiResult.failure(error: RemoteException.timeoutError()),
      );
      await cardAttempt(tester);
      await pumpCard(tester);

      final retry = find.byKey(const Key('payment_request_retry_wallet'));
      expect(retry, findsOneWidget);
      expect(find.textContaining('in your wallet'), findsOneWidget);

      when(() => repo.payPaymentRequest(_kId))
          .thenAnswer((_) async => ApiResult.success(data: _paidResult()));
      await tester.tap(retry);
      await _settle(tester);

      expect(find.byType(PaymentRequestMethodSheet), findsNothing);
      verify(() => repo.payPaymentRequest(_kId)).called(2);
      verify(() => repo.initializeWalletTopUp(amount: 300)).called(1);
      expect(retry, findsNothing);
      expect(snackText('Payment successful.'), findsOneWidget);
    });

    testWidgets('a payment in progress survives a rebuild and ignores taps',
        (tester) async {
      final pending = Completer<ApiResult<PaymentRequestPayResult>>();
      when(() => repo.payPaymentRequest(_kId))
          .thenAnswer((_) => pending.future);
      await pumpCard(tester);

      unawaited(conversationsCubit.payFromWallet(_kId));
      await _settle(tester);
      expect(find.text('Completing your payment…'), findsOneWidget);

      // Rebuild the card from scratch: it must show the same progress.
      await tester.pumpWidget(const SizedBox());
      await pumpCard(tester, settle: false);
      await _settle(tester);
      expect(find.text('Completing your payment…'), findsOneWidget);

      // While busy the button shows a spinner and is disabled.
      final button = tester.widget<CustomButton>(find.byType(CustomButton));
      expect(button.isLoading, isTrue);
      expect(button.onPressed, isNull);
      await tester.tap(find.byType(CustomButton), warnIfMissed: false);
      await _settle(tester);
      expect(find.byType(PaymentRequestMethodSheet), findsNothing);
      verifyNever(repo.getWallet);

      pending.complete(ApiResult.success(data: _paidResult()));
      await _settle(tester);
      verify(() => repo.payPaymentRequest(_kId)).called(1);
      expect(find.text('Pay Now'), findsNothing);
    });
  });

  group('checkout closed with the X', () {
    // A stand-in for the Peach WebView dialog (whose plugin is unavailable
    // in tests) with the same top-left X: it pops the dialog with `false`.
    late List<String?> openedUrls;
    late Future<bool> Function(BuildContext, CheckoutPaymentData) original;

    setUp(() {
      openedUrls = [];
      original = PaymentRequestCard.openCheckout;
      PaymentRequestCard.openCheckout = (context, checkout) async {
        openedUrls.add(checkout.redirectUrl);
        final closed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                key: const Key('checkout_x'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ),
          ),
        );
        return closed ?? false;
      };
      TestWidgetsFlutterBinding.instance.platformDispatcher
          .textScaleFactorTestValue = 0.9;
    });

    tearDown(() {
      PaymentRequestCard.openCheckout = original;
      TestWidgetsFlutterBinding.instance.platformDispatcher
          .clearTextScaleFactorTestValue();
    });

    const checkout = CheckoutPaymentData(
      isInitialized: true,
      depositId: '88',
      redirectUrl: 'https://checkout.example.test/chk_88',
    );

    void stubTopUp() {
      when(() => repo.initializeWalletTopUp(amount: any(named: 'amount')))
          .thenAnswer((_) async => const ApiResult.success(data: checkout));
    }

    void stubStatus(ApiResult<PaymentReconciliation> answer) {
      when(() => repo.reconcilePeachPayment('88'))
          .thenAnswer((_) async => answer);
    }

    /// Pay Now → Card → (unavailable) → Add Funds by Card → checkout → X.
    Future<void> payByCardAndCloseWithX(WidgetTester tester) async {
      await pumpCard(tester);
      await tester.tap(find.text('Pay Now'));
      await _settle(tester);
      await chooseCardThenTopUpRoute(tester);
      expect(openedUrls, ['https://checkout.example.test/chk_88']);
      await tester.tap(find.byKey(const Key('checkout_x')));
      await _settle(tester);
    }

    void expectNotLoading() {
      for (final button
          in _buttonsIn(find.byType(CustomButton).evaluate())) {
        expect(button.isLoading, isFalse);
        expect(button.onPressed, isNotNull);
      }
    }

    testWidgets('pending: Check Payment Status, not a spinner',
        (tester) async {
      stubTopUp();
      stubStatus(
        const ApiResult.success(data: PaymentReconciliation(status: 'pending')),
      );

      await payByCardAndCloseWithX(tester);

      expect(
        find.byKey(const Key('payment_request_check_status')),
        findsOneWidget,
      );
      expectNotLoading();
      expect(
        conversationsCubit.paymentProgressFor(_kId).depositId,
        '88',
      );
      // Full request amount, one top-up only.
      verify(() => repo.initializeWalletTopUp(amount: 300)).called(1);
      verifyNever(() => repo.payPaymentRequest(any()));
    });

    testWidgets('unknown (503): Check Payment Status, deposit kept',
        (tester) async {
      stubTopUp();
      stubStatus(
        const ApiResult.failure(
          error: RemoteException.serverError(
            503,
            ServerError(message: 'Payment could not yet be verified.'),
          ),
        ),
      );

      await payByCardAndCloseWithX(tester);

      expect(
        find.byKey(const Key('payment_request_check_status')),
        findsOneWidget,
      );
      expectNotLoading();
      expect(
        conversationsCubit.paymentProgressFor(_kId).phase,
        PaymentRequestPaymentPhase.topUpUnknown,
      );

      // Tapping Pay Now's replacement checks; it never opens a checkout.
      await tester.tap(find.byKey(const Key('payment_request_check_status')));
      await _settle(tester);
      expect(openedUrls, hasLength(1));
      verify(() => repo.initializeWalletTopUp(amount: 300)).called(1);
    });

    testWidgets('successful: pays from the wallet and shows Paid',
        (tester) async {
      stubTopUp();
      stubStatus(
        const ApiResult.success(
          data: PaymentReconciliation(status: 'successful', settled: false),
        ),
      );
      when(() => repo.payPaymentRequest(_kId))
          .thenAnswer((_) async => ApiResult.success(data: _paidResult()));

      await payByCardAndCloseWithX(tester);

      verify(() => repo.payPaymentRequest(_kId)).called(1);
      expect(find.text('Pay Now'), findsNothing);
      expect(snackText('Payment successful.'), findsOneWidget);
    });

    testWidgets('failed: Pay Now is usable again', (tester) async {
      stubTopUp();
      stubStatus(
        const ApiResult.success(data: PaymentReconciliation(status: 'failed')),
      );

      await payByCardAndCloseWithX(tester);

      expect(find.text('Pay Now'), findsOneWidget);
      expectNotLoading();
      expect(
        snackText('Your card payment failed. You can try again.'),
        findsOneWidget,
      );
      expectLoadingCleared();
    });

    testWidgets('short wallet tops up exactly the backend shortfall',
        (tester) async {
      when(repo.getWallet).thenAnswer(
        (_) async => ApiResult.success(data: CustomerWallet(balance: 40)),
      );
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => const ApiResult.failure(
          error: RemoteException.serverError(
            400,
            ServerError(message: 'Insufficient wallet balance.'),
            code: 'insufficient_wallet_balance',
            responseBody: {
              'code': 'insufficient_wallet_balance',
              'wallet_balance': 40,
              'required_amount': 300,
              'shortfall': 260,
            },
          ),
        ),
      );
      stubTopUp();
      stubStatus(
        const ApiResult.success(data: PaymentReconciliation(status: 'pending')),
      );
      await pumpCard(tester);

      await tester.tap(find.text('Pay Now'));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('payment_method_wallet')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('payment_request_method_continue')));
      await _settle(tester);

      // The summary shows the backend's figures before anything is charged.
      expect(find.text('Proceed to Pay'), findsOneWidget);
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
      await tester.tap(find.text('Proceed to Pay'));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('checkout_x')));
      await _settle(tester);

      verify(() => repo.initializeWalletTopUp(amount: 260)).called(1);
    });

    testWidgets('declining the shortfall summary leaves Add / Retry',
        (tester) async {
      when(() => repo.payPaymentRequest(_kId)).thenAnswer(
        (_) async => const ApiResult.failure(
          error: RemoteException.serverError(
            400,
            ServerError(message: 'Insufficient wallet balance.'),
            code: 'insufficient_wallet_balance',
            responseBody: {'shortfall': 260, 'wallet_balance': 40},
          ),
        ),
      );
      await pumpCard(tester);

      await tester.tap(find.text('Pay Now'));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('payment_method_wallet')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('payment_request_method_continue')));
      await _settle(tester);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);

      expect(find.byKey(const Key('payment_request_add_funds')), findsOneWidget);
      expect(
        find.byKey(const Key('payment_request_retry_wallet')),
        findsOneWidget,
      );
      expect(find.textContaining('260.00'), findsWidgets);
      verifyNever(
        () => repo.initializeWalletTopUp(amount: any(named: 'amount')),
      );
    });
  });
}
