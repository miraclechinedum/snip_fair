import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/stats.dart';


part 'customer_wallet.g.dart';

@JsonSerializable()
class CustomerWallet {

  CustomerWallet({this.balance, this.escrowBalance, this.stats});

  factory CustomerWallet.fromJson(Map<String, dynamic> json) {
    return _$CustomerWalletFromJson(json);
  }
  int? balance;
  @JsonKey(name: 'escrow_balance')
  int? escrowBalance;
  Stats? stats;

  Map<String, dynamic> toJson() => _$CustomerWalletToJson(this);
}
