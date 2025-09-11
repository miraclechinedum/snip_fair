import 'package:snip_fair/core/data/models/remote/base_remote_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_response.freezed.dart';
part 'error_response.g.dart';

@freezed
sealed class ErrorResponse extends BaseRemoteData with _$ErrorResponse {
  factory ErrorResponse({
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'message') String? message,
    @JsonKey(name: 'errors') Map<String, dynamic>? errors,
  }) = _ErrorResponse;

  const ErrorResponse._();

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
}
