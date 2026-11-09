import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';
import 'package:snip_fair/features/account/seller/earnings/views/seller_earning_screen.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

class _MockEarningsCubit extends MockCubit<EarningsState>
    implements EarningsCubit {}

class _MockSellerProfileMgtCubit extends MockCubit<SellerProfileMgtState>
    implements SellerProfileMgtCubit {}

/// The test font draws every glyph as a full em square, so the existing
/// "Payout Settings" header row overflows in tests only. Overflows are
/// ignored; every other error still fails the test.
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

const _laravelMessage =
    'Insufficient balance. Your available balance is R120.00.';

RemoteException _serverError(String message) =>
    RemoteException.serverError(422, ServerError(message: message));

void main() {
  group('SellerEarningScreen.payoutErrorMessage', () {
    const fallback = 'fallback';
    String message(Object? error) =>
        SellerEarningScreen.payoutErrorMessage(error, fallback: fallback);

    test("keeps the backend's message for a RemoteException", () {
      expect(message(_serverError(_laravelMessage)), _laravelMessage);
      expect(message(RemoteException.httpError(500)), 'Server Error');
    });

    test('uses the fallback when a RemoteException has no message', () {
      expect(message(const RemoteException.timeoutError()), fallback);
      expect(message(const RemoteException.noInternetError()), fallback);
      expect(message(_serverError('   ')), fallback);
    });

    test('uses the fallback for any other error type', () {
      expect(message(StateError('Bad state: boom')), fallback);
      expect(message(TypeError()), fallback);
      expect(message(const FormatException('x')), fallback);
      expect(message('a string'), fallback);
      expect(message(null), fallback);
    });
  });

  group('payout error dialogs', () {
    late _MockEarningsCubit cubit;
    late _MockSellerProfileMgtCubit profileCubit;

    setUp(() {
      cubit = _MockEarningsCubit();
      profileCubit = _MockSellerProfileMgtCubit();
    });

    Future<void> pumpWithStates(
      WidgetTester tester,
      List<EarningsState> states,
    ) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      _ignoreTestFontOverflows();

      whenListen(
        cubit,
        Stream.fromIterable(states),
        initialState: const EarningsState.initial(),
      );
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MultiBlocProvider(
            providers: [
              BlocProvider<EarningsCubit>.value(value: cubit),
              BlocProvider<SellerProfileMgtCubit>.value(value: profileCubit),
            ],
            child: const MaterialApp(home: SellerEarningScreen()),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    EarningsState payoutFailed(Object error) => const EarningsState.initial()
        .copyWith(requestPayoutState: ProcessState.error(error));

    EarningsState settingsFailed(Object error) =>
        const EarningsState.initial()
            .copyWith(updatePayoutSettingState: ProcessState.error(error));

    void expectFailDialog(WidgetTester tester, String text) {
      expect(tester.takeException(), isNull);
      expect(find.byType(OnFailDialogContent), findsOneWidget);
      expect(
        tester.widget<OnFailDialogContent>(find.byType(OnFailDialogContent))
            .subtext,
        text,
      );
      expect(find.text(text), findsOneWidget);
    }

    testWidgets("request payout: shows Laravel's message", (tester) async {
      await pumpWithStates(tester, [
        payoutFailed(_serverError(_laravelMessage)),
      ]);
      expectFailDialog(tester, _laravelMessage);
    });

    testWidgets('request payout: a non-RemoteException does not crash',
        (tester) async {
      await pumpWithStates(tester, [
        payoutFailed(StateError('Bad state: secret internals')),
      ]);
      // An unclassifiable failure is treated as "outcome unknown".
      expectFailDialog(
        tester,
        SellerEarningScreen.withdrawalUncertainMessage,
      );
      expect(find.textContaining('Bad state'), findsNothing);
    });

    testWidgets('request payout: a timeout offers a safe retry, not a blank',
        (tester) async {
      await pumpWithStates(tester, [
        payoutFailed(const RemoteException.timeoutError()),
      ]);
      expectFailDialog(
        tester,
        SellerEarningScreen.withdrawalUncertainMessage,
      );
    });

    testWidgets("payout settings: shows Laravel's message", (tester) async {
      await pumpWithStates(tester, [
        settingsFailed(_serverError('The payout day field is required.')),
      ]);
      expectFailDialog(tester, 'The payout day field is required.');
    });

    testWidgets('payout settings: a non-RemoteException does not crash',
        (tester) async {
      await pumpWithStates(tester, [
        settingsFailed(TypeError()),
      ]);
      expectFailDialog(tester, SellerEarningScreen.settingsErrorFallback);
      expect(find.textContaining('TypeError'), findsNothing);
      // A failure does not trigger the success-only profile refresh.
      verifyNever(() => profileCubit.getProfileDetails(any()));
    });
  });
}
