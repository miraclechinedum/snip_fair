import 'package:json_annotation/json_annotation.dart';

part 'payfast_payment_data.g.dart';

@JsonSerializable()
class PayfastPaymentData {
  PayfastPaymentData({
    this.status,
    this.payfastUuid,
    this.depositId,
    this.inSandbox,
    this.amount,
    this.paymentUrl,
    this.successUrl,
    this.cancelUrl,
  });

  factory PayfastPaymentData.fromJson(Map<String, dynamic> json) {
    return _$PayfastPaymentDataFromJson(json);
  }
  bool? status;
  @JsonKey(name: 'payfast_uuid')
  String? payfastUuid;
  @JsonKey(name: 'deposit_id')
  int? depositId;
  @JsonKey(name: 'in_sandbox')
  bool? inSandbox;
  int? amount;
  @JsonKey(name: 'payment_url')
  String? paymentUrl;
  @JsonKey(name: 'success_url')
  String? successUrl;
  @JsonKey(name: 'cancel_url')
  String? cancelUrl;

  Map<String, dynamic> toJson() => _$PayfastPaymentDataToJson(this);
}
