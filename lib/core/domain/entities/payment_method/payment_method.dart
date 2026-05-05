import 'package:json_annotation/json_annotation.dart';

part 'payment_method.g.dart';

@JsonSerializable()
class PaymentMethod {
  PaymentMethod({
    this.id,
    this.userId,
    this.accountNumber,
    this.accountName,
    this.bankName,
    this.routingNumber,
    this.isDefault,
    this.isActive,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.bank,
    this.account,
    this.routing,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return _$PaymentMethodFromJson(json);
  }
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'account_number')
  String? accountNumber;
  @JsonKey(name: 'account_name')
  String? accountName;
  @JsonKey(name: 'bank_name')
  String? bankName;
  @JsonKey(name: 'routing_number')
  String? routingNumber;
  @JsonKey(name: 'is_default')
  bool? isDefault;
  @JsonKey(name: 'is_active')
  bool? isActive;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  String? bank;
  String? account;
  String? routing;

  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);
}
