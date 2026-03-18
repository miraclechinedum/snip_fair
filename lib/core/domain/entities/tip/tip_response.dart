class TipResponse {

  TipResponse({
    required this.success,
    required this.message,
    required this.tipAmount,
    required this.newWalletBalance,
  });

  factory TipResponse.fromJson(Map<String, dynamic> json) => TipResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        tipAmount: (json['tip_amount'] as num).toDouble(),
        newWalletBalance: (json['new_wallet_balance'] as num).toDouble(),
      );
  final bool success;
  final String message;
  final double tipAmount;
  final double newWalletBalance;
}
