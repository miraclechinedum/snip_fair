import 'package:json_annotation/json_annotation.dart';

part 'stylist_settings.g.dart';

@JsonSerializable()
class StylistSettings {
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

  StylistSettings({
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

  factory StylistSettings.fromJson(Map<String, dynamic> json) {
    return _$StylistSettingsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$StylistSettingsToJson(this);
}
