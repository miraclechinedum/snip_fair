import 'package:json_annotation/json_annotation.dart';

import 'notification_datum.dart';

part 'notifications_list.g.dart';

@JsonSerializable()
class NotificationsList {
  List<NotificationDatum>? data;
  String? path;
  @JsonKey(name: 'per_page')
  int? perPage;
  @JsonKey(name: 'next_cursor')
  String? nextCursor;
  @JsonKey(name: 'next_page_url')
  String? nextPageUrl;
  @JsonKey(name: 'prev_cursor')
  String? prevCursor;
  @JsonKey(name: 'prev_page_url')
  String? prevPageUrl;

  NotificationsList({
    this.data,
    this.path,
    this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory NotificationsList.fromJson(Map<String, dynamic> json) {
    return _$NotificationsListFromJson(json);
  }

  Map<String, dynamic> toJson() => _$NotificationsListToJson(this);
}
