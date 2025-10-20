// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_portfolio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerPortfolio _$SellerPortfolioFromJson(Map<String, dynamic> json) =>
    SellerPortfolio(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      title: json['title'] as String?,
      categoryId: json['category_id'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      duration: json['duration'] as String?,
      description: json['description'] as String?,
      tags: json['tags'] as String?,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      visitsCount: json['visits_count'],
      status: json['status'] as bool?,
      isAvailable: json['is_available'] as bool?,
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      averageRating: (json['average_rating'] as num?)?.toInt(),
      reviewsCount: (json['reviews_count'] as num?)?.toInt(),
      portfolioLikesCount: (json['portfolio_likes_count'] as num?)?.toInt(),
      trending: (json['trending'] as num?)?.toInt(),
      appointmentsCount: (json['appointments_count'] as num?)?.toInt(),
      favourite: json['favourite'] as bool?,
      category: json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      distance: (json['distance'] as num?)?.toInt(),
      sampleImages: (json['sample_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SellerPortfolioToJson(SellerPortfolio instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'category_id': instance.categoryId,
      'price': instance.price,
      'duration': instance.duration,
      'description': instance.description,
      'tags': instance.tags,
      'media_urls': instance.mediaUrls,
      'visits_count': instance.visitsCount,
      'status': instance.status,
      'is_available': instance.isAvailable,
      'deleted_at': instance.deletedAt,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'average_rating': instance.averageRating,
      'reviews_count': instance.reviewsCount,
      'portfolio_likes_count': instance.portfolioLikesCount,
      'trending': instance.trending,
      'appointments_count': instance.appointmentsCount,
      'favourite': instance.favourite,
      'category': instance.category,
      'user': instance.user,
      'distance': instance.distance,
      'sample_images': instance.sampleImages,
    };
