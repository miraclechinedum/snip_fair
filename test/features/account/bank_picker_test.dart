import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/bank/bank.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/features/account/seller/payment_methods/cubit/seller_payment_methods_cubit.dart';
import 'package:snip_fair/features/account/seller/payment_methods/views/bank_picker_sheet.dart';
import 'package:snip_fair/features/account/seller/payment_methods/views/seller_payment_method_form_view.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

final _banks = [
  Bank(name: 'Absa Bank', branchCode: '632005'),
  Bank(name: 'Capitec Bank', branchCode: '470010'),
  Bank(name: 'First National Bank', branchCode: '250655'),
  Bank(name: 'Nedbank', branchCode: '198765'),
  Bank(name: 'Standard Bank', branchCode: '051001'),
];

void main() {
  group('BankPickerSheet.filter', () {
    List<String?> names(String query) =>
        BankPickerSheet.filter(_banks, query).map((b) => b.name).toList();

    test('full, partial and case-insensitive matches', () {
      expect(names('Nedbank'), ['Nedbank']);
      expect(names('nat'), ['First National Bank']);
      expect(names('STANDARD'), ['Standard Bank']);
      expect(names('bank'), hasLength(5));
    });

    test('surrounding spaces are ignored; blank shows everything', () {
      expect(names('  capitec  '), ['Capitec Bank']);
      expect(names('   '), hasLength(5));
    });

    test('no match yields an empty list', () {
      expect(names('zzz'), isEmpty);
    });

    test('banks are the same when name and branch code match', () {
      expect(
        BankPickerSheet.isSameBank(
          _banks.first,
          Bank(name: 'Absa Bank', branchCode: '632005'),
        ),
        isTrue,
      );
      expect(BankPickerSheet.isSameBank(_banks.first, _banks[1]), isFalse);
      expect(BankPickerSheet.isSameBank(null, _banks.first), isFalse);
    });
  });

  group('searchable bank selector in the payment method form', () {
    late _MockProfileRepository repo;
    late SellerPaymentMethodsCubit paymentCubit;
    late SellerProfileMgtCubit profileCubit;

    setUp(() {
      repo = _MockProfileRepository();
      when(repo.getBanks)
          .thenAnswer((_) async => ApiResult.success(data: _banks));
      when(repo.getPaymentMethods)
          .thenAnswer((_) async => const ApiResult.success(data: []));
      when(repo.getStylistProfile).thenAnswer(
        (_) async => ApiResult.success(data: StylistProfileDetails()),
      );
      when(
        () => repo.updatePaymentMethod(
          paymentMethodId: any(named: 'paymentMethodId'),
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

    /// iPhone SE-sized screen: the smallest the app supports.
    Future<void> openForm(
      WidgetTester tester, {
      PaymentMethod? editing,
    }) async {
      tester.view
        ..physicalSize = const Size(375 * 2, 667 * 2)
        ..devicePixelRatio = 2.0;
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
                      onPressed: () =>
                          SellerPaymentMethodFormWidget.show(context, editing),
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
    }

    Finder picker() => find.byType(BankPickerSheet);
    Finder option(String name) => find.byKey(Key('bank_option_$name'));
    Finder form() => find.byType(SellerPaymentMethodFormWidget);

    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('bank_name_field')));
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(const Key('bank_picker_search')), text);
      await tester.pump();
    }

    String? fieldText(WidgetTester tester) => find
        .descendant(
          of: find.byKey(const Key('bank_name_field')),
          matching: find.byType(Text),
        )
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .firstOrNull;

    testWidgets('opens as a titled overlay with a focused search field',
        (tester) async {
      await openForm(tester);
      await openPicker(tester);

      expect(picker(), findsOneWidget);
      expect(find.text('Select Bank'), findsOneWidget);
      expect(find.text('Search bank name'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('bank_picker_search')),
      );
      expect(field.autofocus, isTrue);
      for (final bank in _banks) {
        expect(option(bank.name!), findsOneWidget);
      }
      // An overlay, not a full-screen page: capped at 75% of the screen.
      expect(
        tester.getSize(picker()).height,
        lessThanOrEqualTo(667 * 0.75 + 1),
      );
    });

    testWidgets('filters by full, partial and mixed-case names',
        (tester) async {
      await openForm(tester);
      await openPicker(tester);

      await search(tester, 'Nedbank');
      expect(option('Nedbank'), findsOneWidget);
      expect(option('Absa Bank'), findsNothing);

      await search(tester, 'nat');
      expect(option('First National Bank'), findsOneWidget);
      expect(option('Nedbank'), findsNothing);

      await search(tester, '  CaPiTeC ');
      expect(option('Capitec Bank'), findsOneWidget);
      expect(option('Standard Bank'), findsNothing);
    });

    testWidgets('no match shows a friendly empty state; clear resets',
        (tester) async {
      await openForm(tester);
      await openPicker(tester);

      await search(tester, 'zzz');
      expect(find.text('No banks found.'), findsOneWidget);
      expect(option('Absa Bank'), findsNothing);

      await tester.tap(find.byKey(const Key('bank_picker_clear')));
      await tester.pump();

      expect(find.text('No banks found.'), findsNothing);
      expect(option('Absa Bank'), findsOneWidget);
      expect(option('Standard Bank'), findsOneWidget);
    });

    testWidgets('selecting a bank closes the picker and fills the field',
        (tester) async {
      await openForm(tester);
      await openPicker(tester);
      await search(tester, 'first');

      await tester.tap(option('First National Bank'));
      await tester.pumpAndSettle();

      expect(picker(), findsNothing);
      expect(form(), findsOneWidget);
      expect(fieldText(tester), 'First National Bank');
      expect(paymentCubit.state.selectedBank?.branchCode, '250655');
      // Selecting never submits.
      verifyNever(
        () => repo.createPaymentMethod(
          accountNumber: any(named: 'accountNumber'),
          accountName: any(named: 'accountName'),
          bankName: any(named: 'bankName'),
          routingNumber: any(named: 'routingNumber'),
        ),
      );
    });

    testWidgets('reopening marks the selected bank', (tester) async {
      await openForm(tester);
      await openPicker(tester);
      await tester.tap(option('Nedbank'));
      await tester.pumpAndSettle();

      await openPicker(tester);

      final tile = tester.widget<ListTile>(option('Nedbank'));
      expect(tile.selected, isTrue);
      expect(tester.widget<ListTile>(option('Absa Bank')).selected, isFalse);
      expect(
        find.descendant(
          of: option('Nedbank'),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
    });

    for (final (how, dismiss) in [
      (
        'the close button',
        (WidgetTester tester) async {
          await tester.tap(find.byKey(const Key('bank_picker_close')));
        },
      ),
      (
        'a tap outside',
        (WidgetTester tester) async {
          await tester.tapAt(const Offset(187, 10));
        },
      ),
      (
        'device back',
        (WidgetTester tester) async {
          await tester.binding.handlePopRoute();
        },
      ),
    ]) {
      testWidgets('dismissing with $how keeps the previous bank',
          (tester) async {
        await openForm(tester);
        await openPicker(tester);
        await tester.tap(option('Capitec Bank'));
        await tester.pumpAndSettle();

        await openPicker(tester);
        await search(tester, 'standard');
        await dismiss(tester);
        await tester.pumpAndSettle();

        expect(picker(), findsNothing);
        // Only the picker closed; the payment method form is still open.
        expect(form(), findsOneWidget);
        expect(fieldText(tester), 'Capitec Bank');
        expect(paymentCubit.state.selectedBank?.name, 'Capitec Bank');
      });
    }

    testWidgets('scrolling the results closes the keyboard, selects nothing',
        (tester) async {
      await openForm(tester);
      await openPicker(tester);

      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(picker(), findsOneWidget);
      expect(paymentCubit.state.selectedBank, isNull);
    });

    testWidgets('updating a method keeps its bank until another is chosen',
        (tester) async {
      await openForm(
        tester,
        editing: PaymentMethod.fromJson({
          'id': 7,
          'account_name': 'Jane Doe',
          'account_number': '1234567890',
          'bank_name': 'Standard Bank',
          'routing_number': '051001',
        }),
      );

      expect(fieldText(tester), 'Standard Bank');
      await openPicker(tester);
      expect(tester.widget<ListTile>(option('Standard Bank')).selected, isTrue);
      await tester.tap(find.byKey(const Key('bank_picker_close')));
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'Standard Bank');
    });
  });
}
