class CheckoutPaymentData {
  const CheckoutPaymentData({
    this.appointmentId,
    this.bookingStatus,
    this.isInitialized,
    this.processor,
    this.depositId,
    this.checkoutId,
    this.redirectUrl,
  });

  factory CheckoutPaymentData.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : json;
    return CheckoutPaymentData(
      appointmentId: _asString(json['appointment_id']),
      bookingStatus: _asString(json['status']),
      isInitialized: payment['status'] as bool?,
      processor: _asString(payment['processor']),
      depositId: _asString(payment['deposit_id']),
      checkoutId: _asString(payment['checkoutId']),
      redirectUrl: _asString(payment['redirectUrl']),
    );
  }

  final String? appointmentId;
  final String? bookingStatus;
  final bool? isInitialized;
  final String? processor;
  final String? depositId;
  final String? checkoutId;
  final String? redirectUrl;

  bool get canOpenCheckout =>
      isInitialized == true &&
      depositId != null &&
      redirectUrl != null &&
      redirectUrl!.isNotEmpty;
}

String? _asString(Object? value) => value?.toString();
