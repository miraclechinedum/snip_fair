import 'package:json_annotation/json_annotation.dart';

part 'like_response.g.dart';

@JsonSerializable()
class LikeResponse {
  bool? success;
  @JsonKey(name: 'is_liked')
  bool? isLiked;
  @JsonKey(name: 'likes_count')
  int? likesCount;
  String? message;

  LikeResponse({this.success, this.isLiked, this.likesCount, this.message});

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return _$LikeResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LikeResponseToJson(this);
}
