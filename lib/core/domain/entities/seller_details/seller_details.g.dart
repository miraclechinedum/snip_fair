// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerDetails _$SellerDetailsFromJson(Map<String, dynamic> json) =>
    SellerDetails(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      emailVerifiedAt: json['email_verified_at'] == null
          ? null
          : DateTime.parse(json['email_verified_at'] as String),
      phoneVerifiedAt: json['phone_verified_at'],
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      type: json['type'] as String?,
      role: json['role'] as String?,
      avatar: json['avatar'] as String?,
      lastLoginAt: json['last_login_at'] == null
          ? null
          : DateTime.parse(json['last_login_at'] as String),
      status: json['status'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'],
      balance: (json['balance'] as num?)?.toInt(),
      isFeatured: json['is_featured'] as bool?,
      useLocation: json['use_location'] as bool?,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      portfolioVisitsCount: (json['portfolio_visits_count'] as num?)?.toInt(),
      profileVisitsCount: (json['profile_visits_count'] as num?)?.toInt(),
      yearsOfExperience: (json['years_of_experience'] as num?)?.toInt(),
      averageRating: (json['average_rating'] as num?)?.toInt(),
      reviewsCount: (json['reviews_count'] as num?)?.toInt(),
      portfolioLikesCount: (json['portfolio_likes_count'] as num?)?.toInt(),
      trending: (json['trending'] as num?)?.toInt(),
      appointmentsCount: (json['appointments_count'] as num?)?.toInt(),
      minPrice: (json['min_price'] as num?)?.toInt(),
      maxPrice: (json['max_price'] as num?)?.toInt(),
      favourite: json['favourite'] as bool?,
      distance: (json['distance'] as num?)?.toDouble(),
      profileLikesCount: (json['profile_likes_count'] as num?)?.toInt(),
      subscriptionStatus: json['subscription_status'] as String?,
      availability: json['availability'] == null
          ? null
          : Availability.fromJson(json['availability'] as Map<String, dynamic>),
      plan: json['plan'] as String?,
      stylistProfile: json['stylist_profile'] == null
          ? null
          : StylistProfile.fromJson(
              json['stylist_profile'] as Map<String, dynamic>),
      stylistCertifications: json['stylist_certifications'] as List<dynamic>?,
      responseTime: json['response_time'] as String?,
      nextAvailable: json['next_available'] as String?,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      workingHours: (json['working_hours'] as List<dynamic>?)
          ?.map((e) => WorkingHour.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..completedAppointmentsCount =
        (json['completed_appointments_count'] as num?)?.toInt();

Map<String, dynamic> _$SellerDetailsToJson(SellerDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'email_verified_at': instance.emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': instance.phoneVerifiedAt,
      'phone': instance.phone,
      'country': instance.country,
      'bio': instance.bio,
      'type': instance.type,
      'role': instance.role,
      'avatar': instance.avatar,
      'last_login_at': instance.lastLoginAt?.toIso8601String(),
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt,
      'balance': instance.balance,
      'is_featured': instance.isFeatured,
      'use_location': instance.useLocation,
      'categories': instance.categories,
      'portfolio_visits_count': instance.portfolioVisitsCount,
      'profile_visits_count': instance.profileVisitsCount,
      'completed_appointments_count': instance.completedAppointmentsCount,
      'years_of_experience': instance.yearsOfExperience,
      'average_rating': instance.averageRating,
      'reviews_count': instance.reviewsCount,
      'portfolio_likes_count': instance.portfolioLikesCount,
      'trending': instance.trending,
      'appointments_count': instance.appointmentsCount,
      'min_price': instance.minPrice,
      'max_price': instance.maxPrice,
      'favourite': instance.favourite,
      'distance': instance.distance,
      'profile_likes_count': instance.profileLikesCount,
      'subscription_status': instance.subscriptionStatus,
      'availability': instance.availability,
      'plan': instance.plan,
      'stylist_profile': instance.stylistProfile,
      'stylist_certifications': instance.stylistCertifications,
      'response_time': instance.responseTime,
      'next_available': instance.nextAvailable,
      'media_urls': instance.mediaUrls,
      'reviews': instance.reviews,
      'working_hours': instance.workingHours,
    };
