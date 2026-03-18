import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {

  Category({this.id, this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return _$CategoryFromJson(json);
  }
  int? id;
  String? name;

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
