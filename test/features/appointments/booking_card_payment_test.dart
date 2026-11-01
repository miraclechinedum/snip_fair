import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

const _kDeposit = '41';

const _checkout = CheckoutPaymentData(
  appointmentId: '9',
  isInitialized: true,
  depositId: _kDeposit,
  checkoutId: 'chk_41',
  redirectUrl: 'https://checkout.example.test/chk_41',
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
    ).thenAnswer((_) async => const ApiResult.success(data: _checkout));
  });

  tearDown(() => cubit.close());

  void stubStatus(ApiResult<PaymentReconciliation> answer) {
    when(() => repo.reconcilePeachPayment(_kDeposit))
        .thenAnswer((_) async => answer);
  }

  int checkoutsStarted() => verify(
        () => repo.createAppointmentWithCard(
          portfolioId: any(named: 'portfolioId'),
          date: any(named: 'date'),
          time: any(named: 'time'),
          note: any(named: 'note'),
          address: any(named: 'address'),
        ),
      ).callCount;

  /// The booking cubit formats the time with the widget tree's
  /// MaterialLocalizations, so it needs a real BuildContext.
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

  /// Starts a card checkout and closes it, as the booking screen does.
  Future<void> cardAttempt(WidgetTester tester) => tester.runAsync(() async {
        await cubit.initializeCardPayment();
        await cubit.onCardCheckoutClosed();
      });

  for (final status in ['failed', 'cancelled']) {
    testWidgets('a $status card attempt can be retried (B2)', (tester) async {
      await prepareBooking(tester);
      stubStatus(
        ApiResult.success(data: PaymentReconciliation(status: status)),
      );

      await cardAttempt(tester);

      expect(
        cubit.state.cardPaymentPhase,
        status == 'failed' ? CardPaymentPhase.failed : CardPaymentPhase.cancelled,
      );
      expect(cubit.state.activeCardCheckout, isNull);
      expect(cubit.state.hasUnresolvedCardPayment, isFalse);
      expect(checkoutsStarted(), 1);

      // Before the fix this silently did nothing.
      await tester.runAsync(cubit.initializeCardPayment);
      expect(checkoutsStarted(), 1);
      expect(cubit.state.cardPaymentPhase, CardPaymentPhase.checkoutOpen);
      expect(cubit.state.activeCardCheckout?.depositId, _kDeposit);
    });
  }

  testWidgets('an unknown card attempt blocks an unsafe retry',
      (tester) async {
    await prepareBooking(tester);
    stubStatus(
      const ApiResult.failure(
        error: RemoteException.serverError(
          503,
          ServerError(message: 'Payment could not yet be verified.'),
        ),
      ),
    );

    await cardAttempt(tester);

    expect(cubit.state.cardPaymentPhase, CardPaymentPhase.unknown);
    expect(cubit.state.activeCardCheckout?.depositId, _kDeposit);
    // Book and Book Again are both disabled by this flag.
    expect(cubit.state.hasUnresolvedCardPayment, isTrue);

    await tester.runAsync(cubit.initializeCardPayment);
    expect(checkoutsStarted(), 1);
  });

  testWidgets('a pending card attempt also blocks a retry', (tester) async {
    await prepareBooking(tester);
    stubStatus(
      const ApiResult.success(data: PaymentReconciliation(status: 'pending')),
    );

    await cardAttempt(tester);

    expect(cubit.state.cardPaymentPhase, CardPaymentPhase.pending);
    expect(cubit.state.hasUnresolvedCardPayment, isTrue);
    await tester.runAsync(cubit.initializeCardPayment);
    expect(checkoutsStarted(), 1);
  });

  testWidgets('booking keeps its settled success rule', (tester) async {
    await prepareBooking(tester);
    // successful but not settled by this call: booking still reports pending,
    // exactly as before the shared reconciler was introduced.
    stubStatus(
      const ApiResult.success(
        data: PaymentReconciliation(status: 'successful', settled: false),
      ),
    );

    await cardAttempt(tester);

    expect(cubit.state.cardPaymentPhase, CardPaymentPhase.pending);
    verify(() => repo.reconcilePeachPayment(_kDeposit)).called(3);
  });

  testWidgets('Check Payment Status resolves an unknown attempt',
      (tester) async {
    await prepareBooking(tester);
    stubStatus(
      const ApiResult.failure(
        error: RemoteException.serverError(
          503,
          ServerError(message: 'Payment could not yet be verified.'),
        ),
      ),
    );
    await cardAttempt(tester);
    stubStatus(
      const ApiResult.success(data: PaymentReconciliation(status: 'failed')),
    );

    await tester.runAsync(() => cubit.reconcileCardPayment(automatic: false));

    expect(cubit.state.cardPaymentPhase, CardPaymentPhase.failed);
    expect(cubit.state.hasUnresolvedCardPayment, isFalse);
    expect(cubit.state.activeCardCheckout, isNull);
  });
}
