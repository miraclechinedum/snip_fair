import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/stylist_escrow/escrow_item.dart';

part 'escrow_breakdown.g.dart';

@JsonSerializable()
class EscrowBreakdown {
  EscrowBreakdown({
    this.success,
    this.escrowTotal,
    this.count,
    this.items,
  });

  factory EscrowBreakdown.fromJson(Map<String, dynamic> json) =>
      _$EscrowBreakdownFromJson(json);

  bool? success;

  // Same int-vs-double resilience as held_amount.
  @JsonKey(name: 'escrow_total', fromJson: escrowToDouble)
  double? escrowTotal;

  int? count;

  List<EscrowItem>? items;

  Map<String, dynamic> toJson() => _$EscrowBreakdownToJson(this);
}
