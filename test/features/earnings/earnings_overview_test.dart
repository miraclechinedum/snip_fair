import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';
import 'package:snip_fair/features/account/seller/earnings/views/seller_earning_screen.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

import 'earnings_fixtures.dart';
import 'withdrawal_test_support.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockSellerProfileMgtCubit extends MockCubit<SellerProfileMgtState>
    implements SellerProfileMgtCubit {}

/// The test font draws every glyph as a full em square, so the existing
/// "Payout Settings" header row (unchanged here) overflows in tests only.
/// Overflows are ignored; every other error still fails the test.
void _ignoreTestFontOverflows() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
      return;
    }
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ApiResult<StylistEarnings> _ok(Map<String, dynamic> body) =>
    ApiResult.success(data: StylistEarnings.fromJson(body));

void main() {
  late _MockProfileRepository repo;
  late EarningsCubit cubit;
  late _MockSellerProfileMgtCubit profileCubit;

  setUp(() async {
    repo = _MockProfileRepository();
    cubit = EarningsCubit(repo, await stylistAttemptStore());
    profileCubit = _MockSellerProfileMgtCubit();
    when(() => profileCubit.getProfileDetails(any()))
        .thenAnswer((_) async {});
    when(repo.getPaymentMethods).thenAnswer(
      (_) async => ApiResult.success(
        data: [
          PaymentMethod.fromJson(
            problematicEarningsResponse()['payment_method']
                as Map<String, dynamic>,
          ),
        ],
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
  });

  tearDown(() => cubit.close());

  /// Pumps the real screen the way `wrappedRoute` starts it.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    _ignoreTestFontOverflows();

    unawaited(cubit.getEarnings());
    unawaited(cubit.getPaymentMethods());
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider<SellerProfileMgtCubit>.value(value: profileCubit),
          ],
          child: const MaterialApp(home: SellerEarningScreen()),
        ),
      ),
    );
    await _settle(tester);
  }

  String shown(WidgetTester tester, String key) =>
      tester.widget<AppText>(find.byKey(Key(key))).text;

  testWidgets('renders the response that used to crash the Overview',
      (tester) async {
    when(repo.getEarnings)
        .thenAnswer((_) async => _ok(problematicEarningsResponse()));

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(OverviewWidget), findsOneWidget);
    expect(shown(tester, 'earnings_total_earned'), 'R1,600.50');
    expect(shown(tester, 'earnings_available_balance'), 'R1,250.50');
    expect(shown(tester, 'earnings_in_escrow'), 'R480.75');
    expect(shown(tester, 'earnings_total_withdrawn'), 'R350.00');
    expect(shown(tester, 'earnings_pending_requests'), '2');
    expect(find.byKey(const Key('earnings_load_error')), findsNothing);
    expect(find.text('Capitec Bank'), findsOneWidget);
  });

  testWidgets('zero earnings and no transactions show zeros, not a crash',
      (tester) async {
    when(repo.getEarnings)
        .thenAnswer((_) async => _ok(zeroEarningsResponse()));

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    for (final key in [
      'earnings_total_earned',
      'earnings_available_balance',
      'earnings_in_escrow',
      'earnings_total_withdrawn',
    ]) {
      expect(shown(tester, key), 'R0.00', reason: key);
    }
    expect(shown(tester, 'earnings_pending_requests'), '0');
    expect(find.text('No Payment method'), findsOneWidget);
    expect(cubit.state.transactionsState.data, isEmpty);
  });

  testWidgets('missing figures show a dash instead of an invented zero',
      (tester) async {
    when(repo.getEarnings).thenAnswer(
      (_) async => _ok({
        'statistics': {
          'total_earnings': {'value': null},
          'total_withdrawn': {'value': 'abc'},
        },
      }),
    );

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    for (final key in [
      'earnings_total_earned',
      'earnings_available_balance',
      'earnings_in_escrow',
      'earnings_total_withdrawn',
      'earnings_pending_requests',
    ]) {
      expect(shown(tester, key), OverviewWidget.unavailable, reason: key);
    }
  });

  testWidgets('masks figures while loading', (tester) async {
    final pending = Completer<ApiResult<StylistEarnings>>();
    when(repo.getEarnings).thenAnswer((_) => pending.future);

    await pumpScreen(tester);

    expect(shown(tester, 'earnings_total_earned'), '********');
    expect(shown(tester, 'earnings_total_withdrawn'), '********');

    pending.complete(_ok(problematicEarningsResponse()));
    await _settle(tester);
    expect(shown(tester, 'earnings_total_withdrawn'), 'R350.00');
  });

  testWidgets('a failed load shows a friendly error and retries',
      (tester) async {
    var calls = 0;
    when(repo.getEarnings).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        // What BaseRemoteSource returns for a response it can't parse.
        return ApiResult.failure(
          error: RemoteException.unexpectedError(
            TypeError(),
          ),
        );
      }
      return _ok(problematicEarningsResponse());
    });

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('earnings_load_error')), findsOneWidget);
    expect(
      find.text("We couldn't load your earnings. Please try again."),
      findsOneWidget,
    );
    // No raw Dart error reaches the stylist.
    expect(find.textContaining('TypeError'), findsNothing);
    expect(find.textContaining('Instance of'), findsNothing);
    expect(
      shown(tester, 'earnings_total_withdrawn'),
      OverviewWidget.unavailable,
    );

    await tester.tap(find.byKey(const Key('earnings_retry')));
    await _settle(tester);

    expect(calls, 2);
    expect(find.byKey(const Key('earnings_load_error')), findsNothing);
    expect(shown(tester, 'earnings_total_withdrawn'), 'R350.00');
  });

  testWidgets('Request Payout still submits to the default payment method',
      (tester) async {
    when(repo.getEarnings)
        .thenAnswer((_) async => _ok(problematicEarningsResponse()));
    when(
      () => repo.requestPayout(
        any(),
        any(),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer(
      (_) async => ApiResult.success(
        data: const WithdrawalSubmission(amount: 250.5),
      ),
    );

    await pumpScreen(tester);

    await tester.tap(find.text('Request Payout'));
    await _settle(tester);
    expect(find.byType(RequestPayoutFormWidget), findsOneWidget);
    expect(find.text('Payout Details'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(RequestPayoutFormWidget),
        matching: find.byType(TextField),
      ),
      '250.50',
    );
    await tester.tap(find.widgetWithText(CustomButton, 'Request Payout'));
    await _settle(tester);

    verify(
      () => repo.requestPayout(
        '7',
        250.5,
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
    expect(find.text('Withdrawal Request Submitted'), findsOneWidget);
    expect(find.byType(RequestPayoutFormWidget), findsNothing);
    // Figures are refreshed after the payout.
    verify(repo.getEarnings).called(2);
  });

  testWidgets('Transactions tab still lists the escrow row', (tester) async {
    when(repo.getEarnings)
        .thenAnswer((_) async => _ok(problematicEarningsResponse()));

    await pumpScreen(tester);
    await tester.tap(find.text('Transactions'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TransactionsWidget), findsOneWidget);
    final rows = cubit.state.transactionsState.data!;
    expect(rows.where((t) => t.isEscrow), hasLength(1));
    expect(rows.firstWhere((t) => t.isEscrow).amount, 480.75);
  });
}
