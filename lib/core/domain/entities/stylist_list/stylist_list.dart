import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';

part 'stylist_list.g.dart';

@JsonSerializable()
class StylistList {
  List<SellerDetails>? data;
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

  StylistList({
    this.data,
    this.path,
    this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory StylistList.fromJson(Map<String, dynamic> json) {
    return _$StylistListFromJson(json);
  }

  Map<String, dynamic> toJson() => _$StylistListToJson(this);
}
