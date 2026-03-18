import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/apointment/location_service.dart';


part 'customer.g.dart';

@JsonSerializable()
class Customer {

  Customer({
    this.id,
    this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.phone,
    this.country,
    this.bio,
    this.type,
    this.role,
    this.avatar,
    this.lastLoginAt,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.balance,
    this.isFeatured,
    this.useLocation,
    this.subscriptionStatus,
    this.availability,
    this.plan,
    this.locationService,
    this.stylistProfile,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return _$CustomerFromJson(json);
  }
  int? id;
  String? name;
  @JsonKey(name: 'first_name')
  String? firstName;
  @JsonKey(name: 'last_name')
  String? lastName;
  String? email;
  @JsonKey(name: 'email_verified_at')
  DateTime? emailVerifiedAt;
  @JsonKey(name: 'phone_verified_at')
  dynamic phoneVerifiedAt;
  String? phone;
  String? country;
  String? bio;
  String? type;
  String? role;
  dynamic avatar;
  @JsonKey(name: 'last_login_at')
  dynamic lastLoginAt;
  String? status;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  int? balance;
  @JsonKey(name: 'is_featured')
  bool? isFeatured;
  @JsonKey(name: 'use_location')
  bool? useLocation;
  @JsonKey(name: 'subscription_status')
  String? subscriptionStatus;
  bool? availability;
  String? plan;
  @JsonKey(name: 'location_service')
  LocationService? locationService;
  @JsonKey(name: 'stylist_profile')
  dynamic stylistProfile;

  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}
