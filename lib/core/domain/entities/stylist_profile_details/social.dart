import 'package:json_annotation/json_annotation.dart';

part 'social.g.dart';

@JsonSerializable()
class Social {

  Social({this.socialApp, this.url});

  factory Social.fromJson(Map<String, dynamic> json) {
    return _$SocialFromJson(json);
  }
  @JsonKey(name: 'social_app')
  String? socialApp;
  String? url;

  Map<String, dynamic> toJson() => _$SocialToJson(this);
}
