import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {

  Category({
    this.id,
    this.name,
    this.description,
    this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.banner,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return _$CategoryFromJson(json);
  }
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

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
