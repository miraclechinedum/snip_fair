import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';

part 'seller_portfolio_list.g.dart';

@JsonSerializable()
class SellerPortfolioList {
  SellerPortfolioList({
    this.data,
    this.path,
    this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory SellerPortfolioList.fromJson(Map<String, dynamic> json) {
    return _$SellerPortfolioListFromJson(json);
  }
  List<SellerPortfolio>? data;
  String? path;
  @JsonKey(name: 'per_page')
  int? perPage;
  @JsonKey(name: 'next_cursor')
  String? nextCursor;
  @JsonKey(name: 'next_page_url')
  String? nextPageUrl;
  @JsonKey(name: 'prev_cursor')
  dynamic prevCursor;
  @JsonKey(name: 'prev_page_url')
  dynamic prevPageUrl;

  Map<String, dynamic> toJson() => _$SellerPortfolioListToJson(this);
}
