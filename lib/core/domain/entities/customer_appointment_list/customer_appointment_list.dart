import 'package:json_annotation/json_annotation.dart';

import 'customer_appointment.dart';

part 'customer_appointment_list.g.dart';

@JsonSerializable()
class CustomerAppointmentList {
  List<CustomerAppointment>? data;
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

  CustomerAppointmentList({
    this.data,
    this.path,
    this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory CustomerAppointmentList.fromJson(Map<String, dynamic> json) {
    return _$CustomerAppointmentListFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CustomerAppointmentListToJson(this);
}
