import 'package:json_annotation/json_annotation.dart';

part 'social.g.dart';

@JsonSerializable()
class Social {
  @JsonKey(name: 'social_app')
  String? socialApp;
  String? url;

  Social({this.socialApp, this.url});

  factory Social.fromJson(Map<String, dynamic> json) {
    return _$SocialFromJson(json);
  }

  Map<String, dynamic> toJson() => _$SocialToJson(this);
}
