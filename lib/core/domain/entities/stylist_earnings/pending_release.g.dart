// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingRelease _$PendingReleaseFromJson(Map<String, dynamic> json) =>
    PendingRelease(
      value: toNumOrNull(json['value']),
      changeText: json['change_text'] as String?,
      isPositive: json['is_positive'] as bool?,
    );

Map<String, dynamic> _$PendingReleaseToJson(PendingRelease instance) =>
    <String, dynamic>{
      'value': instance.value,
      'change_text': instance.changeText,
      'is_positive': instance.isPositive,
    };
