import 'package:json_annotation/json_annotation.dart';

import 'slot.dart';

part 'working_hour.g.dart';

@JsonSerializable()
class WorkingHour {
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
  String? day;
  bool? available;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  List<Slot>? slots;

  WorkingHour({
    this.id,
    this.userId,
    this.day,
    this.available,
    this.createdAt,
    this.updatedAt,
    this.slots,
  });

  factory WorkingHour.fromJson(Map<String, dynamic> json) {
    return _$WorkingHourFromJson(json);
  }

  Map<String, dynamic> toJson() => _$WorkingHourToJson(this);
}
