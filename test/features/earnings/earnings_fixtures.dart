/// `GET /stylist/earnings` bodies shaped exactly like Laravel's
/// `Stylist\DashboardController::earningIndex`:
/// - statistics `value`s are raw PHP numbers or SQL `sum()` decimal strings;
/// - transaction rows are `{id, name, email, requestId, purpose,
///   requestTime, amount, status, avatar, source}`, with `amount` from
///   `number_format(…, 2)` and pouch ids of the form `"pouch_<id>"`.
library;

/// A pouch (escrow) row as Laravel builds it.
Map<String, dynamic> pouchRow({
  Object? id = 'pouch_12',
  Object? amount = '480.75',
  String requestTime = 'Aug 20, 2026, 14:05:09',
}) =>
    {
      'id': id,
      'name': 'Jane Doe',
      'email': 'jane@example.com',
      'requestId': 'BK-1783504974-10',
      'purpose': 'Appointment',
      'requestTime': requestTime,
      'amount': amount,
      'status': 'Holding',
      'avatar': null,
      'source': 'pouch',
    };

/// A real transaction row (also returned by `/wallet/transactions`).
Map<String, dynamic> transactionRow({
  Object? id = 402,
  Object? amount = '1,250.00',
}) =>
    {
      'id': id,
      'name': 'Me',
      'email': 'stylist@example.com',
      'requestId': 'WD-20260819-ABC',
      'purpose': 'Withdrawal',
      'requestTime': 'Aug 19, 2026, 10:00:00',
      'amount': amount,
      'status': 'Completed',
      'avatar': null,
      'source': 'transaction',
    };

/// The response that crashed the Overview: string ids and `number_format`
/// amounts in `transactions`, and decimal-string sums in `statistics`.
Map<String, dynamic> problematicEarningsResponse({
  List<Map<String, dynamic>>? transactions,
}) =>
    {
      'statistics': {
        'total_earnings': {
          'value': 1600.5,
          'current_period': '0',
          'change_percentage': 0,
          'change_text': 'No previous data',
          'is_positive': true,
        },
        'total_balance': {
          'value': '1250.50',
          'change_percentage': 0,
          'change_text': 'No recent activity',
          'is_positive': true,
        },
        'total_withdrawn': {
          'value': '350.00',
          'current_period': 0,
          'change_percentage': 0,
          'change_text': 'No previous data',
          'is_positive': true,
        },
        'total_requests': {
          'value': 2,
          'change_text': '2 requests pending',
          'is_positive': false,
        },
        'pending_release': {
          'value': 480.75,
          'change_text': 'Released after the appointment completes',
          'is_positive': true,
        },
      },
      'transactions': transactions ?? [pouchRow(), transactionRow()],
      'payment_method': {
        'id': 7,
        'user_id': '3',
        'account_number': '1234567890',
        'account_name': 'Jane Doe',
        'bank_name': 'Capitec Bank',
        'routing_number': '470010',
        'is_default': true,
        'is_active': true,
        'deleted_at': null,
        'created_at': '2026-08-01T10:00:00.000000Z',
        'updated_at': '2026-08-01T10:00:00.000000Z',
        'bank': 'Capitec Bank',
        'account': '******7890',
        'routing': '****10',
      },
      'payment_methods': <Map<String, dynamic>>[],
      'settings': {
        'id': 1,
        'user_id': '3',
        'automatic_payout': false,
        'instant_payout': true,
        'payout_frequency': 'weekly',
        'payout_day': 'friday',
      },
    };

/// A stylist with no earnings yet: every figure is zero, no rows.
Map<String, dynamic> zeroEarningsResponse() => {
      'statistics': {
        'total_earnings': {'value': 0, 'change_text': 'No previous data'},
        'total_balance': {'value': '0.00'},
        'total_withdrawn': {'value': 0},
        'total_requests': {'value': 0, 'change_text': 'No pending requests'},
        'pending_release': {'value': 0.0},
      },
      'transactions': <Map<String, dynamic>>[],
      'payment_method': null,
      'payment_methods': <Map<String, dynamic>>[],
      'settings': null,
    };
