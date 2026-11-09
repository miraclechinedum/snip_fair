import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';
import 'package:snip_fair/features/account/customer/payment_history/widgets/customer_transaction_tile.dart';

/// `GET /wallet/transactions` rows as Laravel sends them
/// (`App\Support\TransactionHistoryRow`).
Map<String, dynamic> _row(
  int id,
  String type,
  String description, {
  Map<String, dynamic>? appointment,
  String? paymentMethod,
  String status = 'completed',
}) =>
    {
      'id': id,
      'type': type,
      'amount': 450,
      'description': description,
      'status': status,
      'reference': 'REF-$id',
      'created_at': '2026-11-04T10:00:00.000000Z',
      'updated_at': '2026-11-04T10:00:00.000000Z',
      'appointment': appointment,
      'payment_method': paymentMethod,
    };

const _appointment = {
  'id': '75',
  'booking_id': 'BK-1793796535-12',
  'appointment_code': 'SF-AB12CD',
  'service_name': 'Hair Installation',
  'stylist_name': "Miracle's Beauty Studio",
  'date': '2026-11-20',
  'time': '14:30:00',
  'status': 'pending',
};

const _appointmentTitle =
    "Appointment Payment – Hair Installation with Miracle's Beauty Studio";

UserTransaction _parse(Map<String, dynamic> json) =>
    UserTransaction.fromJson(json);

Future<void> _pumpTile(
  WidgetTester tester,
  UserTransaction transaction, {
  double width = 390,
}) async {
  tester.view
    ..physicalSize = Size(width * 3, 844 * 3)
    ..devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [CustomerTransactionTile(transaction: transaction)],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) =>
    (tester.widget<Text>(
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
    )).data!;

void main() {
  group('parsing', () {
    test('an appointment payment carries its booking', () {
      final tx = _parse(
        _row(1, 'payment', _appointmentTitle,
            appointment: _appointment, paymentMethod: 'card'),
      );

      expect(tx.description, _appointmentTitle);
      expect(tx.isAppointmentPayment, isTrue);
      expect(tx.paymentMethod, 'card');
      final appointment = tx.appointment!;
      expect(appointment.serviceName, 'Hair Installation');
      expect(appointment.stylistName, "Miracle's Beauty Studio");
      expect(appointment.reference, 'BK-1793796535-12');
      expect(appointment.startsAt, DateTime(2026, 11, 20, 14, 30));
      expect(appointment.scheduleLabel, 'Fri, 20 Nov 2026 · 2:30 PM');
    });

    test('every other transaction type keeps its description', () {
      final rows = {
        'topup': 'Wallet top-up via peachpayment',
        'withdraw': 'Withdrawal request',
        'refund': 'Refund for cancellation',
        'earning': 'Earnings from completed appointment #BK-1',
        // A Payment Request payment is a payment with no appointment.
        'payment': 'Payment for: Braids touch-up',
        'other': 'Tip sent to Miracle B for appointment #BK-1',
      };
      var id = 10;
      rows.forEach((type, description) {
        final tx = _parse(_row(id++, type, description));
        expect(tx.description, description, reason: type);
        expect(tx.appointment, isNull, reason: type);
        expect(tx.isAppointmentPayment, isFalse, reason: type);
      });
    });

    test('rows from an older server, or with odd values, still parse', () {
      final old = _parse({
        'id': 2,
        'type': 'payment',
        'amount': 60,
        'description': 'Appointment booking payment by card',
        'status': 'completed',
      });
      expect(old.description, 'Appointment booking payment by card');
      expect(old.appointment, isNull);
      expect(old.paymentMethod, isNull);

      final odd = _parse(
        _row(3, 'payment', 'x', appointment: {
          'id': 75,
          'service_name': '  ',
          'date': 'not-a-date',
          'time': 1430,
        }),
      );
      expect(odd.appointment!.id, '75');
      expect(odd.appointment!.serviceName, isNull);
      expect(odd.appointment!.scheduleLabel, isNull);

      expect(
        _parse({..._row(4, 'payment', 'x'), 'appointment': 'oops'}).appointment,
        isNull,
      );
    });

    test('an appointment without a time shows its date only', () {
      final appointment = TransactionAppointment.tryParse(
        {'date': '2026-11-20', 'booking_id': 'BK-9'},
      )!;
      expect(appointment.scheduleLabel, 'Fri, 20 Nov 2026');
    });
  });

  group('tile', () {
    testWidgets('an appointment payment shows its service, stylist and date',
        (tester) async {
      await _pumpTile(
        tester,
        _parse(_row(1, 'payment', _appointmentTitle,
            appointment: _appointment, paymentMethod: 'card')),
      );

      expect(_text(tester, 'customer_transaction_title_1'), _appointmentTitle);
      expect(
        _text(tester, 'customer_transaction_appointment_1'),
        'Fri, 20 Nov 2026 · 2:30 PM · BK-1793796535-12',
      );
      expect(find.text('-R450.00'), findsOneWidget);
      expect(find.text('completed'), findsOneWidget);
    });

    testWidgets('other rows show no appointment line', (tester) async {
      await _pumpTile(
        tester,
        _parse(_row(5, 'topup', 'Wallet top-up via peachpayment')),
      );

      expect(
        _text(tester, 'customer_transaction_title_5'),
        'Wallet top-up via peachpayment',
      );
      expect(
        find.byKey(const Key('customer_transaction_appointment_5')),
        findsNothing,
      );
      expect(find.text('+R450.00'), findsOneWidget);
    });

    testWidgets('a long title fits a small phone', (tester) async {
      await _pumpTile(
        tester,
        _parse(_row(
          6,
          'payment',
          'Appointment Payment – Knotless Box Braids (Waist Length, Colour '
              'Included) with The Very Long Beauty Studio Name Of Cape Town',
          appointment: _appointment,
        )),
        width: 320,
      );

      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('customer_transaction_title_6')),
          matching: find.byType(Text),
        ),
      );
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('tapping opens the details with the appointment reference',
        (tester) async {
      await _pumpTile(
        tester,
        _parse(_row(1, 'payment', _appointmentTitle,
            appointment: _appointment, paymentMethod: 'card')),
      );

      await tester.tap(find.byKey(const Key('customer_transaction_1')));
      await tester.pumpAndSettle();

      String detail(String label) =>
          _text(tester, 'customer_transaction_detail_$label');
      expect(detail('Service'), 'Hair Installation');
      expect(detail('Stylist'), "Miracle's Beauty Studio");
      expect(detail('Appointment'), 'Fri, 20 Nov 2026 · 2:30 PM');
      expect(detail('Appointment reference'), 'BK-1793796535-12');
      expect(detail('Payment method'), 'Card');
      expect(detail('Amount'), 'R450.00');
      expect(detail('Status'), 'Completed');
      expect(detail('Transaction reference'), 'REF-1');
    });

    testWidgets('details of a non-appointment row omit booking fields',
        (tester) async {
      await _pumpTile(
        tester,
        _parse(_row(7, 'withdraw', 'Withdrawal request')),
      );
      await tester.tap(find.byKey(const Key('customer_transaction_7')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('customer_transaction_detail_Service')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('customer_transaction_detail_Payment method')),
        findsNothing,
      );
      expect(_text(tester, 'customer_transaction_details_title'),
          'Withdrawal request');
    });
  });
}
