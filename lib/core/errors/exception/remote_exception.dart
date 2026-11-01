import 'package:snip_fair/core/data/models/server_error.dart';

class RemoteException implements Exception {
  const RemoteException._(
    this.kind, {
    this.statusCode,
    this.errorResponse,
    this.exception,
    this.code,
    this.responseBody,
  });

  RemoteException.httpError(int? statusCode)
      : this._(
          RemoteExceptionKind.http,
          statusCode: statusCode,
          errorResponse: const ServerError(message: 'Server Error'),
        );

  const RemoteException.serverError(
    int? statusCode,
    ServerError errorResponse, {
    String? code,
    Map<String, dynamic>? responseBody,
  }) : this._(
          RemoteExceptionKind.server,
          statusCode: statusCode,
          errorResponse: errorResponse,
          code: code,
          responseBody: responseBody,
        );

  const RemoteException.networkError(int statusCode)
      : this._(RemoteExceptionKind.network, statusCode: statusCode);

  const RemoteException.noInternetError() : this._(RemoteExceptionKind.noInternet);

  const RemoteException.timeoutError() : this._(RemoteExceptionKind.timeout);

  const RemoteException.cancellationError() : this._(RemoteExceptionKind.cancellation);

  RemoteException.unexpectedError(Object? exception)
      : this._(
          RemoteExceptionKind.unexpected,
          exception: exception,
          errorResponse: const ServerError(message: 'Server Error'),
        );
  final RemoteExceptionKind kind;
  final int? statusCode;
  final ServerError? errorResponse;
  final Object? exception;

  /// Machine-readable error code from the response body (e.g.
  /// `insufficient_wallet_balance`), when the backend sends one.
  final String? code;

  /// The decoded JSON error body, for structured fields such as `shortfall`
  /// or `data`. Never log it wholesale.
  final Map<String, dynamic>? responseBody;

  /// A numeric field of [responseBody], accepting JSON ints, doubles and
  /// numeric strings.
  num? numberField(String key) {
    final value = responseBody?[key];
    if (value is num) return value;
    return value is String ? num.tryParse(value.trim()) : null;
  }

  bool get isServerInternalError => statusCode != null && statusCode! >= 500 && statusCode! <= 599;

  @override
  String toString() {
    return 'RemoteException: {kind: $kind, statusCode: $statusCode, code: $code, errorResponse: $errorResponse, exception: $exception}';
  }
}

enum RemoteExceptionKind { noInternet, network, http, server, timeout, cancellation, unexpected }
