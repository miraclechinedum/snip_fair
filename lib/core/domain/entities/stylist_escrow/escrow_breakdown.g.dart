// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'escrow_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EscrowBreakdown _$EscrowBreakdownFromJson(Map<String, dynamic> json) =>
    EscrowBreakdown(
      success: json['success'] as bool?,
      escrowTotal: escrowToDouble(json['escrow_total']),
      count: (json['count'] as num?)?.toInt(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => EscrowItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EscrowBreakdownToJson(EscrowBreakdown instance) =>
    <String, dynamic>{
      'success': instance.success,
      'escrow_total': instance.escrowTotal,
      'count': instance.count,
      'items': instance.items,
    };
