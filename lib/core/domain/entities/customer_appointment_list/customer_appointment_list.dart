import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';


part 'customer_appointment_list.g.dart';

@JsonSerializable()
class CustomerAppointmentList {

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
  List<CustomerAppointment>? data;
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

  Map<String, dynamic> toJson() => _$CustomerAppointmentListToJson(this);
}
