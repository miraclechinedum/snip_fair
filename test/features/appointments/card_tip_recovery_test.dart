import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/appointments/customer_appointments/cubit/customer_appointments_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/data/card_tip_attempt_store.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/data/card_tip_recovery.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/widgets/tip_payment.dart';

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

class _MockProfileCubit extends MockCubit<CustomerProfileMgtState>
    implements CustomerProfileMgtCubit {}

class _MockAppointmentsCubit extends MockCubit<CustomerAppointmentsState>
    implements CustomerAppointmentsCubit {}

const _customerA = '501';
const _customerB = '502';
const _kAppointment = '77';
const _kDeposit = '123';

CardTipAttempt _attempt({
  String appointmentId = _kAppointment,
  String depositId = _kDeposit,
  DateTime? createdAt,
}) =>
    CardTipAttempt(
      appointmentId: appointmentId,
      depositId: depositId,
      checkoutId: 'chk_$depositId',
      amount: 30,
      createdAt: createdAt ?? DateTime(2026, 11, 10, 11),
    );

ApiResult<PaymentReconciliation> _tip(String tipStatus) => ApiResult.success(
      data: PaymentReconciliation.fromJson({
        'deposit_id': _kDeposit,
        'purpose': 'tip',
        'status': tipStatus == 'pending' ? 'pending' : 'successful',
        'settled': tipStatus == 'tipped',
        'transaction_reference': 'TIP-TOPUP-77-abc',
        'amount': 30,
        'currency': 'ZAR',
        'message': 'Laravel says $tipStatus.',
        'tip': {
          'appointment_id': _kAppointment,
          'amount': 30,
          'status': tipStatus,
        },
      }),
    );

ApiResult<PaymentReconciliation> _failure(RemoteException error) =>
    ApiResult.failure(error: error);

final _http503 = RemoteException.serverError(
  503,
  const ServerError(message: 'Payment could not yet be verified.'),
  responseBody: const {'status': 'unknown'},
);

