enum PaymentRequestStatus {
  pending,
  accepted,
  declined,
  paid,
  cancelled,
  expired;

  static PaymentRequestStatus fromString(String value) {
    return PaymentRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentRequestStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case PaymentRequestStatus.pending:
        return 'Pending';
      case PaymentRequestStatus.accepted:
        return 'Accepted';
      case PaymentRequestStatus.declined:
        return 'Declined';
      case PaymentRequestStatus.paid:
        return 'Paid';
      case PaymentRequestStatus.cancelled:
        return 'Cancelled';
      case PaymentRequestStatus.expired:
        return 'Expired';
    }
  }
}
