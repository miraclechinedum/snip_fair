import 'package:json_annotation/json_annotation.dart';

import 'appointment.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  int? id;
  String? rating;
  String? comment;
  @JsonKey(name: 'appointment_id')
  String? appointmentId;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  Appointment? appointment;

  Review({
    this.id,
    this.rating,
    this.comment,
    this.appointmentId,
    this.userId,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.appointment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return _$ReviewFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}
