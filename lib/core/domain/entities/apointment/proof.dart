import 'package:json_annotation/json_annotation.dart';

part 'proof.g.dart';

@JsonSerializable()
class Proof {
  int? id;
  @JsonKey(name: 'media_urls')
  List<String>? mediaUrls;
  String? comment;
  @JsonKey(name: 'appointment_id')
  int? appointmentId;
  @JsonKey(name: 'user_id')
  int? userId;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  Proof({
    this.id,
    this.mediaUrls,
    this.comment,
    this.appointmentId,
    this.userId,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Proof.fromJson(Map<String, dynamic> json) => _$ProofFromJson(json);

  Map<String, dynamic> toJson() => _$ProofToJson(this);
}
