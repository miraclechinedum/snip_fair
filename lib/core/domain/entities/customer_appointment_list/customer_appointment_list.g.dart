// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_appointment_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerAppointmentList _$CustomerAppointmentListFromJson(
        Map<String, dynamic> json) =>
    CustomerAppointmentList(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => CustomerAppointment.fromJson(e as Map<String, dynamic>))
          .toList(),
      path: json['path'] as String?,
      perPage: (json['per_page'] as num?)?.toInt(),
      nextCursor: json['next_cursor'],
      nextPageUrl: json['next_page_url'],
      prevCursor: json['prev_cursor'],
      prevPageUrl: json['prev_page_url'],
    );

Map<String, dynamic> _$CustomerAppointmentListToJson(
        CustomerAppointmentList instance) =>
    <String, dynamic>{
      'data': instance.data,
      'path': instance.path,
      'per_page': instance.perPage,
      'next_cursor': instance.nextCursor,
      'next_page_url': instance.nextPageUrl,
      'prev_cursor': instance.prevCursor,
      'prev_page_url': instance.prevPageUrl,
    };
