import 'package:json_annotation/json_annotation.dart';

import 'package:snip_fair/core/domain/entities/apointment/category.dart';

part 'portfolio.g.dart';

@JsonSerializable()
class Portfolio {
  int? id;
  @JsonKey(name: 'user_id')
  int? userId;
  String? title;
  @JsonKey(name: 'category_id')
  String? categoryId;
  int? price;
  String? duration;
  String? description;
  String? tags;
  @JsonKey(name: 'media_urls')
  List<String>? mediaUrls;
  @JsonKey(name: 'visits_count')
  int? visitsCount;
  bool? status;
  @JsonKey(name: 'is_available')
  bool? isAvailable;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  Category? category;

  Portfolio({
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
    this.category,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return _$PortfolioFromJson(json);
  }

  Map<String, dynamic> toJson() => _$PortfolioToJson(this);
}
