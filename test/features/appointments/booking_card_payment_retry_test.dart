import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/widgets/appointment_card_payment_notice.dart';

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

const _kFirstDeposit = '41';
const _kRetryDeposit = '42';
const _kAppointment = '9';

const _firstCheckout = CheckoutPaymentData(
  appointmentId: _kAppointment,
  isInitialized: true,
  depositId: _kFirstDeposit,
  checkoutId: 'chk_41',
  redirectUrl: 'https://checkout.example.test/chk_41',
);

const _retryCheckout = CheckoutPaymentData(
  appointmentId: _kAppointment,
  isInitialized: true,
  depositId: _kRetryDeposit,
  checkoutId: 'chk_42',
  redirectUrl: 'https://checkout.example.test/chk_42',
);

PaymentReconciliation _status(
  String status, {
  bool? canRetry,
  bool? settled,
  String? appointmentStatus,
}) =>
    PaymentReconciliation(
      depositId: _kFirstDeposit,
      purpose: 'appointment',
      status: status,
      settled: settled ?? false,
      appointmentId: _kAppointment,
      appointmentStatus: appointmentStatus ?? 'processing',
      canRetry: canRetry,
    );

ApiResult<T> _refused<T>(int status, String code) => ApiResult.failure(
      error: RemoteException.serverError(
        status,
        ServerError(message: code),
        responseBody: {'code': code, 'message': code},
      ),
    );

