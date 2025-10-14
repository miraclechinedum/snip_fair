// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_portfolio_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerPortfolioList _$SellerPortfolioListFromJson(Map<String, dynamic> json) =>
    SellerPortfolioList(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => SellerPortfolio.fromJson(e as Map<String, dynamic>))
          .toList(),
      path: json['path'] as String?,
      perPage: (json['per_page'] as num?)?.toInt(),
      nextCursor: json['next_cursor'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      prevCursor: json['prev_cursor'],
      prevPageUrl: json['prev_page_url'],
    );

Map<String, dynamic> _$SellerPortfolioListToJson(
        SellerPortfolioList instance) =>
    <String, dynamic>{
      'data': instance.data,
      'path': instance.path,
      'per_page': instance.perPage,
      'next_cursor': instance.nextCursor,
      'next_page_url': instance.nextPageUrl,
      'prev_cursor': instance.prevCursor,
      'prev_page_url': instance.prevPageUrl,
    };
