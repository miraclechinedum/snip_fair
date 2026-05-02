import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/portfolio.dart';

part 'work_item.g.dart';

@JsonSerializable()
class WorkItem {
  WorkItem({
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

  factory WorkItem.fromJson(Map<String, dynamic> json) => _$WorkItemFromJson(json);

  factory WorkItem.fromPortfolio(Portfolio portfolio) {
    return WorkItem(
      id: portfolio.id,
      userId: portfolio.userId,
      title: portfolio.title,
      categoryId: portfolio.categoryId,
      price: portfolio.price,
      duration: portfolio.duration,
      description: portfolio.description,
      tags: portfolio.tags,
      mediaUrls: portfolio.mediaUrls,
      visitsCount: portfolio.visitsCount,
      status: portfolio.status,
      isAvailable: portfolio.isAvailable,
      deletedAt: portfolio.deletedAt,
      createdAt: portfolio.createdAt,
      updatedAt: portfolio.updatedAt,
    );
  }
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
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
  String? visitsCount;
  bool? status;
  @JsonKey(name: 'is_available')
  bool? isAvailable;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  @JsonKey(name: 'category')
  WorkCategory? category;
  Map<String, dynamic> toJson() => _$WorkItemToJson(this);
}
