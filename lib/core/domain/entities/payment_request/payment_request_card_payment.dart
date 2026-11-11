import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';

/// HTTP 200 body of `POST /payment-requests/{id}/pay` with
/// `{"payment_method": "card"}`:
/// `{message, status: "pending", payment_method: "card",
///   payment: {payment_id, checkout_id, redirect_url, reused}, data}`.
///
/// Nothing is paid yet: only the payer-only status endpoint can say so.
class PaymentRequestCardCheckout {
  const PaymentRequestCardCheckout({
    this.paymentId,
    this.checkoutId,
    this.redirectUrl,
    this.reused = false,
    this.paymentRequest,
  });

  factory PaymentRequestCardCheckout.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final data = json['data'];
    return PaymentRequestCardCheckout(
      paymentId: payment['payment_id']?.toString(),
      checkoutId: payment['checkout_id']?.toString(),
      redirectUrl: payment['redirect_url']?.toString(),
      reused: payment['reused'] == true,
      paymentRequest:
          data is Map<String, dynamic> ? PaymentRequest.fromJson(data) : null,
    );
  }

  final String? paymentId;
  final String? checkoutId;
  final String? redirectUrl;

  /// Laravel handed back the attempt's existing checkout instead of a new one.
  final bool reused;
  final PaymentRequest? paymentRequest;

  bool get canOpenCheckout =>
      paymentId != null &&
      paymentId!.isNotEmpty &&
      redirectUrl != null &&
      redirectUrl!.isNotEmpty;

  /// For the shared hosted-checkout WebView, which only needs the URL.
  CheckoutPaymentData toCheckoutData() => CheckoutPaymentData(
        isInitialized: true,
        processor: 'peachpayment',
        checkoutId: checkoutId,
        redirectUrl: redirectUrl,
      );
}

/// Body of `GET /payment-requests/{id}/payments/{paymentId}/status` (payer
/// only). [paid] is the only success signal.
class PaymentRequestCardPaymentStatus {
  const PaymentRequestCardPaymentStatus({
    this.paymentId,
    this.paymentStatus,
    this.verification,
    this.paid = false,
    this.paymentRequestStatus,
    this.message,
    this.paymentRequest,
  });

  factory PaymentRequestCardPaymentStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return PaymentRequestCardPaymentStatus(
      paymentId: json['payment_id']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      verification: json['verification']?.toString(),
      // Strictly `true`: anything else is not a payment.
      paid: json['paid'] == true,
      paymentRequestStatus: json['payment_request_status']?.toString(),
      message: json['message'] is String ? json['message'] as String : null,
      paymentRequest:
          data is Map<String, dynamic> ? PaymentRequest.fromJson(data) : null,
    );
  }

  final String? paymentId;

  /// `pending`, `successful`, `failed`, `cancelled`, `requires_review`,
  /// `requires_refund` or `closed` (others are treated as not final).
  final String? paymentStatus;
  final String? verification;
  final bool paid;
  final String? paymentRequestStatus;

  /// Laravel's customer-facing explanation.
  final String? message;
  final PaymentRequest? paymentRequest;

  /// The card was not charged; a new card payment may be started.
  bool get isFailedOrCancelled =>
      !paid && (paymentStatus == 'failed' || paymentStatus == 'cancelled');

  /// Final without paying the request: charged and awaiting a refund, or
  /// closed by support. Not retried; the customer may pay again.
  bool get isEndedUnpaid =>
      !paid &&
      (paymentStatus == 'requires_refund' || paymentStatus == 'closed');
}
