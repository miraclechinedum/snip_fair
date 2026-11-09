import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/utils/json_coercion.dart';

import 'earnings_fixtures.dart';

void main() {
  group('toNumOrNull / toIntOrNull', () {
    test('reads numbers, decimal strings and number_format strings', () {
      expect(toNumOrNull(1250), 1250);
      expect(toNumOrNull(1250.5), 1250.5);
      expect(toNumOrNull('1250.50'), 1250.5);
      expect(toNumOrNull('1,250.00'), 1250);
      expect(toNumOrNull(' 12 345.67 '), 12345.67);
      expect(toNumOrNull('-75.25'), -75.25);
    });

    test('keeps zero as zero', () {
      for (final zero in [0, 0.0, '0', '0.00']) {
        expect(toNumOrNull(zero), 0, reason: '$zero');
      }
    });

    test('rejects anything that is not a number', () {
      for (final bad in [
        null,
        '',
        '  ',
        'abc',
        'R10',
        true,
        <String, dynamic>{},
        <dynamic>[],
        double.nan,
        double.infinity,
      ]) {
        expect(toNumOrNull(bad), isNull, reason: '$bad');
      }
    });

    test('toIntOrNull accepts whole numbers only', () {
      expect(toIntOrNull(2), 2);
      expect(toIntOrNull('3'), 3);
      expect(toIntOrNull(4.0), 4);
      expect(toIntOrNull(2.5), isNull);
      expect(toIntOrNull('pouch_1'), isNull);
    });
  });

  group('StylistEarnings.fromJson', () {
    test('parses the response that crashed the Overview', () {
      final earnings =
          StylistEarnings.fromJson(problematicEarningsResponse());
      final stats = earnings.statistics!;

      // Cents are kept: these used to be `int` and truncated.
      expect(stats.totalEarnings!.value, 1600.5);
      expect(stats.totalBalance!.value, 1250.5);
      expect(stats.totalWithdrawn!.value, 350);
      expect(stats.totalRequests!.value, 2);
      expect(stats.pendingRelease!.value, 480.75);
      expect(stats.pendingRelease!.changeText, isNotEmpty);

      expect(earnings.paymentMethod!.bankName, 'Capitec Bank');
      expect(earnings.settings!.instantPayout, isTrue);

      final rows = earnings.transactions!;
      expect(rows, hasLength(2));

      final pouch = rows.first;
      expect(pouch.id, -12, reason: 'pouch ids live in their own space');
      expect(pouch.isEscrow, isTrue);
      expect(pouch.type, 'earning');
      expect(pouch.amount, 480.75);
      expect(pouch.status, 'holding');
      expect(pouch.reference, 'BK-1783504974-10');
      expect(pouch.description, 'Appointment · Jane Doe');
      expect(pouch.createdAt, DateTime(2026, 8, 20, 14, 5, 9));

      final withdrawal = rows.last;
      expect(withdrawal.id, 402);
      expect(withdrawal.isEscrow, isFalse);
      expect(withdrawal.type, 'withdrawal');
      expect(withdrawal.amount, 1250);
      expect(withdrawal.status, 'completed');
      expect(withdrawal.description, 'Withdrawal');
    });

    test('null values and sections are kept null, not zeroed', () {
      final earnings = StylistEarnings.fromJson({
        'statistics': {
          'total_earnings': {'value': null, 'change_text': null},
          'total_balance': {'value': null},
          'total_withdrawn': {'value': null},
          'total_requests': {'value': null},
          'pending_release': null,
        },
        'transactions': null,
        'payment_method': null,
        'payment_methods': null,
        'settings': null,
      });

      final stats = earnings.statistics!;
      expect(stats.totalEarnings!.value, isNull);
      expect(stats.totalBalance!.value, isNull);
      expect(stats.totalWithdrawn!.value, isNull);
      expect(stats.totalRequests!.value, isNull);
      expect(stats.pendingRelease, isNull);
      expect(earnings.transactions, isNull);
      expect(earnings.paymentMethod, isNull);
      expect(earnings.settings, isNull);
    });

    test('missing optional fields parse', () {
      expect(StylistEarnings.fromJson({}).statistics, isNull);

      final earnings = StylistEarnings.fromJson({
        'statistics': {'total_balance': <String, dynamic>{}},
        'transactions': [
          {'id': 9, 'amount': '10.00'},
        ],
      });
      expect(earnings.statistics!.totalBalance!.value, isNull);
      expect(earnings.statistics!.totalWithdrawn, isNull);

      // A row with only an id and amount: no date, description or reference.
      final row = earnings.transactions!.single;
      expect(row.id, 9);
      expect(row.amount, 10);
      expect(row.createdAt, isNull);
      expect(row.description, isNull);
      expect(row.reference, isNull);
      expect(row.status, isNull);
    });

    test('zero earnings stay zero', () {
      final stats = StylistEarnings.fromJson(zeroEarningsResponse())
          .statistics!;
      expect(stats.totalEarnings!.value, 0);
      expect(stats.totalBalance!.value, 0);
      expect(stats.totalWithdrawn!.value, 0);
      expect(stats.totalRequests!.value, 0);
      expect(stats.pendingRelease!.value, 0);
    });

    test('an empty transaction list is an empty list', () {
      expect(
        StylistEarnings.fromJson(zeroEarningsResponse()).transactions,
        isEmpty,
      );
    });

    test('invalid types become null instead of throwing', () {
      final earnings = StylistEarnings.fromJson({
        'statistics': {
          'total_earnings': {'value': 'abc'},
          'total_balance': {'value': true},
          'total_withdrawn': {'value': <String, dynamic>{}},
          'total_requests': {'value': 2.5},
          'pending_release': {'value': <dynamic>[]},
        },
        'transactions': 'not a list',
      });
      final stats = earnings.statistics!;
      expect(stats.totalEarnings!.value, isNull);
      expect(stats.totalBalance!.value, isNull);
      expect(stats.totalWithdrawn!.value, isNull);
      expect(stats.totalRequests!.value, isNull);
      expect(stats.pendingRelease!.value, isNull);
      expect(earnings.transactions, isNull);
    });

    test('unreadable rows are skipped, readable ones kept', () {
      final earnings = StylistEarnings.fromJson({
        'transactions': [
          'garbage',
          42,
          pouchRow(amount: null),
          pouchRow(amount: 'n/a'),
          pouchRow(id: 'pouch_x'),
          transactionRow(id: '17'),
          {
            ...transactionRow(id: 18),
            'requestTime': 'yesterday',
            'requestId': 'N/A',
            'purpose': 123,
          },
        ],
      });

      final rows = earnings.transactions!;
      expect(rows, hasLength(3));
      // A pouch whose id can't be read is kept, without an id.
      expect(rows[0].id, isNull);
      expect(rows[0].isEscrow, isTrue);
      expect(rows[1].id, 17);
      expect(rows[2].id, 18);
      expect(rows[2].createdAt, isNull);
      expect(rows[2].reference, isNull);
      expect(rows[2].description, isNull);
      expect(rows[2].type, isNull);
    });

    test('wallet rows still parse with the wallet shape', () {
      final row = UserTransaction.fromJson({
        'id': 402,
        'type': 'withdraw',
        'amount': 200.0,
        'status': 'completed',
        'description': 'Payout',
        'reference': 'WD-1',
        'created_at': '2026-08-19T10:00:00.000Z',
      });
      expect(row.id, 402);
      expect(row.amount, 200);
      expect(row.isEscrow, isFalse);
    });
  });
}
