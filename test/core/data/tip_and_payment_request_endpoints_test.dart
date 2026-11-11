import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/mapper/error_response_mapper.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/errors/exception/mapper/http_request_exception_mapper.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';

/// Never a real host: every request is answered by [_FakeHttpService].
const _kBaseUrl = 'http://127.0.0.1:8002/api';

typedef _Reply = void Function(RequestOptions, RequestInterceptorHandler);

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

_Reply _ok(int status, Map<String, dynamic> body) =>
    (options, handler) => handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: status,
            data: body,
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
    remote = SnipFairBackendRemoteSource();
  });

  tearDown(getIt.reset);

  T successOf<T>(ApiResult<T> result) => result.when(
        success: (data) => data,
        failure: (error) => fail('unexpected failure: $error'),
      );

  RemoteException failureOf<T>(ApiResult<T> result) => result.when(
        success: (data) => fail('expected a failure, got $data'),
        failure: (error) => error,
      );

  group('POST /customer/appointment/{id}/tip', () {
    test('card: amount as a two-decimal string and payment_method', () async {
      useTransport(
        _ok(201, {
          'success': true,
          'code': 'checkout_started',
          'status': 'pending',
          'payment_method': 'card',
          'tip_amount': 25.5,
          'payment': {
            'deposit_id': '123',
            'checkout_id': 'chk_123',
            'redirect_url': 'https://checkout.example.test/chk_123',
            'status_url':
                'https://api.example.test/api/customer/payment/peach/123/status',
          },
        }),
      );

      final tip = successOf(
        await remote.tipCustomerAppointment(
          '77',
          amount: 25.5,
          paymentMethod: 'card',
        ),
      );

      final request = http.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/customer/appointment/77/tip');
      expect(request.data, {'amount': '25.50', 'payment_method': 'card'});
      expect(tip.isCheckoutStarted, isTrue);
      expect(tip.checkout?.depositId, '123');
      expect(
          tip.checkout?.redirectUrl, 'https://checkout.example.test/chk_123');
      expect(tip.isTipped, isFalse);
    });

    test('wallet is sent explicitly too', () async {
      useTransport(
        _ok(200, {
          'success': true,
          'code': 'tipped',
          'payment_method': 'wallet',
          'message': 'Tip sent successfully.',
          'tip_amount': 50,
          'new_wallet_balance': 74.5,
        }),
      );

      final tip = successOf(
        await remote.tipCustomerAppointment('77', amount: 50),
      );

      expect(
        http.requests.single.data,
        {'amount': '50.00', 'payment_method': 'wallet'},
      );
      expect(tip.isTipped, isTrue);
      expect(tip.newWalletBalance, 74.5);
    });

    test('card disabled: 422 payment_method_unavailable is a coded failure',
        () async {
      useTransport(
        _fail(422, {
          'success': false,
          'code': 'payment_method_unavailable',
          'message': 'Card tipping is not available yet. '
              'Please tip from your wallet.',
        }),
      );

      final error = failureOf(
        await remote.tipCustomerAppointment(
          '77',
          amount: 30,
          paymentMethod: 'card',
        ),
      );

      expect(error.statusCode, 422);
      expect(error.code, 'payment_method_unavailable');
    });
  });

  group('GET /customer/payment/peach/{deposit}/status (card tip)', () {
    for (final status in [
      'tipped',
      'pending',
      'credited_to_wallet',
      'not_paid'
    ]) {
      test('tip.status $status is read from the tip block', () async {
        useTransport(
          _ok(200, {
            'deposit_id': '123',
            'purpose': 'tip',
            'status': status == 'pending' ? 'pending' : 'successful',
            'settled': status == 'tipped',
            'amount': 30,
            'currency': 'ZAR',
            'message': 'x',
            'tip': {
              'appointment_id': '77',
              'amount': 30,
              'status': status,
              'tipped_at': null,
            },
          }),
        );

        final payment = successOf(await remote.reconcilePeachPayment('123'));

        expect(http.requests.single.path, '/customer/payment/peach/123/status');
        expect(payment.purpose, 'tip');
        expect(payment.tip?.status, status);
        expect(payment.tip?.isTipped, status == 'tipped');
        expect(payment.tip?.isFinal, status != 'pending');
      });
    }
  });

  group('payment request card', () {
    test('POST /pay with payment_method card; reads payment_id + URL',
        () async {
      useTransport(
        _ok(200, {
          'message': 'Card checkout started.',
          'status': 'pending',
          'payment_method': 'card',
          'payment': {
            'payment_id': '31',
            'checkout_id': 'chk_31',
            'redirect_url': 'https://checkout.example.test/chk_31',
            'reused': false,
          },
          'data': {'id': 9, 'status': 'accepted', 'total_amount': 300},
        }),
      );

      final checkout = successOf(
        await remote.startPaymentRequestCardCheckout(9),
      );

      final request = http.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/payment-requests/9/pay');
      expect(request.data, {'payment_method': 'card'});
      expect(checkout.paymentId, '31');
      expect(checkout.canOpenCheckout, isTrue);
      expect(checkout.reused, isFalse);
      expect(checkout.paymentRequest?.id, 9);
    });

    test('status: paid is the only success signal', () async {
      useTransport(
        _ok(200, {
          'payment_id': '31',
          'payment_method': 'card',
          'payment_status': 'successful',
          'verification': 'settled',
          'paid': true,
          'payment_request_status': 'paid',
          'message': 'Payment verified. The payment request has been paid.',
          'data': {'id': 9, 'status': 'paid', 'total_amount': 300},
        }),
      );

      final status = successOf(
        await remote.getPaymentRequestCardPaymentStatus(9, '31'),
      );

      final request = http.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/payment-requests/9/payments/31/status');
      expect(status.paid, isTrue);
      expect(status.paymentRequest?.isPaid, isTrue);
    });

    test('status: anything but a JSON true is not paid', () async {
      useTransport(
        _ok(200, {
          'payment_id': '31',
          'payment_status': 'successful',
          'paid': 'true',
          'payment_request_status': 'accepted',
        }),
      );

      final status = successOf(
        await remote.getPaymentRequestCardPaymentStatus(9, '31'),
      );

      expect(status.paid, isFalse);
    });

    test('status 503 (Peach unreachable) is a failure, never success',
        () async {
      useTransport(
        _fail(503, {
          'payment_id': '31',
          'payment_status': 'pending',
          'verification': 'unknown',
          'paid': false,
          'message': 'The card payment has not been confirmed yet.',
        }),
      );

      final error = failureOf(
        await remote.getPaymentRequestCardPaymentStatus(9, '31'),
      );

      expect(error.statusCode, 503);
    });
  });
}
