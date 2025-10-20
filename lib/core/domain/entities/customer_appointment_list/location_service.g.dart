// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationService _$LocationServiceFromJson(Map<String, dynamic> json) =>
    LocationService(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      locationAccuracy: json['location_accuracy'] as String?,
      locationUpdatedAt: json['location_updated_at'] == null
          ? null
          : DateTime.parse(json['location_updated_at'] as String),
      locationPermissionGranted: json['location_permission_granted'] as bool?,
      locationConsentGiven: json['location_consent_given'] as bool?,
      locationConsentDate: json['location_consent_date'],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$LocationServiceToJson(LocationService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'location_accuracy': instance.locationAccuracy,
      'location_updated_at': instance.locationUpdatedAt?.toIso8601String(),
      'location_permission_granted': instance.locationPermissionGranted,
      'location_consent_given': instance.locationConsentGiven,
      'location_consent_date': instance.locationConsentDate,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