void main() {
  late _MockAppointmentRepository repo;
  late UpdateCreateAppointmentCubit cubit;

  setUp(() {
    UpdateCreateAppointmentCubit.cardReconcileRetryGap = Duration.zero;
    repo = _MockAppointmentRepository();
    cubit = UpdateCreateAppointmentCubit(repo);

    when(() => repo.customerFetchPortfolioById(id: any(named: 'id')))
        .thenAnswer(
      (_) async => ApiResult.success(
        data: SellerPortfolio(id: 3, userId: '8', price: 300),
      ),
    );
    when(() => repo.customerFetchStylistById(any())).thenAnswer(
      (_) async => ApiResult.failure(error: RemoteException.httpError(500)),
    );
    when(
      () => repo.createAppointmentWithCard(
        portfolioId: any(named: 'portfolioId'),
        date: any(named: 'date'),
        time: any(named: 'time'),
        note: any(named: 'note'),
        address: any(named: 'address'),
      ),
    ).thenAnswer((_) async => const ApiResult.success(data: _firstCheckout));
    when(() => repo.retryAppointmentCardPayment(_kAppointment))
        .thenAnswer((_) async => const ApiResult.success(data: _retryCheckout));
    when(() => repo.getCustomerAppointmentById(any())).thenAnswer(
      (_) async => ApiResult.failure(error: RemoteException.httpError(500)),
    );
  });

  tearDown(() => cubit.close());

  void statusOf(String deposit, ApiResult<PaymentReconciliation> answer) {
    when(() => repo.reconcilePeachPayment(deposit))
        .thenAnswer((_) async => answer);
  }

  void noBookingCreated() => verifyNever(
        () => repo.createAppointmentWithCard(
          portfolioId: any(named: 'portfolioId'),
          date: any(named: 'date'),
          time: any(named: 'time'),
          note: any(named: 'note'),
          address: any(named: 'address'),
        ),
      );

  int bookingsCreated() => verify(
        () => repo.createAppointmentWithCard(
          portfolioId: any(named: 'portfolioId'),
          date: any(named: 'date'),
          time: any(named: 'time'),
          note: any(named: 'note'),
          address: any(named: 'address'),
        ),
      ).callCount;

  Future<void> prepareBooking(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            cubit.context = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.runAsync(() => cubit.fetchPortfolioById('3'));
    cubit
      ..setPaymentMethod('card')
      ..onSelectDate(DateTime(2026, 11, 20))
      ..onSelectTime(const TimeOfDay(hour: 10, minute: 0));
  }

  /// Books by card, then the customer leaves checkout (cancel or close).
  Future<void> bookAndReturn(WidgetTester tester) => tester.runAsync(() async {
        await cubit.initializeCardPayment();
        await cubit.onCardCheckoutClosed();
      });

  group('confirmed cancellation or failure', () {
    for (final status in ['cancelled', 'failed']) {
      testWidgets('a $status payment retries the SAME booking', (tester) async {
        await prepareBooking(tester);
        statusOf(
          _kFirstDeposit,
          ApiResult.success(data: _status(status, canRetry: true)),
        );

        await bookAndReturn(tester);

        expect(
          cubit.state.cardPaymentPhase,
          status == 'cancelled'
              ? CardPaymentPhase.cancelled
              : CardPaymentPhase.failed,
        );
        expect(cubit.state.retryAppointmentId, _kAppointment);
        expect(cubit.state.hasUnresolvedCardPayment, isFalse);
        expect(bookingsCreated(), 1);

        // "Retry Payment": a new attempt for booking 9, never a new booking.
        await tester.runAsync(cubit.initializeCardPayment);

        verify(() => repo.retryAppointmentCardPayment(_kAppointment))
            .called(1);
        verifyNever(
          () => repo.createAppointmentWithCard(
            portfolioId: any(named: 'portfolioId'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            note: any(named: 'note'),
            address: any(named: 'address'),
          ),
        );
        expect(cubit.state.cardPaymentPhase, CardPaymentPhase.checkoutOpen);
        expect(cubit.state.activeCardCheckout?.depositId, _kRetryDeposit);
      });
    }

    testWidgets('the retried payment succeeding clears the retry',
        (tester) async {
      await prepareBooking(tester);
      statusOf(
        _kFirstDeposit,
        ApiResult.success(data: _status('cancelled', canRetry: true)),
      );
      await bookAndReturn(tester);
      statusOf(
        _kRetryDeposit,
        ApiResult.success(
          data: _status('successful', settled: true, appointmentStatus: 'pending'),
        ),
      );

      await bookAndReturn(tester);

      expect(cubit.state.cardPaymentPhase, CardPaymentPhase.successful);
      expect(cubit.state.retryAppointmentId, isNull);
    });

    testWidgets('without can_retry (older server) nothing is retried',
        (tester) async {
      await prepareBooking(tester);
      statusOf(
        _kFirstDeposit,
        ApiResult.success(data: _status('cancelled')),
      );

      await bookAndReturn(tester);

      expect(cubit.state.cardPaymentPhase, CardPaymentPhase.cancelled);
      expect(cubit.state.retryAppointmentId, isNull);
    });

    for (final code in [
      'APPOINTMENT_ALREADY_PAID',
      'APPOINTMENT_EXPIRED',
      'APPOINTMENT_NOT_PAYABLE',
    ]) {
      testWidgets('a retry refused with $code stops retrying that booking',
          (tester) async {
        await prepareBooking(tester);
        statusOf(
          _kFirstDeposit,
          ApiResult.success(data: _status('failed', canRetry: true)),
        );
        await bookAndReturn(tester);
        when(() => repo.retryAppointmentCardPayment(_kAppointment))
            .thenAnswer((_) async => _refused(409, code));

        await tester.runAsync(cubit.initializeCardPayment);

        expect(cubit.state.cardPaymentPhase, CardPaymentPhase.failed);
        expect(cubit.state.retryAppointmentId, isNull);
      });
    }

    testWidgets('a retry refused as PAYMENT_IN_PROGRESS keeps the booking',
        (tester) async {
      await prepareBooking(tester);
      statusOf(
        _kFirstDeposit,
        ApiResult.success(data: _status('failed', canRetry: true)),
      );
      await bookAndReturn(tester);
      when(() => repo.retryAppointmentCardPayment(_kAppointment))
          .thenAnswer((_) async => _refused(409, 'PAYMENT_IN_PROGRESS'));

      await tester.runAsync(cubit.initializeCardPayment);

      expect(cubit.state.retryAppointmentId, _kAppointment);
      expect(bookingsCreated(), 1, reason: 'never a second booking');
    });
  });

  group('not confirmed', () {
    testWidgets('pending keeps the attempt and never retries', (tester) async {
      await prepareBooking(tester);
      statusOf(
        _kFirstDeposit,
        ApiResult.success(data: _status('pending')),
      );

      await bookAndReturn(tester);

      expect(cubit.state.cardPaymentPhase, CardPaymentPhase.pending);
      expect(cubit.state.hasUnresolvedCardPayment, isTrue);
      expect(cubit.state.retryAppointmentId, isNull);
      await tester.runAsync(cubit.initializeCardPayment);
      verifyNever(() => repo.retryAppointmentCardPayment(any()));
    });

    for (final (label, error) in [
      (
        '503 unknown',
        const RemoteException.serverError(
          503,
          ServerError(message: 'unknown'),
          responseBody: {'status': 'unknown'},
        ),
      ),
      ('timeout', const RemoteException.timeoutError()),
      ('no internet', const RemoteException.noInternetError()),
    ]) {
      testWidgets('$label is never treated as cancelled or paid',
          (tester) async {
        await prepareBooking(tester);
        statusOf(_kFirstDeposit, ApiResult.failure(error: error));

        await bookAndReturn(tester);

        expect(cubit.state.cardPaymentPhase, CardPaymentPhase.unknown);
        expect(
          cubit.state.cardVerificationState.error,
          UpdateCreateAppointmentCubit.paymentUnconfirmedMessage,
        );
        expect(cubit.state.activeCardCheckout?.depositId, _kFirstDeposit);
        expect(cubit.state.hasUnresolvedCardPayment, isTrue);
        expect(cubit.state.retryAppointmentId, isNull);
        verify(() => repo.reconcilePeachPayment(_kFirstDeposit)).called(3);
      });
    }

    testWidgets(
        'paid by the webhook or the return first: verified, not pending',
        (tester) async {
      await prepareBooking(tester);
      // This call did not settle it, but the booking is already paid.
      statusOf(
        _kFirstDeposit,
        ApiResult.success(
          data: _status('successful', appointmentStatus: 'pending'),
        ),
      );

      await bookAndReturn(tester);

      expect(cubit.state.cardPaymentPhase, CardPaymentPhase.successful);
    });

    testWidgets('a manual review is never shown as paid', (tester) async {
      await prepareBooking(tester);
      statusOf(
        _kFirstDeposit,
        ApiResult.success(data: _status('manual_review')),
      );

      await bookAndReturn(tester);

      expect(cubit.state.cardPaymentPhase, CardPaymentPhase.pending);
    });
  });

  group('an opened booking', () {
    testWidgets('Check Payment Status checks its latest attempt only',
        (tester) async {
      await prepareBooking(tester);
      statusOf(
        _kFirstDeposit,
        ApiResult.success(data: _status('cancelled', canRetry: true)),
      );

      await tester.runAsync(
        () => cubit.checkAppointmentPayment(
          appointmentId: _kAppointment,
          depositId: _kFirstDeposit,
        ),
      );

      verify(() => repo.reconcilePeachPayment(_kFirstDeposit)).called(1);
      expect(cubit.state.cardPaymentPhase, CardPaymentPhase.cancelled);
      expect(cubit.state.retryAppointmentId, _kAppointment);
      verifyNever(() => repo.retryAppointmentCardPayment(any()));
      noBookingCreated();
    });

    testWidgets('Retry Payment pays the opened booking again',
        (tester) async {
      await prepareBooking(tester);

      await tester.runAsync(() => cubit.retryAppointmentPayment(_kAppointment));

      verify(() => repo.retryAppointmentCardPayment(_kAppointment)).called(1);
      expect(cubit.state.activeCardCheckout?.depositId, _kRetryDeposit);
      noBookingCreated();
    });
  });

  group('wording', () {
    test('messages say what happened and never claim payment', () {
      String message(CardPaymentPhase phase, {bool canRetry = false}) =>
          UpdateCreateAppointmentCubit.cardPaymentMessage(
            phase,
            canRetry: canRetry,
          );

      expect(
        message(CardPaymentPhase.cancelled, canRetry: true),
        'Payment was cancelled. Your appointment has not been paid. '
        'You can retry the payment.',
      );
      expect(
        message(CardPaymentPhase.failed),
        'Payment failed. Your appointment has not been paid.',
      );
      expect(
        message(CardPaymentPhase.pending),
        'Peach has not confirmed your payment yet. Please check again '
        'shortly.',
      );
      expect(
        message(CardPaymentPhase.unknown),
        "We couldn't confirm your payment status yet. Your payment has not "
        'been confirmed. Please check again shortly.',
      );
    });

    test('Laravel payloads parse', () {
      final reconciliation = PaymentReconciliation.fromJson({
        'status': 'cancelled',
        'settled': false,
        'appointment_status': 'processing',
        'can_retry': true,
      });
      expect(reconciliation.canRetry, isTrue);
      expect(reconciliation.appointmentStatus, 'processing');
      expect(reconciliation.isSuccessful, isFalse);
      // An older server sends neither field.
      expect(
        PaymentReconciliation.fromJson({'status': 'successful', 'settled': false})
            .isSuccessful,
        isFalse,
      );

      final appointment = CustomerAppointment.fromJson({
        'id': 9,
        'status': 'processing',
        'card_payment': {
          'status': 'cancelled',
          'deposit_id': '41',
          'can_retry': true,
          'message': 'Payment was cancelled. This appointment has not been paid.',
        },
      });
      expect(appointment.cardPayment!.statusLabel, 'Payment cancelled');
      expect(appointment.cardPayment!.canRetry, isTrue);
      expect(appointment.cardPayment!.depositId, '41');
      expect(
        CustomerAppointment.fromJson({'id': 1, 'status': 'pending'}).cardPayment,
        isNull,
      );
      expect(
        AppointmentCardPayment.tryParse({'status': 'awaiting_confirmation'})!
            .statusLabel,
        'Awaiting payment confirmation',
      );
      expect(
        AppointmentCardPayment.tryParse({'status': 'failed'})!.statusLabel,
        'Payment failed',
      );
    });
  });

  group('payment notice', () {
    Future<void> pumpNotice(
      WidgetTester tester,
      AppointmentCardPayment payment, {
      VoidCallback? onRetry,
      VoidCallback? onCheck,
    }) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: AppointmentCardPaymentNotice(
                payment: payment,
                isBusy: false,
                onRetry: onRetry ?? () {},
                onCheckStatus: onCheck ?? () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a cancelled payment offers Retry Payment', (tester) async {
      var retried = 0;
      await pumpNotice(
        tester,
        const AppointmentCardPayment(
          status: 'cancelled',
          depositId: '41',
          canRetry: true,
          message: 'Payment was cancelled. This appointment has not been paid.',
        ),
        onRetry: () => retried++,
      );

      expect(find.text('Payment cancelled'), findsOneWidget);
      expect(
        find.text('Payment was cancelled. This appointment has not been paid.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry Payment'));
      expect(retried, 1);
      expect(find.text('Check Payment Status'), findsNothing);
    });

    testWidgets('an unconfirmed payment offers Check Payment Status only',
        (tester) async {
      var checked = 0;
      await pumpNotice(
        tester,
        const AppointmentCardPayment(
          status: 'awaiting_confirmation',
          depositId: '41',
        ),
        onCheck: () => checked++,
      );

      expect(find.text('Awaiting payment confirmation'), findsOneWidget);
      expect(find.text('Retry Payment'), findsNothing);
      await tester.tap(find.text('Check Payment Status'));
      expect(checked, 1);
    });

    testWidgets('a cancelled payment that cannot be retried offers nothing',
        (tester) async {
      await pumpNotice(
        tester,
        const AppointmentCardPayment(status: 'cancelled', depositId: '41'),
      );

      expect(find.text('Retry Payment'), findsNothing);
      expect(find.text('Check Payment Status'), findsNothing);
    });
  });
}
