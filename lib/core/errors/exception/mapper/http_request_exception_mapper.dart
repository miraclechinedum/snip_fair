import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/models/remote/error_response.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/errors/exception/mapper/exception_mapper.dart';
import 'package:snip_fair/core/data/models/remote/mapper/error_response_mapper.dart';

@Injectable()
class HttpRequestExceptionMapper extends ExceptionMapper<RemoteException> {
  HttpRequestExceptionMapper(this._errorResponseMapper);
  final ErrorResponseMapper _errorResponseMapper;

  @override
  RemoteException map(Object? exception) {
    if (exception is DioException) {
      // The raw response body is intentionally not logged here: callers already
      // get a compact failure line from BaseRemoteSource, and dumping the body
      // duplicated every error (and could echo sensitive payloads).
      if (exception.error is RemoteException && exception.error != null) {
        return exception.error! as RemoteException;
      }
      switch (exception.type) {
        case DioExceptionType.cancel:
          return const RemoteException.cancellationError();
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return const RemoteException.timeoutError();
        case DioExceptionType.unknown:
          return RemoteException.unexpectedError(exception);
        case DioExceptionType.badResponse:
          if (exception.response?.data != null) {
            if (exception.response!.data is String) {
              return RemoteException.serverError(
                exception.response!.statusCode,
                const ServerError(message: 'Unexpected Server error'),
              );
            }
            final body = exception.response!.data;
            final json = body is Map<String, dynamic> ? body : null;
            final code = json?['code'];
            try {
              return RemoteException.serverError(
                exception.response!.statusCode,
                _errorResponseMapper.mapToEntity(
                  ErrorResponse.fromJson(normalizeErrorBody(json!)),
                ),
                code: code is String ? code : null,
                responseBody: json,
              );
            } catch (e) {
              return RemoteException.serverError(
                exception.response!.statusCode,
                const ServerError(message: 'An errorfrrr occured'),
                code: code is String ? code : null,
                responseBody: json,
              );
            }
          } else {
            return RemoteException.httpError(exception.response!.statusCode);
          }
        case DioExceptionType.badCertificate:
        case DioExceptionType.connectionError:
          return RemoteException.unexpectedError(exception);
      }
    } else if (exception is SocketException) {
      return const RemoteException.timeoutError();
    } else {
      return RemoteException.unexpectedError(exception);
    }
  }
}

/// Coerces fields the backend does not always type consistently before the
/// generated [ErrorResponse] parser sees them: `status` arrives as a bool, or
/// as the string `"false"` from `POST /payment/topup`; `message` may be absent
/// or non-string.
Map<String, dynamic> normalizeErrorBody(Map<String, dynamic> body) {
  final status = body['status'];
  final message = body['message'];
  final errors = body['errors'];
  return {
    ...body,
    'status': status is bool
        ? status
        : status == 'true' || status == '1' || status == 1
            ? true
            : status == 'false' || status == '0' || status == 0
                ? false
                : null,
    'message': message is String ? message : null,
    'errors': errors is Map<String, dynamic> ? errors : null,
  };
}
