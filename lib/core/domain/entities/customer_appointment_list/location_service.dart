import 'package:json_annotation/json_annotation.dart';

part 'location_service.g.dart';

@JsonSerializable()
class LocationService {
  int? id;
  @JsonKey(name: 'user_id')
  int? userId;
  String? latitude;
  String? longitude;
  @JsonKey(name: 'location_accuracy')
  int? locationAccuracy;
  @JsonKey(name: 'location_updated_at')
  DateTime? locationUpdatedAt;
  @JsonKey(name: 'location_permission_granted')
  bool? locationPermissionGranted;
  @JsonKey(name: 'location_consent_given')
  bool? locationConsentGiven;
  @JsonKey(name: 'location_consent_date')
  dynamic locationConsentDate;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  LocationService({
    this.id,
    this.userId,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.locationUpdatedAt,
    this.locationPermissionGranted,
    this.locationConsentGiven,
    this.locationConsentDate,
    this.createdAt,
    this.updatedAt,
  });

  factory LocationService.fromJson(Map<String, dynamic> json) {
    return _$LocationServiceFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LocationServiceToJson(this);
}