void main() {
  late _MockAppointmentRepository repo;
  late MemoryCardTipAttemptStore store;
  late CardTipRecovery recovery;
  late List<FutureOr<ApiResult<PaymentReconciliation>> Function()> statuses;
  late List<CardTipCheck> events;
  late StreamSubscription<CardTipCheck> eventSub;

  int statusCalls() {
    try {
      return verify(() => repo.reconcilePeachPayment(_kDeposit)).callCount;
    } on TestFailure {
      return 0;
    }
  }

  setUp(() {
    CardTipRecovery.clock = () => DateTime(2026, 11, 10, 12);
    UpdateCreateAppointmentCubit.tipReconcileRetryGap = Duration.zero;
    repo = _MockAppointmentRepository();
    store = MemoryCardTipAttemptStore();
    recovery = CardTipRecovery(repo, store: store);
    statuses = [];
    events = [];
    eventSub = recovery.events.listen(events.add);
    when(() => repo.reconcilePeachPayment(any())).thenAnswer(
      (_) async =>
          statuses.length > 1 ? statuses.removeAt(0)() : statuses.first(),
    );
  });

  tearDown(() async {
    await eventSub.cancel();
    await recovery.dispose();
    CardTipRecovery.clock = DateTime.now;
  });

  /// A previous run left [attempt] saved; the app restarts as [owner].
  Future<CardTipRecovery> restartWith(
    CardTipAttempt attempt, {
    String owner = _customerA,
  }) async {
    await store.save(owner, [attempt]);
    final restarted = CardTipRecovery(repo, store: store);
    addTearDown(restarted.dispose);
    restarted.events.listen(events.add);
    return restarted;
  }

  group('restore after an app restart', () {
    test('2/3. restored, then checked once through Laravel', () async {
      final restarted = await restartWith(_attempt());
      statuses.add(() => _tip('pending'));

      await restarted.restore(ownerId: _customerA);

      verify(() => repo.reconcilePeachPayment(_kDeposit)).called(1);
      expect(restarted.unresolvedFor(_kAppointment)?.depositId, _kDeposit);
      final saved = store.load(_customerA).single;
      expect(saved.lastStatus, CardTipAttempt.statusPending);
      expect(saved.reference, 'TIP-TOPUP-77-abc');
      expect(events.single.verdict, CardTipVerdict.pending);
      expect(events.single.source, isNull, reason: 'app-level recovery');
    });

    test('4/11. tipped: completed and removed from the queue', () async {
      final restarted = await restartWith(_attempt());
      statuses.add(() => _tip('tipped'));

      await restarted.restore(ownerId: _customerA);

      expect(events.single.verdict, CardTipVerdict.tipped);
      expect(events.single.amount, 30);
      expect(restarted.unresolvedFor(_kAppointment), isNull);
      expect(store.load(_customerA), isEmpty);
    });

    test('5. credited_to_wallet: completed, never reported as tipped',
        () async {
      final restarted = await restartWith(_attempt());
      statuses.add(() => _tip('credited_to_wallet'));

      await restarted.restore(ownerId: _customerA);

      expect(events.single.verdict, CardTipVerdict.creditedToWallet);
      expect(store.load(_customerA), isEmpty);
    });

    test('6. not_paid: terminal and removed', () async {
      final restarted = await restartWith(_attempt());
      statuses.add(() => _tip('not_paid'));

      await restarted.restore(ownerId: _customerA);

      expect(events.single.verdict, CardTipVerdict.notPaid);
      expect(store.load(_customerA), isEmpty);
    });

    test('7. HTTP 503 keeps the attempt, saved and unresolved', () async {
      final restarted = await restartWith(_attempt());
      statuses.add(() => _failure(_http503));

      await restarted.restore(ownerId: _customerA);

      expect(events.single.verdict, CardTipVerdict.unknown);
      expect(restarted.unresolvedFor(_kAppointment), isNotNull);
      expect(
        store.load(_customerA).single.lastStatus,
        CardTipAttempt.statusUnknown,
      );
    });

    for (final (name, error) in [
      ('no connection', const RemoteException.noInternetError()),
      ('timeout', const RemoteException.timeoutError()),
      ('expired session (401)', RemoteException.httpError(401)),
    ]) {
      test('8. $name keeps the attempt', () async {
        final restarted = await restartWith(_attempt());
        statuses.add(() => _failure(error));

        await restarted.restore(ownerId: _customerA);

        expect(events.single.verdict, CardTipVerdict.unknown);
        expect(store.load(_customerA), hasLength(1));
      });
    }

    test('9. an unknown tip.status fails closed: still unresolved', () async {
      final restarted = await restartWith(_attempt());
      statuses.add(() => _tip('refunded'));

      await restarted.restore(ownerId: _customerA);

      expect(events.single.verdict, CardTipVerdict.pending);
      expect(store.load(_customerA), hasLength(1));
    });

    test('a deposit-level "successful" alone is not a tip', () async {
      final restarted = await restartWith(_attempt());
      statuses.add(
        () => ApiResult.success(
          data: PaymentReconciliation.fromJson(const {
            'deposit_id': _kDeposit,
            'purpose': 'tip',
            'status': 'successful',
            'settled': true,
          }),
        ),
      );

      await restarted.restore(ownerId: _customerA);

      expect(events.single.verdict, CardTipVerdict.pending);
      expect(store.load(_customerA), hasLength(1));
    });

    test('attempts older than a week are not checked', () async {
      final restarted = await restartWith(
        _attempt(createdAt: DateTime(2026, 11, 1)),
      );

      await restarted.restore(ownerId: _customerA);

      expect(statusCalls(), 0);
      expect(store.load(_customerA), isEmpty);
    });

    test('15. back from the background: checked again, then resolved',
        () async {
      final restarted = await restartWith(_attempt());
      statuses
        ..add(() => _tip('pending'))
        ..add(() => _tip('tipped'));

      await restarted.restore(ownerId: _customerA); // start-up
      expect(restarted.unresolvedFor(_kAppointment), isNotNull);
      // Laravel settled it (e.g. the webhook) while the app was away.
      await restarted.restore(ownerId: _customerA); // resume

      expect(statusCalls(), 2);
      expect(events.map((e) => e.verdict), [
        CardTipVerdict.pending,
        CardTipVerdict.tipped,
      ]);
      expect(store.load(_customerA), isEmpty);
    });
  });

  test('16. concurrent checks of one deposit share one request', () async {
    await recovery.restore(ownerId: _customerA);
    await recovery.record(_attempt());
    final gate = Completer<ApiResult<PaymentReconciliation>>();
    statuses.add(() => gate.future);

    final first = recovery.check(_kAppointment);
    final second = recovery.check(_kAppointment);
    final third = recovery.recheckAll();
    gate.complete(_tip('tipped'));
    await Future.wait([first, second, third]);

    expect(statusCalls(), 1);
    expect(identical(await first, await second), isTrue);
  });

  group('customers', () {
    test('12. one customer never sees another\'s attempts', () async {
      await store.save(_customerA, [_attempt()]);
      final asB = CardTipRecovery(repo, store: store);
      addTearDown(asB.dispose);

      await asB.restore(ownerId: _customerB);

      expect(asB.unresolved, isEmpty);
      expect(statusCalls(), 0);
      await asB.record(_attempt(appointmentId: '88', depositId: '456'));
      expect(store.load(_customerB).single.appointmentId, '88');
      expect(store.load(_customerA).single.appointmentId, _kAppointment);
    });

    test('13. logout, then login: only the signed-in customer\'s attempts',
        () async {
      await store.save(_customerA, [_attempt()]);
      await store.save(
        _customerB,
        [_attempt(appointmentId: '88', depositId: '456')],
      );
      statuses.add(() => _tip('pending'));
      when(() => repo.reconcilePeachPayment('456'))
          .thenAnswer((_) async => _tip('pending'));

      await recovery.restore(ownerId: _customerA);
      expect(recovery.unresolved.map((a) => a.appointmentId), [_kAppointment]);

      recovery.onLogout();
      expect(recovery.unresolved, isEmpty);
      expect(recovery.ownerId, isNull);
      expect(store.load(_customerA), hasLength(1), reason: 'not deleted');

      await recovery.restore(ownerId: _customerB);
      expect(recovery.unresolved.map((a) => a.appointmentId), ['88']);

      recovery.onLogout();
      await recovery.restore(ownerId: _customerA);
      expect(recovery.unresolved.map((a) => a.appointmentId), [_kAppointment]);
    });

    test('the device store ignores a record carrying another owner', () async {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({
        LocalCardTipAttemptStore.keyFor(_customerA): jsonEncode([
          _attempt().toJson(_customerB),
          _attempt(appointmentId: '88').toJson(_customerA),
        ]),
      });
      getIt
        ..allowReassignment = true
        ..registerSingleton<LocalKeyStorage>(
          LocalKeyStorage(await SharedPreferences.getInstance()),
        );
      addTearDown(getIt.reset);

      final loaded = const LocalCardTipAttemptStore().load(_customerA);

      expect(loaded.map((a) => a.appointmentId), ['88']);
    });

    test('saved records hold no checkout URL or card data', () {
      final json = jsonEncode(_attempt().toJson(_customerA));
      expect(json, isNot(contains('http')));
      expect(json, isNot(contains('redirect')));
      expect(
        jsonDecode(json),
        allOf(
          containsPair('deposit_id', _kDeposit),
          containsPair('checkout_id', 'chk_123'),
          containsPair('owner_id', _customerA),
        ),
      );
    });

    test('logout (clearData) keeps saved card tips under their owner key',
        () async {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({
        SharedPrefKey.accessToken: 'token',
        LocalCardTipAttemptStore.keyFor(_customerA): '[]',
      });
      final prefs = await SharedPreferences.getInstance();

      await LocalKeyStorage(prefs).clearData();

      expect(prefs.getString(SharedPrefKey.accessToken), isNull);
      expect(
        prefs.getString(LocalCardTipAttemptStore.keyFor(_customerA)),
        '[]',
      );
    });
  });

  group('booking screen', () {
    late UpdateCreateAppointmentCubit cubit;

    setUp(() async {
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
      cubit = UpdateCreateAppointmentCubit(repo, tipRecovery: recovery);
    });

    tearDown(() => cubit.close());

    int tipRequests() {
      try {
        return verify(
          () => repo.tipCustomerAppointment(
            any(),
            amount: any(named: 'amount'),
            paymentMethod: any(named: 'paymentMethod'),
          ),
        ).callCount;
      } on TestFailure {
        return 0;
      }
    }

    test('1. the attempt is saved before the checkout is handed out', () async {
      await recovery.restore(ownerId: _customerA);
      await cubit.fetchAppointmentById(_kAppointment);
      when(
        () => repo.tipCustomerAppointment(
          _kAppointment,
          amount: any(named: 'amount'),
          paymentMethod: 'card',
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(
          data: TipResponse.fromJson(const {
            'success': true,
            'code': 'checkout_started',
            'status': 'pending',
            'payment_method': 'card',
            'tip_amount': 30,
            'payment': {
              'deposit_id': _kDeposit,
              'checkout_id': 'chk_123',
              'redirect_url': 'https://checkout.example.test/chk_123',
            },
          }),
        ),
      );

      final result = await cubit.startTip(30, paymentMethod: 'card');

      expect(result, TipStartResult.checkoutStarted);
      final saved = store.load(_customerA).single;
      expect(saved.depositId, _kDeposit);
      expect(saved.checkoutId, 'chk_123');
      expect(saved.appointmentId, _kAppointment);
      expect(saved.lastStatus, CardTipAttempt.statusCheckoutStarted);
      expect(statusCalls(), 0, reason: 'nothing checked before checkout');
    });

    test('opening the booking recovers its saved tip and asks Laravel',
        () async {
      await store.save(_customerA, [_attempt()]);
      final restarted = CardTipRecovery(repo, store: store);
      addTearDown(restarted.dispose);
      statuses
        ..add(() => _tip('pending')) // start-up recovery
        ..add(() => _tip('tipped')); // booking opened
      await restarted.restore(ownerId: _customerA);
      final booking =
          UpdateCreateAppointmentCubit(repo, tipRecovery: restarted);
      addTearDown(booking.close);

      await booking.fetchAppointmentById(_kAppointment);
      await Future<void>.delayed(Duration.zero);

      expect(statusCalls(), 2);
      expect(booking.state.tipPayment.phase, TipPaymentPhase.tipped);
      expect(restarted.unresolvedFor(_kAppointment), isNull);
    });

    test('10. no new tip while a saved card tip is unresolved', () async {
      await store.save(_customerA, [_attempt()]);
      final restarted = CardTipRecovery(repo, store: store);
      addTearDown(restarted.dispose);
      statuses.add(() => _tip('pending'));
      await restarted.restore(ownerId: _customerA);
      final booking =
          UpdateCreateAppointmentCubit(repo, tipRecovery: restarted);
      addTearDown(booking.close);
      await booking.fetchAppointmentById(_kAppointment);
      await Future<void>.delayed(Duration.zero);

      expect(booking.hasUnresolvedCardTip, isTrue);
      expect(booking.state.tipPayment.phase, TipPaymentPhase.pending);
      for (final method in ['card', 'wallet']) {
        expect(
          await booking.startTip(30, paymentMethod: method),
          TipStartResult.unresolved,
        );
      }
      expect(tipRequests(), 0, reason: 'no second checkout or tip');
    });

    test('an app-level outcome updates an open booking, unannounced', () async {
      await recovery.restore(ownerId: _customerA);
      await cubit.fetchAppointmentById(_kAppointment);
      await recovery.record(_attempt());
      statuses.add(() => _tip('tipped'));

      await recovery.recheckAll(); // e.g. on resume
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.tipPayment.phase, TipPaymentPhase.tipped);
      expect(cubit.state.tipPayment.announced, isTrue);
    });
  });

  group('UI', () {
    Future<void> pumpHost(
      WidgetTester tester, {
      required Widget Function(BuildContext) child,
      CustomerProfileMgtCubit? profile,
      CustomerAppointmentsCubit? appointments,
    }) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 1200 * 3)
        ..devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains('overflowed')) {
          original?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = original);
      final p = profile ?? _MockProfileCubit();
      final a = appointments ?? _MockAppointmentsCubit();
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MultiBlocProvider(
            providers: [
              BlocProvider<CustomerProfileMgtCubit>.value(value: p),
              BlocProvider<CustomerAppointmentsCubit>.value(value: a),
            ],
            child: MaterialApp(
              home: Scaffold(body: Builder(builder: child)),
            ),
          ),
        ),
      );
    }

    testWidgets('a recovered tip refreshes the app\'s own wallet cubit',
        (tester) async {
      final profile = _MockProfileCubit();
      final appointments = _MockAppointmentsCubit();
      when(() => profile.getWallet(any())).thenAnswer((_) async {});
      when(() => profile.getWalletTransactions()).thenAnswer((_) async {});
      when(() => appointments.getAppointments()).thenAnswer((_) async {});

      await pumpHost(
        tester,
        profile: profile,
        appointments: appointments,
        child: (context) => TextButton(
          onPressed: () => TipOutcomePresenter.present(
            context,
            phase: TipOutcomePresenter.phaseFor(
              CardTipVerdict.creditedToWallet,
            )!,
          ),
          child: const Text('go'),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      verify(() => profile.getWallet(true)).called(1);
      verify(() => profile.getWalletTransactions()).called(1);
      verify(() => appointments.getAppointments()).called(1);
      expect(find.byKey(const Key('tip_credited_dialog')), findsOneWidget);
      expect(find.textContaining('did not receive this tip'), findsOneWidget);
      expect(find.text('Tip Sent'), findsNothing);
    });

    test('pending and unknown outcomes are not announced as results', () {
      expect(TipOutcomePresenter.phaseFor(CardTipVerdict.pending), isNull);
      expect(TipOutcomePresenter.phaseFor(CardTipVerdict.unknown), isNull);
    });

    testWidgets('14. closing the checkout triggers a status check',
        (tester) async {
      await recovery.restore(ownerId: _customerA);
      final cubit = UpdateCreateAppointmentCubit(repo, tipRecovery: recovery);
      addTearDown(cubit.close);
      when(() => repo.getCustomerAppointmentById(_kAppointment)).thenAnswer(
        (_) async => ApiResult.success(
          data: CustomerAppointment(id: 77, status: 'completed'),
        ),
      );
      when(() => repo.customerFetchPortfolioById(id: any(named: 'id')))
          .thenAnswer(
        (_) async => ApiResult.failure(error: RemoteException.httpError(500)),
      );
      await tester.runAsync(() => cubit.fetchAppointmentById(_kAppointment));
      when(
        () => repo.tipCustomerAppointment(
          _kAppointment,
          amount: any(named: 'amount'),
          paymentMethod: 'card',
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(
          data: TipResponse.fromJson(const {
            'success': true,
            'code': 'checkout_started',
            'payment_method': 'card',
            'tip_amount': 20,
            'payment': {
              'deposit_id': _kDeposit,
              'checkout_id': 'chk_123',
              'redirect_url': 'https://checkout.example.test/chk_123',
            },
          }),
        ),
      );
      statuses.add(() => _tip('pending'));
      final savedAtOpen = <int>[];
      final original = TipFlow.openCheckout;
      TipFlow.openCheckout = (context, checkout) async {
        savedAtOpen.add(store.load(_customerA).length);
        return false; // the X: not proof of anything
      };
      addTearDown(() => TipFlow.openCheckout = original);

      await pumpHost(
        tester,
        child: (context) => TextButton(
          onPressed: () => TipFlow.start(
            context,
            cubit: cubit,
            walletBalance: 100,
            stylistName: 'Jane',
          ),
          child: const Text('tip'),
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

      expect(savedAtOpen, [1], reason: 'saved before the checkout opened');
      expect(statusCalls(), greaterThanOrEqualTo(1));
      expect(cubit.state.tipPayment.phase, TipPaymentPhase.pending);
      expect(store.load(_customerA), hasLength(1), reason: 'still unresolved');
    });

    testWidgets('Tip Your Stylist with an unresolved tip checks it instead',
        (tester) async {
      await store.save(_customerA, [_attempt()]);
      final restarted = CardTipRecovery(repo, store: store);
      addTearDown(restarted.dispose);
      statuses.add(() => _tip('pending'));
      await tester.runAsync(() => restarted.restore(ownerId: _customerA));
      final cubit = UpdateCreateAppointmentCubit(repo, tipRecovery: restarted);
      addTearDown(cubit.close);
      when(() => repo.getCustomerAppointmentById(_kAppointment)).thenAnswer(
        (_) async => ApiResult.success(
          data: CustomerAppointment(id: 77, status: 'completed'),
        ),
      );
      when(() => repo.customerFetchPortfolioById(id: any(named: 'id')))
          .thenAnswer(
        (_) async => ApiResult.failure(error: RemoteException.httpError(500)),
      );
      await tester.runAsync(() async {
        await cubit.fetchAppointmentById(_kAppointment);
        await Future<void>.delayed(Duration.zero);
      });
      final profile = _MockProfileCubit();
      when(() => profile.state).thenReturn(CustomerProfileMgtState.initial());

      await pumpHost(
        tester,
        profile: profile,
        child: (context) => TextButton(
          onPressed: () => TipFlow.startForBooking(context, cubit),
          child: const Text('tip'),
        ),
      );
      await tester.tap(find.text('tip'));
      await tester.pumpAndSettle();

      expect(find.byType(TipBottomSheet), findsNothing);
      expect(
        find.text(UpdateCreateAppointmentCubit.tipUnresolvedMessage),
        findsOneWidget,
      );
      verifyNever(
        () => repo.tipCustomerAppointment(
          any(),
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      );
    });
  });

  test('banner: unresolved tips offer Check Payment Status only', () {
    const pending = TipPaymentProgress(
      phase: TipPaymentPhase.pending,
      checkout: CheckoutPaymentData(depositId: _kDeposit),
    );
    expect(TipPaymentStatusBanner.showsFor(pending.phase), isTrue);
    expect(TipPaymentStatusBanner.showsFor(TipPaymentPhase.tipped), isFalse);
  });
}
