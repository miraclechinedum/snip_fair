import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';

/// Body of `POST /customer/appointment/{id}/tip`.
///
/// - Wallet (HTTP 200): `{success, code: "tipped", payment_method: "wallet",
///   message, tip_amount, new_wallet_balance}` — the tip has been sent.
/// - Card (HTTP 201): `{success, code: "checkout_started", status: "pending",
///   payment_method: "card", tip_amount, payment: {deposit_id, checkout_id,
///   redirect_url, status_url}}` — nothing is paid yet; the outcome comes
///   from the deposit status endpoint.
class TipResponse {
  TipResponse({
    required this.success,
    required this.message,
    required this.tipAmount,
    this.newWalletBalance,
    this.code,
    this.paymentMethod,
    this.checkout,
  });

  factory TipResponse.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    final code = json['code'] is String ? json['code'] as String : null;
    return TipResponse(
      success: json['success'] == true,
      message: json['message'] is String ? json['message'] as String : '',
      tipAmount: _number(json['tip_amount'])?.toDouble() ?? 0,
      newWalletBalance: _number(json['new_wallet_balance'])?.toDouble(),
      code: code,
      paymentMethod: json['payment_method'] is String
          ? json['payment_method'] as String
          : null,
      checkout: payment is Map<String, dynamic> && code == 'checkout_started'
          ? CheckoutPaymentData(
              isInitialized: json['success'] == true,
              processor: 'peachpayment',
              depositId: payment['deposit_id']?.toString(),
              checkoutId: payment['checkout_id']?.toString(),
              redirectUrl: payment['redirect_url']?.toString(),
            )
          : null,
    );
  }

  final bool success;
  final String message;
  final double tipAmount;

  /// Wallet tips only.
  final double? newWalletBalance;
  final String? code;
  final String? paymentMethod;

  /// Card tips only: the hosted checkout to open.
  final CheckoutPaymentData? checkout;

  /// A wallet tip that has been sent.
  bool get isTipped => success && code == 'tipped';

  /// A card tip whose checkout can be opened (nothing is paid yet).
  bool get isCheckoutStarted =>
      success && code == 'checkout_started' && (checkout?.canOpenCheckout ?? false);
}

num? _number(Object? value) =>
    value is num ? value : (value is String ? num.tryParse(value) : null);
