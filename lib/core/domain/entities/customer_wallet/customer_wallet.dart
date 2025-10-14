import 'package:json_annotation/json_annotation.dart';

import 'stats.dart';

part 'customer_wallet.g.dart';

@JsonSerializable()
class CustomerWallet {
  int? balance;
  @JsonKey(name: 'escrow_balance')
  int? escrowBalance;
  Stats? stats;

  CustomerWallet({this.balance, this.escrowBalance, this.stats});

  factory CustomerWallet.fromJson(Map<String, dynamic> json) {
    return _$CustomerWalletFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CustomerWalletToJson(this);
}
