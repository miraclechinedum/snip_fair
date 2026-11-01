class PaymentReconciliation {
  const PaymentReconciliation({
    this.depositId,
    this.purpose,
    this.status,
    this.settled,
    this.appointmentId,
    this.transactionReference,
    this.amount,
    this.currency,
    this.message,
  });

  factory PaymentReconciliation.fromJson(Map<String, dynamic> json) {
    return PaymentReconciliation(
      depositId: json['deposit_id']?.toString(),
      purpose: json['purpose']?.toString(),
      status: json['status']?.toString(),
      settled: json['settled'] as bool?,
      appointmentId: json['appointment_id']?.toString(),
      transactionReference: json['transaction_reference']?.toString(),
      amount: json['amount'] as num?,
      currency: json['currency']?.toString(),
      message: json['message']?.toString(),
    );
  }

  final String? depositId;
  final String? purpose;
  final String? status;
  final bool? settled;
  final String? appointmentId;
  final String? transactionReference;
  final num? amount;
  final String? currency;
  final String? message;

  /// Appointment-booking success rule: successful *and* settled by this call.
  bool get isSuccessful => status == 'successful' && settled == true;

  /// Wallet top-up rule from the backend contract: an HTTP 200 body with
  /// `status == "successful"` means the wallet holds the money. `settled` is
  /// only true on the one call that credited it (and false when the webhook
  /// credited it first), so it must not decide.
  bool get isVerified => status == 'successful';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
}
