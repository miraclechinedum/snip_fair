// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerWallet _$CustomerWalletFromJson(Map<String, dynamic> json) =>
    CustomerWallet(
      balance: (json['balance'] as num?)?.toInt(),
      escrowBalance: (json['escrow_balance'] as num?)?.toInt(),
      stats: json['stats'] == null
          ? null
          : Stats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CustomerWalletToJson(CustomerWallet instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'escrow_balance': instance.escrowBalance,
      'stats': instance.stats,
    };
