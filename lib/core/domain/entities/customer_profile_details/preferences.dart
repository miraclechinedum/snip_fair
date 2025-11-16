import 'package:json_annotation/json_annotation.dart';

part 'preferences.g.dart';

@JsonSerializable()
class Preferences {
  int? id;
  @JsonKey(name: 'user_id')
  dynamic userId;
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

  Preferences copyWith({
    int? id,
    dynamic? userId,
    String? preferredTime,
    String? preferredStylist,
    bool? autoRebooking,
    bool? enableMobileAppointment,
    bool? emailReminders,
    bool? smsReminders,
    bool? phoneReminders,
    String? language,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? useLocation,
  }) {
    return Preferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      preferredTime: preferredTime ?? this.preferredTime,
      preferredStylist: preferredStylist ?? this.preferredStylist,
      autoRebooking: autoRebooking ?? this.autoRebooking,
      enableMobileAppointment:
          enableMobileAppointment ?? this.enableMobileAppointment,
      emailReminders: emailReminders ?? this.emailReminders,
      smsReminders: smsReminders ?? this.smsReminders,
      phoneReminders: phoneReminders ?? this.phoneReminders,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      useLocation: useLocation ?? this.useLocation,
    );
  }
}
