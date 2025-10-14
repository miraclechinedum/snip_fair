// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payfast_payment_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PayfastPaymentData _$PayfastPaymentDataFromJson(Map<String, dynamic> json) =>
    PayfastPaymentData(
      status: json['status'] as bool?,
      payfastUuid: json['payfast_uuid'] as String?,
      depositId: (json['deposit_id'] as num?)?.toInt(),
      inSandbox: json['in_sandbox'] as bool?,
      amount: (json['amount'] as num?)?.toInt(),
      paymentUrl: json['payment_url'] as String?,
      successUrl: json['success_url'] as String?,
      cancelUrl: json['cancel_url'] as String?,
    );

Map<String, dynamic> _$PayfastPaymentDataToJson(PayfastPaymentData instance) =>
    <String, dynamic>{
      'status': instance.status,
      'payfast_uuid': instance.payfastUuid,
      'deposit_id': instance.depositId,
      'in_sandbox': instance.inSandbox,
      'amount': instance.amount,
      'payment_url': instance.paymentUrl,
      'success_url': instance.successUrl,
      'cancel_url': instance.cancelUrl,
    };
