import 'package:json_annotation/json_annotation.dart';

import 'availability.dart';
import 'category.dart';
import 'review.dart';
import 'stylist_profile.dart';
import 'working_hour.dart';

part 'seller_details.g.dart';

@JsonSerializable()
class SellerDetails {
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
  String? avatar;
  @JsonKey(name: 'last_login_at')
  DateTime? lastLoginAt;
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
  List<Category>? categories;
  @JsonKey(name: 'portfolio_visits_count')
  int? portfolioVisitsCount;
  @JsonKey(name: 'profile_visits_count')
  int? profileVisitsCount;
  @JsonKey(name: 'completed_appointments_count')
  int? completedAppointmentsCount;
  @JsonKey(name: 'years_of_experience')
  int? yearsOfExperience;
  @JsonKey(name: 'average_rating')
  int? averageRating;
  @JsonKey(name: 'reviews_count')
  int? reviewsCount;
  @JsonKey(name: 'portfolio_likes_count')
  int? portfolioLikesCount;
  int? trending;
  @JsonKey(name: 'appointments_count')
  int? appointmentsCount;
  @JsonKey(name: 'min_price')
  int? minPrice;
  @JsonKey(name: 'max_price')
  int? maxPrice;
  bool? favourite;
  double? distance;
  @JsonKey(name: 'profile_likes_count')
  int? profileLikesCount;
  @JsonKey(name: 'subscription_status')
  String? subscriptionStatus;
  Availability? availability;
  String? plan;
  @JsonKey(name: 'stylist_profile')
  StylistProfile? stylistProfile;
  @JsonKey(name: 'stylist_certifications')
  List<dynamic>? stylistCertifications;
  @JsonKey(name: 'response_time')
  String? responseTime;
  @JsonKey(name: 'next_available')
  String? nextAvailable;
  @JsonKey(name: 'media_urls')
  List<String>? mediaUrls;
  List<Review>? reviews;
  @JsonKey(name: 'working_hours')
  List<WorkingHour>? workingHours;

  SellerDetails({
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
    this.categories,
    this.portfolioVisitsCount,
    this.profileVisitsCount,
    this.yearsOfExperience,
    this.averageRating,
    this.reviewsCount,
    this.portfolioLikesCount,
    this.trending,
    this.appointmentsCount,
    this.minPrice,
    this.maxPrice,
    this.favourite,
    this.distance,
    this.profileLikesCount,
    this.subscriptionStatus,
    this.availability,
    this.plan,
    this.stylistProfile,
    this.stylistCertifications,
    this.responseTime,
    this.nextAvailable,
    this.mediaUrls,
    this.reviews,
    this.workingHours,
  });

  factory SellerDetails.fromJson(Map<String, dynamic> json) {
    return _$SellerDetailsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$SellerDetailsToJson(this);
}
