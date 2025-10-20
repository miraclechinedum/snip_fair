import 'package:json_annotation/json_annotation.dart';

import 'category.dart';
import 'user.dart';

part 'seller_portfolio.g.dart';

@JsonSerializable()
class SellerPortfolio {
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
  String? title;
  @JsonKey(name: 'category_id')
  String? categoryId;
  double? price;
  String? duration;
  String? description;
  String? tags;
  @JsonKey(name: 'media_urls')
  List<String>? mediaUrls;
  @JsonKey(name: 'visits_count')
  dynamic visitsCount;
  bool? status;
  @JsonKey(name: 'is_available')
  bool? isAvailable;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  @JsonKey(name: 'average_rating')
  int? averageRating;
  @JsonKey(name: 'reviews_count')
  int? reviewsCount;
  @JsonKey(name: 'portfolio_likes_count')
  int? portfolioLikesCount;
  int? trending;
  @JsonKey(name: 'appointments_count')
  int? appointmentsCount;
  bool? favourite;
  Category? category;
  User? user;
  int? distance;
  @JsonKey(name: 'sample_images')
  List<String>? sampleImages;

  SellerPortfolio({
    this.id,
    this.userId,
    this.title,
    this.categoryId,
    this.price,
    this.duration,
    this.description,
    this.tags,
    this.mediaUrls,
    this.visitsCount,
    this.status,
    this.isAvailable,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.averageRating,
    this.reviewsCount,
    this.portfolioLikesCount,
    this.trending,
    this.appointmentsCount,
    this.favourite,
    this.category,
    this.user,
    this.distance,
    this.sampleImages,
  });

  factory SellerPortfolio.fromJson(Map<String, dynamic> json) =>
      _$SellerPortfolioFromJson(json);

  Map<String, dynamic> toJson() => _$SellerPortfolioToJson(this);
}
