import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/stats.dart';

part 'customer_wallet.g.dart';

@JsonSerializable()
class CustomerWallet {
  CustomerWallet({this.balance, this.escrowBalance, this.stats});

  factory CustomerWallet.fromJson(Map<String, dynamic> json) {
    return _$CustomerWalletFromJson(json);
  }

  /// Cash balance. `num` (not `int`) because the backend sends decimals —
  /// an `int` cast silently truncated the cents (R250.50 rendered R250.00).
  num? balance;

  /// Gross amount the customer has in escrow. This is the *full amount paid*,
  /// not the stylist's net/pouch figure — the wallet card must render this
  /// field and nothing else for the "In Escrow" tile.
  @JsonKey(name: 'escrow_balance')
  num? escrowBalance;
  Stats? stats;

  Map<String, dynamic> toJson() => _$CustomerWalletToJson(this);
}
