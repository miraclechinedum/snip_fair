import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class Settings {
  Settings({
    this.id,
    this.userId,
    this.automaticPayout,
    this.instantPayout,
    this.payoutFrequency,
    this.payoutDay,
    this.enableMobileAppointments,
    this.enableShopAppointments,
    this.createdAt,
    this.updatedAt,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return _$SettingsFromJson(json);
  }
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'automatic_payout')
  bool? automaticPayout;
  @JsonKey(name: 'instant_payout')
  bool? instantPayout;
  @JsonKey(name: 'payout_frequency')
  String? payoutFrequency;
  @JsonKey(name: 'payout_day')
  String? payoutDay;
  @JsonKey(name: 'enable_mobile_appointments')
  bool? enableMobileAppointments;
  @JsonKey(name: 'enable_shop_appointments')
  bool? enableShopAppointments;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  Settings copyWith({
    int? id,
    String? userId,
    bool? automaticPayout,
    bool? instantPayout,
    String? payoutFrequency,
    String? payoutDay,
    bool? enableMobileAppointments,
    bool? enableShopAppointments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Settings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      automaticPayout: automaticPayout ?? this.automaticPayout,
      instantPayout: instantPayout ?? this.instantPayout,
      payoutFrequency: payoutFrequency ?? this.payoutFrequency,
      payoutDay: payoutDay ?? this.payoutDay,
      enableMobileAppointments: enableMobileAppointments ?? this.enableMobileAppointments,
      enableShopAppointments: enableShopAppointments ?? this.enableShopAppointments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
