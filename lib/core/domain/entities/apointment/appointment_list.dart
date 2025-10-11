import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';

part 'appointment_list.g.dart';

@JsonSerializable()
class AppointmentList {
  AppointmentList({
    this.data,
    this.path,
    this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory AppointmentList.fromJson(Map<String, dynamic> json) {
    return _$AppointmentListFromJson(json);
  }
  List<Appointment>? data;
  String? path;
  @JsonKey(name: 'per_page')
  int? perPage;
  @JsonKey(name: 'next_cursor')
  dynamic nextCursor;
  @JsonKey(name: 'next_page_url')
  dynamic nextPageUrl;
  @JsonKey(name: 'prev_cursor')
  dynamic prevCursor;
  @JsonKey(name: 'prev_page_url')
  dynamic prevPageUrl;

  Map<String, dynamic> toJson() => _$AppointmentListToJson(this);
}
