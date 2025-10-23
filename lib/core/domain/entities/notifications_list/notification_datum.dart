import 'package:json_annotation/json_annotation.dart';

part 'notification_datum.g.dart';
  
@JsonSerializable()
class NotificationDatum {
  int? id;
  String? type;
  @JsonKey(name: 'type_identifier')
  String? typeIdentifier;
  String? title;
  String? description;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  String? priority;
  @JsonKey(name: 'is_read')
  bool? isRead;

  NotificationDatum({
    this.id,
    this.type,
    this.typeIdentifier,
    this.title,
    this.description,
    this.createdAt,
    this.priority,
    this.isRead,
  });

  factory NotificationDatum.fromJson(Map<String, dynamic> json) => _$NotificationDatumFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDatumToJson(this);
}
