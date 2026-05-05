import 'package:json_annotation/json_annotation.dart';

part 'bank.g.dart';

@JsonSerializable()
class Bank {

  Bank({this.name, this.branchCode});

  factory Bank.fromJson(Map<String, dynamic> json) => _$BankFromJson(json);
  String? name;
  String? branchCode;

  Map<String, dynamic> toJson() => _$BankToJson(this);
}
