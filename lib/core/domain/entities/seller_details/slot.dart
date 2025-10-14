import 'package:json_annotation/json_annotation.dart';

part 'slot.g.dart';

@JsonSerializable()
class Slot {
  int? id;
  @JsonKey(name: 'stylist_schedule_id')
  String? stylistScheduleId;
  String? from;
  String? to;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  Slot({
    this.id,
    this.stylistScheduleId,
    this.from,
    this.to,
    this.createdAt,
    this.updatedAt,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);

  Map<String, dynamic> toJson() => _$SlotToJson(this);
}
