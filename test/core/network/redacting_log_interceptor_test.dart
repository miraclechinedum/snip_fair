import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/network/redacting_log_interceptor.dart';
import 'package:snip_fair/core/utils/environment/base_config.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';

import '../../features/earnings/withdrawal_test_support.dart';

const _token = '41|sanctumSecretTokenValue';
const _key = '3b241101-e2bb-4255-8caf-4136c566a962';
const _cookie = 'laravel_session=sessionSecretValue';

/// Never a real host: every request is answered by [_FakeAdapter].
class _TestConfig implements BaseConfig {
  @override
  String get apiHost => 'http://127.0.0.1:8002/api';
  @override
  bool get useHttpsScheme => false;
  @override
  bool get trackEvents => false;
  @override
  bool get reportErrors => false;
}

/// Answers every request locally with [status] and [body].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.status = 200, this.body = '{"status":true}'});

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
          'set-cookie': [_cookie],
          'idempotent-replayed': ['true'],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<String> logs;
  String allLogs() => logs.join('\n');

  void expectNoSecrets() {
    final text = allLogs();
    expect(text, isNot(contains('sanctumSecretTokenValue')));
    expect(text, isNot(contains(_key)));
    expect(text, isNot(contains('sessionSecretValue')));
    expect(text, isNot(contains('hunter2')));
    expect(text, isNot(contains('62001234')));
  }

  setUp(() => logs = []);

  group('RedactingLogInterceptor', () {
    Dio dio({int status = 200, String body = '{"status":true}'}) => Dio(
          BaseOptions(baseUrl: 'http://127.0.0.1:8002/api'),
        )
          ..httpClientAdapter = _FakeAdapter(status: status, body: body)
          ..interceptors.add(
              RedactingLogInterceptor(logPrint: (line) => logs.add('$line')));

    test('redacts credential headers on the request and response', () async {
      await dio().post<dynamic>(
        '/wallet/withdraw',
        data: {'amount': '150.00', 'method': 12},
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Idempotency-Key': _key,
            'Cookie': _cookie,
          },
        ),
      );

      expectNoSecrets();
      final text = allLogs();
      expect(
          text, contains('--> POST http://127.0.0.1:8002/api/wallet/withdraw'));
      expect(text, contains('Authorization: [REDACTED]'));
      expect(text, contains('Idempotency-Key: [REDACTED]'));
      expect(text, contains('Cookie: [REDACTED]'));
      expect(text, contains('set-cookie: [REDACTED]'));
      // Harmless values stay readable for debugging.
      expect(text, contains('{"amount":"150.00","method":12}'));
      expect(text, contains('idempotent-replayed: true'));
      expect(text, contains('<-- 200 POST'));
    });

    test('redacts sensitive body fields at any depth, and query params',
        () async {
      await dio(
        body: jsonEncode({
          'token': _token,
          'user': {
            'name': 'Jane',
            'payment_method': {'account_number': '62001234'},
          },
        }),
      ).post<dynamic>(
        '/login',
        queryParameters: {'page': '2', 'access_token': _token},
        data: {
          'email': 'jane@example.com',
          'password': 'hunter2',
          'idempotency_key': _key,
        },
      );

      expectNoSecrets();
      final text = allLogs();
      expect(text, contains('"password":"[REDACTED]"'));
      expect(text, contains('"account_number":"[REDACTED]"'));
      expect(text, contains('page=2'));
      expect(text, contains('"name":"Jane"'));
    });

    test('error responses are redacted too', () async {
      await expectLater(
        dio(
          status: 401,
          body: '{"message":"Unauthenticated.","token":"$_token"}',
        ).get<dynamic>(
          '/user',
          options: Options(headers: {'Authorization': 'Bearer $_token'}),
        ),
        throwsA(isA<DioException>()),
      );

      expectNoSecrets();
      expect(allLogs(), contains('<-- ERROR 401 GET'));
      expect(allLogs(), contains('"message":"Unauthenticated."'));
    });

    test('long bodies are truncated', () async {
      await dio(body: jsonEncode({'data': 'x' * 5000})).get<dynamic>('/big');

      final responseLog = logs.last;
      expect(responseLog.length, lessThan(1500));
      expect(responseLog, contains('truncated'));
    });
  });

  group('HttpService with verbose logging enabled', () {
    setUp(() async {
      HttpService.verboseLogging = true;
      Environment().config = _TestConfig();
      final prefs = await stylistPrefs(
        values: {SharedPrefKey.accessToken: _token},
      );
      getIt
        ..allowReassignment = true
        ..registerSingleton<LocalKeyStorage>(LocalKeyStorage(prefs));
    });

    tearDown(() async {
      HttpService.verboseLogging = kEnableVerboseHttpLogging;
      await getIt.reset();
    });

    test('logs through the redacting logger, never Dio LogInterceptor',
        () async {
      final client = HttpService().client();

      expect(
        client.interceptors.whereType<RedactingLogInterceptor>(),
        hasLength(1),
      );
      expect(client.interceptors.whereType<LogInterceptor>(), isEmpty);
    });

    test('the bearer token and idempotency key are not printed', () async {
      final client = HttpService().client()
        ..httpClientAdapter = _FakeAdapter(status: 204, body: '');
      // Capture what the app's own logger would print.
      final index = client.interceptors.indexWhere(
        (i) => i is RedactingLogInterceptor,
      );
      client.interceptors[index] =
          RedactingLogInterceptor(logPrint: (line) => logs.add('$line'));

      await client.post<dynamic>(
        '/wallet/withdraw',
        data: {'amount': '150.00', 'method': 12},
        options: Options(headers: {'Idempotency-Key': _key}),
      );

      expectNoSecrets();
      // The Authorization header added by TokenInterceptor was seen…
      expect(allLogs(), contains('Authorization: [REDACTED]'));
      expect(allLogs(), contains('Idempotency-Key: [REDACTED]'));
      expect(allLogs(), contains('<-- 204 POST'));
    });
  });
}
