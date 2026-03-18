import 'package:json_annotation/json_annotation.dart';

part 'datum.g.dart';

@JsonSerializable()
class UserTransaction {

  UserTransaction({
    this.id,
    this.type,
    this.amount,
    this.description,
    this.status,
    this.reference,
    this.createdAt,
    this.updatedAt,
  });

  factory UserTransaction.fromJson(Map<String, dynamic> json) =>
      _$UserTransactionFromJson(json);
  int? id;
  String? type;
  double? amount;
  String? description;
  String? status;
  String? reference;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$UserTransactionToJson(this);
}
