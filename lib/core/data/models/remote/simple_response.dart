import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:snip_fair/core/data/models/remote/base_remote_data.dart';

part 'simple_response.freezed.dart';
part 'simple_response.g.dart';

@freezed
sealed class SimpleResponse extends BaseRemoteData with _$SimpleResponse {
  factory SimpleResponse({
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'message') String? message,
  }) = _SimpleResponse;

  const SimpleResponse._();

  factory SimpleResponse.fromJson(Map<String, dynamic> json) =>
      _$SimpleResponseFromJson(json);
}
