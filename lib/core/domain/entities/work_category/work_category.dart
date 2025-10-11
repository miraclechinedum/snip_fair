import 'package:json_annotation/json_annotation.dart';

part 'work_category.g.dart';

@JsonSerializable()
class WorkCategory {
  int? id;
  String? name;
  String? description;
  bool? status;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  String? banner;

  WorkCategory({
    this.id,
    this.name,
    this.description,
    this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.banner,
  });

  factory WorkCategory.fromJson(Map<String, dynamic> json) {
    return _$WorkCategoryFromJson(json);
  }

  Map<String, dynamic> toJson() => _$WorkCategoryToJson(this);
}
