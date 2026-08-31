import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/errors/exception/mapper/http_request_exception_mapper.dart';

abstract class BaseRemoteSource {
  final HttpRequestExceptionMapper httpRequestExceptionMapper =
      GetIt.instance.get();
  final logger = Logger();

  /// One-line printer for routine HTTP failures, so a handled 4xx/5xx does not
  /// flood the console with a boxed stack trace on every poll tick.
  static final _httpFailureLogger = Logger(printer: SimplePrinter());

  Future<ApiResult<R>> run<R>(Future<ApiResult<R>> Function() runner) async {
    try {
      return await runner.call();
    } catch (e, stack) {
      _logFailure(e, stack);
      return ApiResult.failure(error: httpRequestExceptionMapper.map(e));
    }
  }

  /// Routine transport/HTTP errors are already surfaced to callers as
  /// [ApiResult.failure] and handled by the UI, so they only get a compact
  /// summary line. Anything unexpected keeps the full error and stack trace.
  void _logFailure(Object error, StackTrace stack) {
    if (error is DioException) {
      final request = error.requestOptions;
      final status = error.response?.statusCode;
      _httpFailureLogger.w(
        'HTTP ${request.method} ${request.path} failed: '
        '${status ?? error.type.name}',
      );
      return;
    }
    logger.e('RemoteSource Error', error: error, stackTrace: stack);
  }
}
