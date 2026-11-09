import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/settings.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/statistics.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';

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

  /// The stylist's own ledger, as returned by `GET /stylist/earnings`.
  ///
  /// Includes holding-pouch rows (escrow held against an approved booking),
  /// which `GET /wallet/transactions` does not carry — so the Transactions
  /// tab has to read this collection, not just the wallet page. Was
  /// `List<dynamic>` and therefore never renderable.
  ///
  /// The rows do NOT share the wallet transaction shape (see
  /// [UserTransaction.fromEarningsRow]), so they get their own parser.
  @JsonKey(fromJson: earningsTransactionsFromJson)
  List<UserTransaction>? transactions;
  @JsonKey(name: 'payment_method')
  PaymentMethod? paymentMethod;
  @JsonKey(name: 'payment_methods')
  List<PaymentMethod>? paymentMethods;
  Settings? settings;

  Map<String, dynamic> toJson() => _$StylistEarningsToJson(this);
}

/// Parses the `transactions` list of `GET /stylist/earnings`. A malformed row
/// is skipped (and reported in debug logs) instead of failing the whole
/// earnings response — which used to leave the Overview with no data.
List<UserTransaction>? earningsTransactionsFromJson(dynamic json) {
  if (json is! List) return null;
  final rows = <UserTransaction>[];
  for (final row in json) {
    final parsed = row is Map<String, dynamic>
        ? UserTransaction.fromEarningsRow(row)
        : null;
    if (parsed == null) {
      // Keys only: rows carry customer names and emails.
      debugPrint(
        '[EARNINGS] Skipped unreadable earnings row: '
        '${row is Map ? 'keys=${row.keys.toList()}' : row.runtimeType}',
      );
      continue;
    }
    rows.add(parsed);
  }
  return rows;
}
