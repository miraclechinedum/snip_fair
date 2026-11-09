import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/mapper/error_response_mapper.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_failure.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_lookup.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';
import 'package:snip_fair/core/errors/exception/mapper/http_request_exception_mapper.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/utils/idempotency_key.dart';

/// Never a real host: every request is answered by [_FakeHttpService].
const _kBaseUrl = 'http://127.0.0.1:8002/api';
const _key = '3b241101-e2bb-4255-8caf-4136c566a962';

typedef _Reply = void Function(RequestOptions, RequestInterceptorHandler);

/// Serves every request from [reply] instead of the network and records it.
class _FakeHttpService implements HttpService {
  _FakeHttpService(this.reply);

  final _Reply reply;
  final requests = <RequestOptions>[];

  @override
  Dio client({
    bool requireAuth = true,
    bool optionalAuth = false,
    bool isFormDataRequest = false,
  }) =>
      Dio(BaseOptions(baseUrl: _kBaseUrl))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              reply(options, handler);
            },
          ),
        );
}

/// Laravel's accepted withdrawal: 204 No Content, empty body.
_Reply _noContent({bool replayed = false}) =>
    (options, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 204,
            data: '',
            headers: Headers.fromMap({
              if (replayed) 'idempotent-replayed': ['true'],
            }),
          ),
        );

_Reply _fail(int status, Map<String, dynamic> body) =>
    (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: status,
              data: body,
            ),
          ),
        );

_Reply _transportError(DioExceptionType type) =>
    (options, handler) => handler.reject(
          DioException(requestOptions: options, type: type),
        );

