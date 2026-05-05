import 'package:json_annotation/json_annotation.dart';

part 'notifications.g.dart';

@JsonSerializable()
class Notifications {

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
  int? id;
  @JsonKey(name: 'user_id')
  dynamic userId;
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

  Map<String, dynamic> toJson() => _$NotificationsToJson(this);

  Notifications copyWith({
    int? id,
    dynamic userId,
    bool? bookingConfirmation,
    bool? appointmentReminders,
    bool? favoriteStylistUpdate,
    bool? promotionsOffers,
    bool? reviewReminders,
    bool? paymentConfirmations,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notifications(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingConfirmation: bookingConfirmation ?? this.bookingConfirmation,
      appointmentReminders: appointmentReminders ?? this.appointmentReminders,
      favoriteStylistUpdate:
          favoriteStylistUpdate ?? this.favoriteStylistUpdate,
      promotionsOffers: promotionsOffers ?? this.promotionsOffers,
      reviewReminders: reviewReminders ?? this.reviewReminders,
      paymentConfirmations: paymentConfirmations ?? this.paymentConfirmations,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
