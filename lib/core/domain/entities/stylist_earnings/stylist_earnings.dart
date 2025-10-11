import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';

import 'settings.dart';
import 'statistics.dart';

part 'stylist_earnings.g.dart';

@JsonSerializable()
class StylistEarnings {
  Statistics? statistics;
  List<dynamic>? transactions;
  @JsonKey(name: 'payment_method')
  PaymentMethod? paymentMethod;
  @JsonKey(name: 'payment_methods')
  List<PaymentMethod>? paymentMethods;
  Settings? settings;

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

  Map<String, dynamic> toJson() => _$StylistEarningsToJson(this);
}
