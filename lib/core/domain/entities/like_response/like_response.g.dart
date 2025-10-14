// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'like_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LikeResponse _$LikeResponseFromJson(Map<String, dynamic> json) => LikeResponse(
      success: json['success'] as bool?,
      isLiked: json['is_liked'] as bool?,
      likesCount: (json['likes_count'] as num?)?.toInt(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$LikeResponseToJson(LikeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'is_liked': instance.isLiked,
      'likes_count': instance.likesCount,
      'message': instance.message,
    };
