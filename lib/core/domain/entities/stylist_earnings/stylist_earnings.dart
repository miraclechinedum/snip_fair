import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/settings.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/statistics.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';

part 'stylist_earnings.g.dart';

@JsonSerializable()
class StylistEarnings {
  StylistEarnings({
    this.statistics,
    this.transactions,
    this.paymentMethod,
    this.paymentMethods,
    this.settings,
  });

  factory StylistEarnings.fromJson(Map<String, dynamic> json) {
    return _$StylistEarningsFromJson(json);
  }
  Statistics? statistics;
  List<dynamic>? transactions;
  @JsonKey(name: 'payment_method')
  PaymentMethod? paymentMethod;
  @JsonKey(name: 'payment_methods')
  List<PaymentMethod>? paymentMethods;
  Settings? settings;

  Map<String, dynamic> toJson() => _$StylistEarningsToJson(this);
}
