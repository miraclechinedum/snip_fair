import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/transaction_appointment.dart';
import 'package:snip_fair/core/utils/json_coercion.dart';

export 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/transaction_appointment.dart';

part 'datum.g.dart';

@JsonSerializable()
class UserTransaction {

  UserTransaction({
    this.id,
    this.type,
    this.amount,
    this.description,
    this.status,
    this.reference,
    this.createdAt,
    this.updatedAt,
    this.isEscrow = false,
    this.appointment,
    this.paymentMethod,
  });

  /// The generated mapping, plus the optional booking details Laravel sends
  /// for appointment payments (read tolerantly, so older payloads still parse).
  factory UserTransaction.fromJson(Map<String, dynamic> json) =>
      _$UserTransactionFromJson(json)
        ..appointment = TransactionAppointment.tryParse(json['appointment'])
        ..paymentMethod = _text(json['payment_method']);

  /// One row of `GET /stylist/earnings` `transactions`, which Laravel builds
  /// as `{id, name, email, requestId, purpose, requestTime, amount, status,
  /// avatar, source}` — not the wallet shape:
  /// - `id` is the transaction id, or `"pouch_<id>"` for escrow held against
  ///   an approved booking (`source: pouch`);
  /// - `amount` is `number_format(…, 2)`, e.g. `"1,250.00"`;
  /// - `requestTime` is `"M d, Y, H:i:s"` wall-clock time in the server's
  ///   `APP_TIMEZONE` (Africa/Johannesburg), with no offset;
  /// - `purpose`/`status` are Title Case (`Earning`, `Completed`).
  ///
  /// Mapped onto the fields the Transactions tab reads. Null when the row has
  /// no usable amount — an amount is never invented.
  static UserTransaction? fromEarningsRow(Map<String, dynamic> row) {
    final amount = toNumOrNull(row['amount']);
    if (amount == null) return null;

    final rawId = row['id'];
    final isPouch = row['source'] == 'pouch' ||
        (rawId is String && rawId.startsWith('pouch_'));
    int? id;
    if (isPouch) {
      // Escrow pouches have their own id space: a negative key keeps them
      // distinct from (and never merged with) real transaction ids.
      final pouchId = toIntOrNull(
        rawId is String ? rawId.replaceFirst('pouch_', '') : rawId,
      );
      id = pouchId == null ? null : -pouchId;
    } else {
      id = toIntOrNull(rawId);
    }

    final purpose = _text(row['purpose']);
    final name = _text(row['name']);
    final reference = _text(row['requestId']);
    return UserTransaction(
      id: id,
      // Escrow is money held for the stylist: shown as incoming.
      type: isPouch ? 'earning' : purpose?.toLowerCase(),
      amount: amount.toDouble(),
      description: purpose == null
          ? null
          : name == null || name == 'Me'
              ? purpose
              : '$purpose · $name',
      status: _text(row['status'])?.toLowerCase(),
      reference: reference,
      createdAt: _parseRequestTime(row['requestTime']),
      isEscrow: isPouch,
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed == 'N/A' ? null : trimmed;
  }

  static DateTime? _parseRequestTime(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    try {
      // No offset is sent: read it as device-local wall-clock time, which
      // matches the server for South African devices.
      return DateFormat('MMM dd, yyyy, HH:mm:ss', 'en_US').parse(value.trim());
    } on FormatException {
      return DateTime.tryParse(value);
    }
  }
  int? id;
  String? type;
  double? amount;
  String? description;
  String? status;
  String? reference;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  /// Escrow held against an approved booking (a `/stylist/earnings` pouch
  /// row). The wallet API never sends these.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isEscrow;

  /// The booking an appointment payment paid for; null for every other row.
  @JsonKey(includeFromJson: false, includeToJson: false)
  TransactionAppointment? appointment;

  /// `wallet`, `card` or `deposit` for an appointment payment, when known.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? paymentMethod;

  /// A payment for a booking (not a Payment Request, top-up, refund, ...).
  bool get isAppointmentPayment => type == 'payment' && appointment != null;

  Map<String, dynamic> toJson() => _$UserTransactionToJson(this);
}
