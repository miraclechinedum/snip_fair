import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request_status.dart';

part 'payment_request.g.dart';

// ---------------------------------------------------------------------------
// PaymentRequestUser
// ---------------------------------------------------------------------------

@JsonSerializable()
class PaymentRequestUser {
  PaymentRequestUser({
    this.id,
    this.name,
    this.profilePicture,
  });

  factory PaymentRequestUser.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestUserFromJson(json);

  int? id;
  String? name;
  @JsonKey(name: 'profile_picture')
  String? profilePicture;

  Map<String, dynamic> toJson() => _$PaymentRequestUserToJson(this);
}

// ---------------------------------------------------------------------------
// PaymentRequestItem
// ---------------------------------------------------------------------------

@JsonSerializable()
class PaymentRequestItem {
  PaymentRequestItem({
    this.id,
    this.name,
    this.description,
    this.quantity,
    this.unitPrice,
    this.amount,
  });

  factory PaymentRequestItem.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestItemFromJson(json);

  int? id;
  String? name;
  String? description;
  int? quantity;
  @JsonKey(name: 'unit_price')
  double? unitPrice;
  double? amount;

  Map<String, dynamic> toJson() => _$PaymentRequestItemToJson(this);
}

// ---------------------------------------------------------------------------
// PaymentRequest
// ---------------------------------------------------------------------------

@JsonSerializable()
class PaymentRequest {
  PaymentRequest({
    this.id,
    this.conversationId,
    this.messageId,
    this.appointmentId,
    this.requester,
    this.payer,
    this.title,
    this.description,
    this.totalAmount,
    this.statusRaw,
    this.items,
    this.canAccept,
    this.canDecline,
    this.canPay,
    this.canCancel,
    this.acceptedAt,
    this.declinedAt,
    this.paidAt,
    this.cancelledAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => _$PaymentRequestFromJson(json);

  int? id;
  @JsonKey(name: 'conversation_id')
  int? conversationId;
  @JsonKey(name: 'message_id')
  int? messageId;
  @JsonKey(name: 'appointment_id')
  int? appointmentId;
  PaymentRequestUser? requester;
  PaymentRequestUser? payer;
  String? title;
  String? description;
  @JsonKey(name: 'total_amount')
  double? totalAmount;

  /// Raw status string from API ('pending', 'accepted', etc.)
  @JsonKey(name: 'status')
  String? statusRaw;
  List<PaymentRequestItem>? items;
  @JsonKey(name: 'can_accept')
  bool? canAccept;
  @JsonKey(name: 'can_decline')
  bool? canDecline;
  @JsonKey(name: 'can_pay')
  bool? canPay;
  @JsonKey(name: 'can_cancel')
  bool? canCancel;
  @JsonKey(name: 'accepted_at')
  DateTime? acceptedAt;
  @JsonKey(name: 'declined_at')
  DateTime? declinedAt;
  @JsonKey(name: 'paid_at')
  DateTime? paidAt;
  @JsonKey(name: 'cancelled_at')
  DateTime? cancelledAt;
  @JsonKey(name: 'expires_at')
  DateTime? expiresAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  PaymentRequestStatus get status => PaymentRequestStatus.fromString(statusRaw ?? 'pending');

  bool get isPending => status == PaymentRequestStatus.pending;
  bool get isPaid => status == PaymentRequestStatus.paid;
  bool get isDeclined => status == PaymentRequestStatus.declined;
  bool get isCancelled => status == PaymentRequestStatus.cancelled;
  bool get isExpired => status == PaymentRequestStatus.expired;
  bool get isAccepted => status == PaymentRequestStatus.accepted;

  Map<String, dynamic> toJson() => _$PaymentRequestToJson(this);
}