void main() {
  late _FakeHttpService http;
  late SnipFairBackendRemoteSource remote;

  void useTransport(_Reply reply) {
    http = _FakeHttpService(reply);
    getIt
      ..allowReassignment = true
      ..registerSingleton<HttpService>(http);
  }

  setUp(() {
    getIt
      ..allowReassignment = true
      ..registerSingleton<HttpRequestExceptionMapper>(
        HttpRequestExceptionMapper(ErrorResponseMapper()),
      );
    useTransport(_noContent());
    remote = SnipFairBackendRemoteSource();
  });

  tearDown(getIt.reset);

  Future<ApiResult<WithdrawalSubmission>> withdraw() =>
      remote.requestPayout('7', 250.5, idempotencyKey: _key);

  RemoteException failureOfLookup(ApiResult<WithdrawalLookup> result) =>
      result.when(
        success: (data) => fail('expected a failure, got $data'),
        failure: (error) => error,
      );

  RemoteException failureOf(ApiResult<WithdrawalSubmission> result) =>
      result.when(
        success: (_) => fail('expected a failure'),
        failure: (error) => error,
      );

  group('generateUuidV4', () {
    final v4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('is an RFC 4122 version 4 UUID', () {
      for (var i = 0; i < 200; i++) {
        expect(generateUuidV4(), matches(v4));
      }
    });

    test('fits the backend key format (8-100 of [A-Za-z0-9._:-])', () {
      expect(generateUuidV4(), matches(RegExp(r'^[A-Za-z0-9._:-]{8,100}$')));
    });

    test('is unique per call', () {
      final keys = {for (var i = 0; i < 1000; i++) generateUuidV4()};
      expect(keys, hasLength(1000));
    });
  });

  group('POST /wallet/withdraw', () {
    test('sends the attempt key in the Idempotency-Key header', () async {
      await withdraw();

      final request = http.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/wallet/withdraw');
      expect(request.headers['Idempotency-Key'], _key);
      expect(request.data, {'amount': '250.50', 'method': 7});
    });

    test('body: amount in rands with two decimals, method as an integer', () {
      expect(
        SnipFairBackendRemoteSource.withdrawalBody('12', 150),
        {'amount': '150.00', 'method': 12},
      );
      expect(
        SnipFairBackendRemoteSource.withdrawalBody('12', 1234.5),
        {'amount': '1234.50', 'method': 12},
      );
      expect(
        SnipFairBackendRemoteSource.withdrawalBody('12', 0.07),
        {'amount': '0.07', 'method': 12},
      );
    });

    test('a retry with the same key sends the identical payload', () async {
      await withdraw();
      await withdraw();

      final [first, second] = http.requests;
      expect(
          second.headers['Idempotency-Key'], first.headers['Idempotency-Key']);
      expect(second.data, first.data);
    });

    test('204 with an empty body is a success, not a parse failure', () async {
      final result = await withdraw();

      final submission = result.when(
        success: (data) => data,
        failure: (error) => fail('unexpected failure: $error'),
      );
      expect(submission, const WithdrawalSubmission(amount: 250.5));
      expect(submission.replayed, isFalse);
    });

    test('204 with Idempotent-Replayed: true is reported as a replay',
        () async {
      useTransport(_noContent(replayed: true));

      final result = await withdraw();

      expect(
        result.when(success: (d) => d.replayed, failure: (_) => false),
        isTrue,
      );
    });

    test('503 withdrawals disabled', () async {
      useTransport(
        _fail(503, {
          'message': 'Withdrawals are temporarily unavailable. Your balance '
              'is safe; please try again later.',
          'code': 'PAYOUT_REQUESTS_DISABLED',
        }),
      );

      final error = failureOf(await withdraw());

      expect(error.statusCode, 503);
      expect(error.code, 'PAYOUT_REQUESTS_DISABLED');
      expect(classifyWithdrawalFailure(error), WithdrawalFailureKind.disabled);
      expect(WithdrawalFailureKind.disabled.isUncertain, isFalse);
    });

    test('503 without a code (misconfigured maximum) is also disabled',
        () async {
      useTransport(
        _fail(503, {'message': 'Withdrawals are temporarily unavailable.'}),
      );

      final error = failureOf(await withdraw());

      expect(classifyWithdrawalFailure(error), WithdrawalFailureKind.disabled);
    });

    test('409 idempotency key reused', () async {
      useTransport(
        _fail(409, {
          'message': 'Ooops.. This idempotency key was already used for a '
              'different withdrawal.',
          'code': 'IDEMPOTENCY_KEY_REUSED',
        }),
      );

      final error = failureOf(await withdraw());

      expect(error.statusCode, 409);
      expect(classifyWithdrawalFailure(error), WithdrawalFailureKind.conflict);
      // The transport never retries on its own.
      expect(http.requests, hasLength(1));
    });

    test('400 idempotency key required', () async {
      useTransport(
        _fail(400, {
          'message': "Ooops.. This version of the app can't request "
              'withdrawals. Please update it and try again.',
          'code': 'IDEMPOTENCY_KEY_REQUIRED',
        }),
      );

      final error = failureOf(await withdraw());

      expect(
        classifyWithdrawalFailure(error),
        WithdrawalFailureKind.keyRejected,
      );
    });

    test('400 business refusal (insufficient balance)', () async {
      useTransport(_fail(400, {'message': 'Ooops.. Insufficient balance.'}));

      final error = failureOf(await withdraw());

      expect(error.statusCode, 400);
      expect(error.errorResponse?.message, 'Ooops.. Insufficient balance.');
      expect(classifyWithdrawalFailure(error), WithdrawalFailureKind.rejected);
      expect(WithdrawalFailureKind.rejected.isUncertain, isFalse);
    });

    test('422 validation errors', () async {
      useTransport(
        _fail(422, {
          'message': 'The amount field must be greater than 10.',
          'errors': {
            'amount': ['The amount field must be greater than 10.'],
          },
        }),
      );

      final error = failureOf(await withdraw());

      expect(classifyWithdrawalFailure(error), WithdrawalFailureKind.rejected);
    });

    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.unknown,
    ]) {
      test('${type.name} leaves the outcome uncertain', () async {
        useTransport(_transportError(type));

        final error = failureOf(await withdraw());

        expect(
          classifyWithdrawalFailure(error),
          WithdrawalFailureKind.uncertain,
        );
        expect(http.requests, hasLength(1));
      });
    }

    for (final (status, kind) in [
      (401, WithdrawalFailureKind.unauthorized),
      (403, WithdrawalFailureKind.forbidden),
      (429, WithdrawalFailureKind.rateLimited),
    ]) {
      test('$status is ${kind.name}: a definite refusal', () async {
        useTransport(_fail(status, {'message': 'Refused'}));

        final error = failureOf(await withdraw());

        expect(classifyWithdrawalFailure(error), kind);
        expect(kind.isUncertain, isFalse);
      });
    }

    for (final status in [500, 502, 504, 408]) {
      test('$status leaves the outcome uncertain', () async {
        useTransport(_fail(status, {'message': 'Server Error'}));

        final error = failureOf(await withdraw());

        expect(
          classifyWithdrawalFailure(error),
          WithdrawalFailureKind.uncertain,
        );
      });
    }
  });

  group('GET /wallet/withdrawals/lookup', () {
    _Reply ok(Map<String, dynamic> body) =>
        (options, handler) => handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: body,
              ),
            );

    Map<String, dynamic> withdrawalBody({
      String status = 'processing',
      bool refunded = false,
      Map<String, dynamic>? refund,
    }) =>
        {
          'withdrawal': {
            'id': 42,
            'reference': 'WDR-42',
            'amount': '150.00',
            'amount_minor': 15000,
            'currency': 'ZAR',
            'status': status,
            'refunded': refunded,
            'refund': refund,
            'transaction_id': 881,
            'created_at': '2026-11-03T10:00:00.000000Z',
            'status_updated_at': '2026-11-03T10:05:00.000000Z',
          },
        };

    Future<ApiResult<WithdrawalLookup>> lookUp() =>
        remote.lookupWithdrawal(_key);

    test('GET with the stored key as a query parameter, nothing else',
        () async {
      useTransport(ok(withdrawalBody()));

      await lookUp();

      final request = http.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/wallet/withdrawals/lookup');
      expect(request.queryParameters, {'idempotency_key': _key});
      expect(request.headers.containsKey('Idempotency-Key'), isFalse);
      expect(request.data, isNull);
    });

    test('200: the client-safe withdrawal', () async {
      useTransport(ok(withdrawalBody()));

      final result = await lookUp();

      final found = result.when(
        success: (data) => data,
        failure: (e) => fail('unexpected failure: $e'),
      );
      expect(found, isA<WithdrawalLookupFound>());
      final withdrawal = (found as WithdrawalLookupFound).withdrawal;
      expect(withdrawal.id, 42);
      expect(withdrawal.amountMinor, 15000);
      expect(withdrawal.amount, 150.0);
      expect(withdrawal.currency, 'ZAR');
      expect(withdrawal.status, WithdrawalRecordStatus.processing);
      expect(withdrawal.refunded, isFalse);
      expect(withdrawal.refund, isNull);
      expect(withdrawal.transactionId, 881);
      expect(withdrawal.reference, 'WDR-42');
    });

    test('200 refunded: the refund details', () async {
      useTransport(
        ok(
          withdrawalBody(
            status: 'failed',
            refunded: true,
            refund: {
              'transaction_id': 990,
              'reference': 'WDR-42-REFUND',
              'amount': '150.00',
              'created_at': '2026-11-03T11:00:00.000000Z',
            },
          ),
        ),
      );

      final withdrawal = ((await lookUp()).when(
        success: (d) => d,
        failure: (e) => fail('$e'),
      ) as WithdrawalLookupFound)
          .withdrawal;

      expect(withdrawal.status, WithdrawalRecordStatus.failed);
      expect(withdrawal.refunded, isTrue);
      expect(withdrawal.refund?.transactionId, 990);
      expect(withdrawal.refund?.amount, 150.0);
      expect(withdrawal.refund?.reference, 'WDR-42-REFUND');
    });

    test('every client-safe status is understood', () {
      expect(
        {
          for (final s in [
            'pending',
            'processing',
            'paid',
            'failed',
            'under_review',
            'reversed',
            'closed',
          ])
            s: WithdrawalRecordStatus.parse(s),
        },
        {
          'pending': WithdrawalRecordStatus.pending,
          'processing': WithdrawalRecordStatus.processing,
          'paid': WithdrawalRecordStatus.paid,
          'failed': WithdrawalRecordStatus.failed,
          'under_review': WithdrawalRecordStatus.underReview,
          'reversed': WithdrawalRecordStatus.reversed,
          'closed': WithdrawalRecordStatus.closed,
        },
      );
      expect(WithdrawalRecordStatus.parse('successful'), isNull);
    });

    test('404 WITHDRAWAL_NOT_FOUND: not found (a success, not an error)',
        () async {
      useTransport(
        _fail(404, {
          'message': 'Ooops.. No withdrawal has been recorded with this '
              'idempotency key.',
          'code': 'WITHDRAWAL_NOT_FOUND',
        }),
      );

      final result = await lookUp();

      expect(
        result.when(success: (d) => d, failure: (_) => null),
        const WithdrawalLookupNotFound(),
      );
    });

    test('a bare 404 (e.g. a backend without this route) is NOT "not found"',
        () async {
      useTransport(
        _fail(404, {
          'message': 'The route api/wallet/withdrawals/lookup could not be '
              'found.',
        }),
      );

      expect(failureOfLookup(await lookUp()).statusCode, 404);
    });

    test('503 WITHDRAWAL_LOOKUP_BUSY is a failure carrying its code', () async {
      useTransport(
        _fail(503, {
          'message': 'Ooops.. Your withdrawal is still being processed. '
              'Please check again shortly.',
          'code': 'WITHDRAWAL_LOOKUP_BUSY',
        }),
      );

      final error = failureOfLookup(await lookUp());

      expect(error.statusCode, 503);
      expect(error.code, 'WITHDRAWAL_LOOKUP_BUSY');
    });

    for (final status in [401, 403, 422, 500]) {
      test('$status is a failure', () async {
        useTransport(_fail(status, {'message': 'No'}));

        expect(failureOfLookup(await lookUp()).statusCode, status);
        expect(http.requests, hasLength(1), reason: 'no automatic retry');
      });
    }

    test('a timeout is a failure', () async {
      useTransport(_transportError(DioExceptionType.receiveTimeout));

      expect(
        failureOfLookup(await lookUp()).kind,
        RemoteExceptionKind.timeout,
      );
    });

    test('an unreadable 200 body never resolves anything', () async {
      useTransport(ok({
        'withdrawal': {'id': 'x'}
      }));

      expect(failureOfLookup(await lookUp()), isA<RemoteException>());
    });
  });

  test('wallet top-up requests carry no Idempotency-Key header', () async {
    useTransport(
      (options, handler) => handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: const {
            'status': true,
            'processor': 'peachpayment',
            'deposit_id': 123,
            'checkoutId': 'chk_test',
            'redirectUrl': 'https://sandbox.example/checkout',
          },
        ),
      ),
    );

    await remote.initializeWalletTopUp(amount: 50);

    final request = http.requests.single;
    expect(request.path, '/payment/topup');
    expect(request.headers.containsKey('Idempotency-Key'), isFalse);
  });
}
