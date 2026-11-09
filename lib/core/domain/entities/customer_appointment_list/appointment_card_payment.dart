/// What happened to the card payment of an unpaid booking: the `card_payment`
/// object Laravel adds to a customer's `processing` (not yet paid) card
/// bookings. Null for every other booking.
class AppointmentCardPayment {
  const AppointmentCardPayment({
    this.status,
    this.depositId,
    this.canRetry = false,
    this.message,
  });

  /// Null unless [json] is an object; never throws on odd values.
  static AppointmentCardPayment? tryParse(Object? json) {
    if (json is! Map) return null;
    final deposit = json['deposit_id'];
    return AppointmentCardPayment(
      status: json['status'] is String ? json['status'] as String : null,
      depositId: deposit is String || deposit is num ? '$deposit' : null,
      canRetry: json['can_retry'] == true,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  /// `awaiting_confirmation` (Peach has not confirmed the latest attempt yet),
  /// `cancelled` or `failed` (confirmed; the booking is unpaid).
  final String? status;

  /// The latest payment attempt, for "Check Payment Status".
  final String? depositId;

  /// The same booking may be paid again (`POST .../payment/card`).
  final bool canRetry;

  /// Laravel's explanation for the customer.
  final String? message;

  bool get isAwaitingConfirmation => status == 'awaiting_confirmation';

  /// Replaces the bare "Processing" an unpaid card booking used to show.
  String get statusLabel => switch (status) {
        'cancelled' => 'Payment cancelled',
        'failed' => 'Payment failed',
        _ => 'Awaiting payment confirmation',
      };
}
