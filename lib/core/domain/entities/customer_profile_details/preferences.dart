import 'package:json_annotation/json_annotation.dart';

part 'preferences.g.dart';

@JsonSerializable()
class Preferences {
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'preferred_time')
  String? preferredTime;
  @JsonKey(name: 'preferred_stylist')
  String? preferredStylist;
  @JsonKey(name: 'auto_rebooking')
  bool? autoRebooking;
  @JsonKey(name: 'enable_mobile_appointment')
  bool? enableMobileAppointment;
  @JsonKey(name: 'email_reminders')
  bool? emailReminders;
  @JsonKey(name: 'sms_reminders')
  bool? smsReminders;
  @JsonKey(name: 'phone_reminders')
  bool? phoneReminders;
  String? language;
  String? currency;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  @JsonKey(name: 'use_location')
  bool? useLocation;

  Preferences({
    this.id,
    this.userId,
    this.preferredTime,
    this.preferredStylist,
    this.autoRebooking,
    this.enableMobileAppointment,
    this.emailReminders,
    this.smsReminders,
    this.phoneReminders,
    this.language,
    this.currency,
    this.createdAt,
    this.updatedAt,
    this.useLocation,
  });

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return _$PreferencesFromJson(json);
  }

  Map<String, dynamic> toJson() => _$PreferencesToJson(this);
}
