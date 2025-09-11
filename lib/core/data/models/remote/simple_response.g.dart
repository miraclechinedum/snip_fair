// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SimpleResponse _$SimpleResponseFromJson(Map<String, dynamic> json) =>
    _SimpleResponse(
      status: json['status'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$SimpleResponseToJson(_SimpleResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
    };
