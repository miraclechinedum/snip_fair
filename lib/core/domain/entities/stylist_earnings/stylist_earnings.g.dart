// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stylist_earnings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StylistEarnings _$StylistEarningsFromJson(Map<String, dynamic> json) =>
    StylistEarnings(
      statistics: json['statistics'] == null
          ? null
          : Statistics.fromJson(json['statistics'] as Map<String, dynamic>),
      transactions: json['transactions'] as List<dynamic>?,
      paymentMethod: json['payment_method'] == null
          ? null
          : PaymentMethod.fromJson(
              json['payment_method'] as Map<String, dynamic>),
      paymentMethods: (json['payment_methods'] as List<dynamic>?)
          ?.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: json['settings'] == null
          ? null
          : Settings.fromJson(json['settings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StylistEarningsToJson(StylistEarnings instance) =>
    <String, dynamic>{
      'statistics': instance.statistics,
      'transactions': instance.transactions,
      'payment_method': instance.paymentMethod,
      'payment_methods': instance.paymentMethods,
      'settings': instance.settings,
    };
