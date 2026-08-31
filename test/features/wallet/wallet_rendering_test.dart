import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/customer_wallet.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';

void main() {
  group('customer wallet escrow contract', () {
    test('escrow_balance keeps its cents (gross amount paid)', () {
      // Complaint #5: the escrow tile must show the FULL gross amount paid.
      // These fields used to be `int`, which truncated R480.75 to R480.00.
      final wallet = CustomerWallet.fromJson({
        'balance': 0,
        'escrow_balance': 480.75,
      });

      expect(wallet.escrowBalance, 480.75);
      expect(wallet.escrowBalance!.formatAmount(), contains('480.75'));
    });

    test('cash balance is unchanged by a card booking', () {
      final wallet = CustomerWallet.fromJson({
        'balance': 0,
        'escrow_balance': 480.75,
        'stats': {'current_balance': 0},
      });

      expect(wallet.balance, 0);
      expect(wallet.stats?.currentBalance, 0);
    });

    test('stats decode under either snake_case or camelCase keys', () {
      final snake = CustomerWallet.fromJson({
        'stats': {'current_balance': 125.5, 'total_topups': 300.25},
      });
      expect(snake.stats?.currentBalance, 125.5);
      expect(snake.stats?.totalTopups, 300.25);

      final camel = CustomerWallet.fromJson({
        'stats': {'currentBalance': 125.5, 'totalTopups': 300.25},
      });
      expect(camel.stats?.currentBalance, 125.5);
      expect(camel.stats?.totalTopups, 300.25);
    });
  });

  group('GET /wallet/transactions rendering data', () {
    test('parses a completed card booking payment row', () {
      // Complaint #6: the completed card booking payment must be visible in
      // history with amount / status / description intact.
      final list = CustomerWalletTransactionList.fromJson({
        'data': [
          {
            'id': 9001,
            'type': 'payment',
            'amount': 480.75,
            'status': 'completed',
            'description': 'Card payment for booking BK-1783504974-10',
            'reference': 'BK-1783504974-10',
            'created_at': '2026-08-24T09:15:00.000Z',
          },
        ],
        'next_cursor': null,
      });

      final row = list.data!.single;
      expect(row.type, 'payment');
      expect(row.amount, 480.75);
      expect(row.status, 'completed');
      expect(
        row.description,
        'Card payment for booking BK-1783504974-10',
      );
      expect(row.createdAt, isNotNull);
      // Null next_cursor means the list has reached the end — the wallet
      // screen relies on this to stop paginating.
      expect(list.nextCursor, isNull);
    });
  });
}
