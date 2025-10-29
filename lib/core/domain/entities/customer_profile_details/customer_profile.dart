import 'package:json_annotation/json_annotation.dart';

part 'customer_profile.g.dart';

@JsonSerializable()
class CustomerProfile {
  int? id;
  @JsonKey(name: 'user_id')
  dynamic userId;
  @JsonKey(name: 'billing_name')
  String? billingName;
  @JsonKey(name: 'billing_email')
  String? billingEmail;
  @JsonKey(name: 'billing_city')
  dynamic billingCity;
  @JsonKey(name: 'billing_zip')
  dynamic billingZip;
  @JsonKey(name: 'billing_location')
  dynamic billingLocation;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  CustomerProfile({
    this.id,
    this.userId,
    this.billingName,
    this.billingEmail,
    this.billingCity,
    this.billingZip,
    this.billingLocation,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return _$CustomerProfileFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CustomerProfileToJson(this);
}
