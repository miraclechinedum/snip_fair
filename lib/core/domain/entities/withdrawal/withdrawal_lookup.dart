import 'package:equatable/equatable.dart';

/// The stylist-facing status Laravel reports for a withdrawal
/// (`WithdrawalPayoutLedger::CLIENT_STATUSES`). Internal payout states and
/// Peach details are never sent.
enum WithdrawalRecordStatus {
  /// Recorded, not yet with the payout provider.
  pending,

  /// With the payout provider; not final.
  processing,

  /// Sent to the stylist's bank account by the payout provider. The bank may
  /// take some time to credit it, and the bank can still reverse it.
  paid,

  /// Not paid.
  failed,

  /// Held for a person to look at.
  underReview,

  /// Paid, then reversed by the bank.
  reversed,

  /// Closed by an administrator.
  closed;

  static WithdrawalRecordStatus? parse(Object? value) => switch (value) {
        'pending' => pending,
        'processing' => processing,
        'paid' => paid,
        'failed' => failed,
        'under_review' => underReview,
        'reversed' => reversed,
        'closed' => closed,
        _ => null,
      };
}

/// The wallet credit for a withdrawal that was not paid out.
class WithdrawalRefund extends Equatable {
  const WithdrawalRefund({
    this.transactionId,
    this.reference,
    this.amount,
    this.createdAt,
  });

  factory WithdrawalRefund.fromJson(Map<String, dynamic> json) =>
      WithdrawalRefund(
        transactionId: json['transaction_id'] is int
            ? json['transaction_id'] as int
            : null,
        reference:
            json['reference'] is String ? json['reference'] as String : null,
        amount: _amount(json['amount']),
        createdAt: _date(json['created_at']),
      );

  final int? transactionId;
  final String? reference;

  /// Rands, from Laravel's two-decimal string.
  final double? amount;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [transactionId, reference, amount, createdAt];
}

/// What `GET /wallet/withdrawals/lookup` found for an idempotency key:
/// client-safe fields only.
class WithdrawalRecord extends Equatable {
  const WithdrawalRecord({
    required this.id,
    required this.amountMinor,
    required this.rawStatus,
    required this.refunded,
    this.reference,
    this.currency,
    this.refund,
    this.transactionId,
    this.createdAt,
    this.statusUpdatedAt,
  });

  /// Throws [FormatException] when the fields the app relies on are missing:
  /// a body that cannot be read must not resolve an attempt.
  factory WithdrawalRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amountMinor = json['amount_minor'];
    final status = json['status'];
    final refunded = json['refunded'];
    if (id is! int ||
        amountMinor is! int ||
        status is! String ||
        refunded is! bool) {
      throw const FormatException('Unexpected withdrawal lookup body');
    }
    final refund = json['refund'];
    return WithdrawalRecord(
      id: id,
      amountMinor: amountMinor,
      rawStatus: status,
      refunded: refunded,
      reference:
          json['reference'] is String ? json['reference'] as String : null,
      currency: json['currency'] is String ? json['currency'] as String : null,
      refund: refund is Map<String, dynamic>
          ? WithdrawalRefund.fromJson(refund)
          : null,
      transactionId:
          json['transaction_id'] is int ? json['transaction_id'] as int : null,
      createdAt: _date(json['created_at']),
      statusUpdatedAt: _date(json['status_updated_at']),
    );
  }

  final int id;
  final int amountMinor;

  /// As sent; see [status].
  final String rawStatus;
  final bool refunded;
  final String? reference;
  final String? currency;
  final WithdrawalRefund? refund;
  final int? transactionId;
  final DateTime? createdAt;
  final DateTime? statusUpdatedAt;

  double get amount => amountMinor / 100;

  /// Null for a status this app does not know; it is then never presented
  /// as paid.
  WithdrawalRecordStatus? get status => WithdrawalRecordStatus.parse(rawStatus);

  @override
  List<Object?> get props => [
        id,
        amountMinor,
        rawStatus,
        refunded,
        reference,
        currency,
        refund,
        transactionId,
        createdAt,
        statusUpdatedAt,
      ];
}

/// The outcome of a successful lookup call.
sealed class WithdrawalLookup extends Equatable {
  const WithdrawalLookup();
}

/// A withdrawal is recorded under the key: the attempt is resolved.
class WithdrawalLookupFound extends WithdrawalLookup {
  const WithdrawalLookupFound(this.withdrawal);

  final WithdrawalRecord withdrawal;

  @override
  List<Object?> get props => [withdrawal];
}

/// 404 `WITHDRAWAL_NOT_FOUND`: nothing is recorded under the key *yet*. Not
/// proof the original request was refused (it may still arrive), so the
/// only safe follow-up is resending it with the same key and payload.
class WithdrawalLookupNotFound extends WithdrawalLookup {
  const WithdrawalLookupNotFound();

  @override
  List<Object?> get props => [];
}

double? _amount(Object? value) => value is num
    ? value.toDouble()
    : value is String
        ? double.tryParse(value.replaceAll(',', ''))
        : null;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
