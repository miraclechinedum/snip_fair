import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/bank/bank.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/features/account/seller/payment_methods/cubit/seller_payment_methods_cubit.dart';
import 'package:snip_fair/features/account/seller/payment_methods/views/seller_payment_method_form_view.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repo;
  late SellerPaymentMethodsCubit paymentCubit;
  late SellerProfileMgtCubit profileCubit;

  setUp(() {
    repo = _MockProfileRepository();
    when(repo.getBanks).thenAnswer(
      (_) async => ApiResult.success(
        data: [Bank(name: 'Absa', branchCode: '632005')],
      ),
    );
    when(repo.getPaymentMethods)
        .thenAnswer((_) async => const ApiResult.success(data: []));
    when(repo.getStylistProfile).thenAnswer(
      (_) async => ApiResult.success(data: StylistProfileDetails()),
    );
    when(
      () => repo.createPaymentMethod(
        accountNumber: any(named: 'accountNumber'),
        accountName: any(named: 'accountName'),
        bankName: any(named: 'bankName'),
        routingNumber: any(named: 'routingNumber'),
      ),
    ).thenAnswer(
      (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
    );
    paymentCubit = SellerPaymentMethodsCubit(repo);
    profileCubit = SellerProfileMgtCubit(repo);
  });

  tearDown(() async {
    await paymentCubit.close();
    await profileCubit.close();
  });

  Future<void> openSheet(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await paymentCubit.getBanks();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: paymentCubit),
            BlocProvider.value(value: profileCubit),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => SellerPaymentMethodFormWidget.show(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Add Payment Method'), findsOneWidget);
  }

  Finder sheet() => find.byType(SellerPaymentMethodFormWidget);
  Finder discardDialog() => find.byKey(const Key('bank_details_discard_dialog'));

  Future<void> typeAccountName(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'Jane Doe');
    await tester.pump();
  }

  void expectNothingSubmitted() {
    verifyNever(
      () => repo.createPaymentMethod(
        accountNumber: any(named: 'accountNumber'),
        accountName: any(named: 'accountName'),
        bankName: any(named: 'bankName'),
        routingNumber: any(named: 'routingNumber'),
      ),
    );
  }

  testWidgets('the back arrow is visible and closes an untouched form',
      (tester) async {
    await openSheet(tester);

    expect(find.byKey(const Key('bank_details_back')), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bank_details_back')));
    await tester.pumpAndSettle();

    expect(sheet(), findsNothing);
    expect(discardDialog(), findsNothing);
    expectNothingSubmitted();
  });

  testWidgets('device back closes an untouched form', (tester) async {
    await openSheet(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(sheet(), findsNothing);
  });

  testWidgets('typed details ask before discarding; Keep editing stays',
      (tester) async {
    await openSheet(tester);
    await typeAccountName(tester);

    await tester.tap(find.byKey(const Key('bank_details_back')));
    await tester.pumpAndSettle();

    expect(discardDialog(), findsOneWidget);
    expect(find.text('Discard bank details?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(discardDialog(), findsNothing);
    expect(sheet(), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expectNothingSubmitted();
  });

  testWidgets('Discard leaves without submitting', (tester) async {
    await openSheet(tester);
    await typeAccountName(tester);

    await tester.tap(find.byKey(const Key('bank_details_back')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(sheet(), findsNothing);
    expectNothingSubmitted();
    // The form is reset when the sheet closes.
    expect(paymentCubit.state.accountName.value, isEmpty);
  });

  testWidgets('device back with typed details asks too', (tester) async {
    await openSheet(tester);
    await typeAccountName(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(discardDialog(), findsOneWidget);
    expect(sheet(), findsOneWidget);
    expectNothingSubmitted();
  });

  testWidgets('tapping outside with typed details asks too', (tester) async {
    await openSheet(tester);
    await typeAccountName(tester);

    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();

    expect(discardDialog(), findsOneWidget);
    expect(sheet(), findsOneWidget);
  });

  testWidgets('a complete submission still saves and closes without asking',
      (tester) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextField).at(1), '1234567890');
    await tester.tap(find.byKey(const Key('bank_name_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank_option_Absa')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Method'));
    await tester.pumpAndSettle();

    verify(
      () => repo.createPaymentMethod(
        accountNumber: '1234567890',
        accountName: 'Jane Doe',
        bankName: 'Absa',
        routingNumber: '632005',
      ),
    ).called(1);
    expect(discardDialog(), findsNothing);
    expect(sheet(), findsNothing);
  });

  testWidgets('dragging the sheet down with typed details does not lose them',
      (tester) async {
    await openSheet(tester);
    await typeAccountName(tester);

    await tester.drag(find.text('Add Payment Method'), const Offset(0, 700));
    await tester.pumpAndSettle();

    // Drag-to-dismiss would bypass the guard, so it is disabled: the sheet
    // and the typed details stay.
    expect(sheet(), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expectNothingSubmitted();
  });
}
