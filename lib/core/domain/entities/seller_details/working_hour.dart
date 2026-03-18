import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/seller_details/slot.dart';

part 'working_hour.g.dart';

@JsonSerializable()
class WorkingHour {
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

  Map<String, dynamic> toJson() => _$WorkingHourToJson(this);
}
