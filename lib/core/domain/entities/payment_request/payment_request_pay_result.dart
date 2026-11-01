import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';

/// HTTP 200 body of `POST /payment-requests/{id}/pay`:
/// `{message, code, payment_method, data, new_wallet_balance}`.
///
/// The request is paid only when [isPaid] — `code == "paid"` — regardless of
/// the HTTP status alone.
class PaymentRequestPayResult {
  const PaymentRequestPayResult({
    this.code,
    this.message,
    this.paymentRequest,
    this.newWalletBalance,
  });

  factory PaymentRequestPayResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final balance = json['new_wallet_balance'];
    return PaymentRequestPayResult(
      code: json['code'] is String ? json['code'] as String : null,
      message: json['message'] is String ? json['message'] as String : null,
      paymentRequest: data is Map<String, dynamic>
          ? PaymentRequest.fromJson(data)
          : null,
      newWalletBalance: balance is num
          ? balance
          : balance is String
              ? num.tryParse(balance)
              : null,
    );
  }

  final String? code;
  final String? message;
  final PaymentRequest? paymentRequest;
  final num? newWalletBalance;

  bool get isPaid => code == 'paid';
}
