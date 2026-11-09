import 'dart:convert';

import 'package:dio/dio.dart';

/// Verbose HTTP logger that never prints credentials or full payloads.
///
/// Replaces Dio's `LogInterceptor`, which prints every header and body
/// verbatim. Here:
/// - credential headers ([sensitiveHeaders]) are replaced with [redacted];
/// - query parameters and JSON body fields whose name looks sensitive
///   ([_sensitiveField]) are replaced with [redacted], at any depth;
/// - bodies are cut to [maxBodyLength] characters; non-JSON bodies are only
///   described (type and length).
class RedactingLogInterceptor extends Interceptor {
  RedactingLogInterceptor({
    this.logPrint = _defaultPrint,
    this.maxBodyLength = 1000,
  });

  final void Function(Object object) logPrint;
  final int maxBodyLength;

  static const redacted = '[REDACTED]';

  /// Lower-case header names whose values are credentials or tie a request
  /// to an account or session.
  static const sensitiveHeaders = {
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'idempotency-key',
    'x-xsrf-token',
    'x-csrf-token',
    'x-api-key',
    'api-key',
    'x-auth-token',
    'x-device-id',
  };

  /// Field names (JSON keys, query parameters) treated as sensitive.
  static final _sensitiveField = RegExp(
    'pass(word)?|token|secret|authori[sz]ation|cookie|session|'
    r'idempotency|otp|pin$|cvv|cvc|card|account_?number|'
    'signature|api_?key',
    caseSensitive: false,
  );

  static void _defaultPrint(Object object) =>
      // ignore: avoid_print
      print(object);

  static bool isSensitiveHeader(String name) =>
      sensitiveHeaders.contains(name.toLowerCase());

  static bool isSensitiveField(String name) => _sensitiveField.hasMatch(name);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logPrint(
      [
        '--> ${options.method} ${_redactUri(options.uri)}',
        ..._headerLines(options.headers),
        if (options.data != null) 'body: ${_describeBody(options.data)}',
      ].join('\n'),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    logPrint(_responseText(response));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    logPrint(
      response != null
          ? _responseText(response, prefix: '<-- ERROR')
          : '<-- ERROR ${err.requestOptions.method} '
              '${_redactUri(err.requestOptions.uri)} (${err.type.name})',
    );
    handler.next(err);
  }

  String _responseText(Response<dynamic> response, {String prefix = '<--'}) {
    final request = response.requestOptions;
    final status = '$prefix ${response.statusCode} ${request.method}';
    return [
      '$status ${_redactUri(request.uri)}',
      ..._headerLines(response.headers.map),
      if (response.data != null) 'body: ${_describeBody(response.data)}',
    ].join('\n');
  }

  Iterable<String> _headerLines(Map<String, dynamic> headers) =>
      headers.entries.map(
        (e) => '  ${e.key}: '
            '${isSensitiveHeader(e.key) ? redacted : _headerValue(e.value)}',
      );

  static String _headerValue(Object? value) =>
      value is List ? value.join(', ') : '$value';

  String _redactUri(Uri uri) {
    if (uri.queryParametersAll.isEmpty) return uri.toString();
    return uri.replace(
      queryParameters: {
        for (final e in uri.queryParametersAll.entries)
          e.key: isSensitiveField(e.key) ? [redacted] : e.value,
      },
    ).toString();
  }

  String _describeBody(Object? data) {
    final Object? json;
    if (data is Map || data is List) {
      json = data;
    } else if (data is String) {
      try {
        json = data.isEmpty ? null : jsonDecode(data);
      } on FormatException {
        return '<text, ${data.length} chars>';
      }
      if (json == null) return '<empty>';
    } else if (data is FormData) {
      return '<form data: ${data.fields.length} fields, '
          '${data.files.length} files>';
    } else {
      return '<${data.runtimeType}>';
    }
    final text = jsonEncode(_redactJson(json));
    return text.length <= maxBodyLength
        ? text
        : '${text.substring(0, maxBodyLength)}… '
            '(${text.length} chars, truncated)';
  }

  static Object? _redactJson(Object? value) {
    if (value is Map) {
      return {
        for (final e in value.entries)
          '${e.key}': isSensitiveField('${e.key}')
              ? redacted
              : _redactJson(e.value),
      };
    }
    if (value is List) return value.map(_redactJson).toList();
    return value;
  }
}
