import 'package:json_annotation/json_annotation.dart';

import 'datum.dart';

part 'customer_wallet_transaction_list.g.dart';

@JsonSerializable()
class CustomerWalletTransactionList {
  List<Datum>? data;
  String? path;
  @JsonKey(name: 'per_page')
  int? perPage;
  @JsonKey(name: 'next_cursor')
  dynamic nextCursor;
  @JsonKey(name: 'next_page_url')
  dynamic nextPageUrl;
  @JsonKey(name: 'prev_cursor')
  dynamic prevCursor;
  @JsonKey(name: 'prev_page_url')
  dynamic prevPageUrl;

  CustomerWalletTransactionList({
    this.data,
    this.path,
    this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory CustomerWalletTransactionList.fromJson(Map<String, dynamic> json) {
    return _$CustomerWalletTransactionListFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CustomerWalletTransactionListToJson(this);
}
