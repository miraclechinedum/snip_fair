import 'package:json_annotation/json_annotation.dart';

part 'notifications.g.dart';

@JsonSerializable()
class Notifications {
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'booking_confirmation')
  bool? bookingConfirmation;
  @JsonKey(name: 'appointment_reminders')
  bool? appointmentReminders;
  @JsonKey(name: 'favorite_stylist_update')
  bool? favoriteStylistUpdate;
  @JsonKey(name: 'promotions_offers')
  bool? promotionsOffers;
  @JsonKey(name: 'review_reminders')
  bool? reviewReminders;
  @JsonKey(name: 'payment_confirmations')
  bool? paymentConfirmations;
  @JsonKey(name: 'email_notifications')
  bool? emailNotifications;
  @JsonKey(name: 'push_notifications')
  bool? pushNotifications;
  @JsonKey(name: 'sms_notifications')
  bool? smsNotifications;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  Notifications({
    this.id,
    this.userId,
    this.bookingConfirmation,
    this.appointmentReminders,
    this.favoriteStylistUpdate,
    this.promotionsOffers,
    this.reviewReminders,
    this.paymentConfirmations,
    this.emailNotifications,
    this.pushNotifications,
    this.smsNotifications,
    this.createdAt,
    this.updatedAt,
  });

  factory Notifications.fromJson(Map<String, dynamic> json) {
    return _$NotificationsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$NotificationsToJson(this);
}
