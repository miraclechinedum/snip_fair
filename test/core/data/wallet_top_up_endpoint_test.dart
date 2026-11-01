import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/mapper/error_response_mapper.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/errors/exception/mapper/http_request_exception_mapper.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';

const _kBaseUrl = 'http://127.0.0.1:8002/api';

class _MockLocalKeyStorage extends Mock implements LocalKeyStorage {}

/// Serves every request from [reply] instead of the network and records it.
class _FakeHttpService implements HttpService {
  _FakeHttpService(this.reply);

  final void Function(RequestOptions, RequestInterceptorHandler) reply;
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

/// Laravel's `PaymentController::initiate` success body for a top-up.
const _peachCheckoutBody = <String, dynamic>{
  'status': true,
  'processor': 'peachpayment',
  'deposit_id': 123,
  'checkoutId': 'chk_test',
  'redirectUrl': 'https://sandbox.example/checkout',
};

void _ok(RequestOptions options, RequestInterceptorHandler handler) {
  handler.resolve(
    Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: 200,
      data: _peachCheckoutBody,
    ),
  );
}

void Function(RequestOptions, RequestInterceptorHandler) _fail(
  int status,
  Map<String, dynamic> body,
) =>
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
  late ProfileRepository repository;

  void useTransport(
    void Function(RequestOptions, RequestInterceptorHandler) reply,
  ) {
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
    useTransport(_ok);
    remote = SnipFairBackendRemoteSource();
    repository = ProfileRepoImpl(_MockLocalKeyStorage(), remote);
  });

  tearDown(getIt.reset);

  void expectTopUpRequest(RequestOptions request, num amount) {
    expect(request.method, 'POST');
    expect(request.path, '/payment/topup');
    expect(request.uri.toString(), '$_kBaseUrl/payment/topup');
    expect(request.data, {'type': 'topup', 'amount': amount});
  }

  test('top-up path matches Laravel POST /api/payment/topup', () {
    expect(AuthPath.customerPaymentTopUp, '/payment/topup');
  });

  test('posts type=topup and the amount to /payment/topup', () async {
    final result = await remote.initializeWalletTopUp(amount: 50);

    expectTopUpRequest(http.requests.single, 50);
    final checkout = result.when(
      success: (data) => data,
      failure: (error) => fail('unexpected failure: $error'),
    );
    expect(checkout.canOpenCheckout, isTrue);
    expect(checkout.depositId, '123');
    expect(checkout.redirectUrl, 'https://sandbox.example/checkout');
  });

  test('404 from a missing route is a preserved failure', () async {
    useTransport(
      _fail(404, {
        'message': 'The route api/payment/topup could not be found.',
      }),
    );

    final result = await remote.initializeWalletTopUp(amount: 50);

    final error = result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => error,
    );
    expect(error.statusCode, 404);
    expect(error.kind, RemoteExceptionKind.server);
    expect(
      ConversationsCubit.topUpFailureMessage(error),
      ConversationsCubit.paymentStartFailedMessage,
    );
  });

  test('Peach status check path is unchanged', () async {
    useTransport(
      (options, handler) => handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {'status': 'pending', 'settled': false},
        ),
      ),
    );

    await remote.reconcilePeachPayment('123');

    expect(http.requests.single.method, 'GET');
    expect(http.requests.single.path, '/customer/payment/peach/123/status');
  });

  group('every top-up flow shares the corrected endpoint', () {
    test('wallet screen and booking shortfall (CustomerProfileMgtCubit)',
        () async {
      // TopUpWalletWidget and the booking wallet-shortfall path both call
      // CustomerProfileMgtCubit.initializeWalletTopUp.
      final cubit = CustomerProfileMgtCubit(repository);
      addTearDown(cubit.close);

      await cubit.initializeWalletTopUp(amount: 120);

      expectTopUpRequest(http.requests.single, 120);
      expect(cubit.state.activeTopUp?.depositId, '123');
    });

    test('payment request card and wallet-shortfall (ConversationsCubit)',
        () async {
      final cubit = ConversationsCubit(repository);
      addTearDown(cubit.close);

      final checkout = await cubit.startCardTopUp(2, amount: 50);

      expectTopUpRequest(http.requests.single, 50);
      expect(checkout?.depositId, '123');
      expect(
        cubit.paymentProgressFor(2).phase,
        PaymentRequestPaymentPhase.checkoutOpen,
      );

      // The open-checkout guard stops a second checkout for the request.
      expect(await cubit.startCardTopUp(2, amount: 50), isNull);
      expect(http.requests, hasLength(1));
    });

    test('payment request start surfaces a 400 backend refusal', () async {
      useTransport(
        _fail(400, {
          'success': false,
          'message': 'Bookings are paused for maintenance.',
        }),
      );
      final cubit = ConversationsCubit(repository);
      addTearDown(cubit.close);

      expect(await cubit.startCardTopUp(2, amount: 50), isNull);

      final progress = cubit.paymentProgressFor(2);
      expect(progress.phase, PaymentRequestPaymentPhase.failed);
      expect(progress.message, 'Bookings are paused for maintenance.');
    });

    test("the backend's string status no longer hides its message", () async {
      // PaymentController::initiate sends `'status' => 'false'` (a string)
      // when Peach card collection is disabled.
      useTransport(
        _fail(400, {
          'status': 'false',
          'message': 'Selected payment method is currently not available',
        }),
      );
      final cubit = ConversationsCubit(repository);
      addTearDown(cubit.close);

      expect(await cubit.startCardTopUp(2, amount: 50), isNull);

      expect(
        cubit.paymentProgressFor(2).message,
        'Selected payment method is currently not available',
      );
    });
  });

  group('wallet top-up retry (B1)', () {
    void statusReply(String status, {int code = 200}) => useTransport(
          (options, handler) {
            if (options.path == '/payment/topup') return _ok(options, handler);
            final body = <String, dynamic>{
              'deposit_id': '123',
              'purpose': 'wallet_topup',
              'status': status,
              'settled': false,
              'amount': 120,
            };
            if (code == 200) {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: body,
                ),
              );
            } else {
              _fail(code, body)(options, handler);
            }
          },
        );

    setUp(() => CustomerProfileMgtCubit.topUpReconcileRetryGap = Duration.zero);

    int topUpCalls() =>
        http.requests.where((r) => r.path == '/payment/topup').length;

    test('a second top-up starts once the first is verified', () async {
      // settled:false — the webhook credited the wallet first. Still success.
      statusReply('successful');
      final cubit = CustomerProfileMgtCubit(repository);
      addTearDown(cubit.close);

      await cubit.initializeWalletTopUp(amount: 120);
      await cubit.reconcileWalletTopUp();

      expect(cubit.state.topUpVerificationState.data?.isVerified, isTrue);
      expect(cubit.state.activeTopUp, isNull);

      await cubit.initializeWalletTopUp(amount: 80);
      expect(topUpCalls(), 2);
      expect(cubit.state.activeTopUp?.depositId, '123');
    });

    test('a second top-up starts after a failed or cancelled one', () async {
      for (final status in ['failed', 'cancelled']) {
        statusReply(status);
        final cubit = CustomerProfileMgtCubit(repository);
        addTearDown(cubit.close);

        await cubit.initializeWalletTopUp(amount: 120);
        await cubit.reconcileWalletTopUp();
        await cubit.initializeWalletTopUp(amount: 120);

        expect(topUpCalls(), 2, reason: status);
      }
    });

    test('an unresolved top-up is not duplicated', () async {
      for (final (status, code) in [('pending', 200), ('unknown', 503)]) {
        statusReply(status, code: code);
        final cubit = CustomerProfileMgtCubit(repository);
        addTearDown(cubit.close);

        await cubit.initializeWalletTopUp(amount: 120);
        await cubit.reconcileWalletTopUp();
        await cubit.initializeWalletTopUp(amount: 120);

        expect(topUpCalls(), 1, reason: status);
        expect(cubit.state.activeTopUp?.depositId, '123', reason: status);
        expect(
          cubit.state.topUpVerificationState.data?.isVerified ?? false,
          isFalse,
          reason: status,
        );
      }
    });
  });

  group('error parsing', () {
    Future<RemoteException> failWith(int status, Map<String, dynamic> body) async {
      useTransport(_fail(status, body));
      final result = await remote.initializeWalletTopUp(amount: 50);
      return result.when(
        success: (_) => fail('expected failure'),
        failure: (error) => error,
      );
    }

    test('boolean status', () async {
      final error = await failWith(400, {
        'status': false,
        'message': 'Top-up failed. Please try again.',
      });
      expect(error.errorResponse?.status, isFalse);
      expect(error.errorResponse?.message, 'Top-up failed. Please try again.');
    });

    test('string status', () async {
      final error = await failWith(400, {
        'status': 'false',
        'message': 'Selected payment method is currently not available',
      });
      expect(error.errorResponse?.status, isFalse);
      expect(
        error.errorResponse?.message,
        'Selected payment method is currently not available',
      );
    });

    test('structured code with integer amounts (insufficient balance)',
        () async {
      final error = await failWith(400, {
        'message': 'Insufficient wallet balance.',
        'code': 'insufficient_wallet_balance',
        'wallet_balance': 40,
        'required_amount': 150,
        'shortfall': 110,
      });
      expect(error.code, 'insufficient_wallet_balance');
      expect(error.numberField('shortfall'), 110);
      expect(error.numberField('wallet_balance'), 40);
      expect(error.numberField('required_amount'), 150.0);
    });

    test('already_paid keeps its data payload', () async {
      final error = await failWith(400, {
        'message': 'This payment request has already been paid.',
        'code': 'already_paid',
        'reason': 'Payment request has already been paid.',
        'data': {'id': 1, 'status': 'paid'},
      });
      expect(error.code, 'already_paid');
      expect(error.responseBody?['data'], {'id': 1, 'status': 'paid'});
    });

    test('an error body without status or code still parses', () async {
      final error = await failWith(422, {
        'message': 'The amount field must be greater than 0.',
        'errors': {
          'amount': ['The amount field must be greater than 0.'],
        },
      });
      expect(error.code, isNull);
      expect(error.statusCode, 422);
      expect(
        error.errorResponse?.message,
        'The amount field must be greater than 0.',
      );
    });
  });

  group('payment request /pay', () {
    test('posts with no body and reads code "paid"', () async {
      useTransport(
        (options, handler) => handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'message': 'Payment successful.',
              'code': 'paid',
              'payment_method': 'wallet',
              'data': {'id': 1, 'status': 'paid', 'total_amount': 150},
              'new_wallet_balance': 0,
            },
          ),
        ),
      );

      final result = await remote.payPaymentRequest(1);

      final request = http.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/payment-requests/1/pay');
      expect(request.data, isNull);
      final pay = result.when(
        success: (data) => data,
        failure: (error) => fail('unexpected failure: $error'),
      );
      expect(pay.isPaid, isTrue);
      expect(pay.paymentRequest?.isPaid, isTrue);
      expect(pay.paymentRequest?.totalAmount, 150);
      expect(pay.newWalletBalance, 0);
    });
  });

  test('status response with an integer amount and string deposit id parses',
      () async {
    useTransport(
      (options, handler) => handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'deposit_id': '1',
            'purpose': 'wallet_topup',
            'status': 'successful',
            'settled': false,
            'appointment_id': null,
            'transaction_reference': 'WALLET-TOPUP-1793528994',
            'amount': 110,
            'currency': 'ZAR',
            'message': 'Payment verified successfully.',
          },
        ),
      ),
    );

    final result = await remote.reconcilePeachPayment('1');

    final payment = result.when(
      success: (data) => data,
      failure: (error) => fail('unexpected failure: $error'),
    );
    expect(payment.amount, 110);
    expect(payment.depositId, '1');
    expect(payment.isVerified, isTrue);
    // Booking's stricter rule is unchanged.
    expect(payment.isSuccessful, isFalse);
  });
}
