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

  bool get isSuccessful => status == 'successful' && settled == true;
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
}
