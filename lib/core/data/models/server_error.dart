import 'package:snip_fair/core/data/models/base_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_error.freezed.dart';

@freezed
sealed class ServerError extends BaseModel with _$ServerError {
  const factory ServerError({
    @Default(false) bool status,
    @Default('') String message,
    @Default({}) Map<String, dynamic> errors,
  }) = _ServerError;
  const ServerError._();
}
