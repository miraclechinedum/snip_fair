import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/remote/mapper/error_response_mapper.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/errors/exception/mapper/http_request_exception_mapper.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/utils/input/email_input.dart';
import 'package:snip_fair/features/authentication/login/cubit/login_cubit.dart';
import 'package:snip_fair/features/authentication/signup/cubit/signup_cubit.dart';

class _MockAuthRepository extends Mock implements AuthenticationRepository {}

void main() {
  group('EmailInput.normalize', () {
    test('trims and lowercases every capitalisation to one address', () {
      for (final input in [
        'Miracle@example.com',
        'MIRACLE@example.com',
        'miracle@example.com',
        '  MiRaClE@ExAmPlE.CoM  ',
      ]) {
        expect(EmailInput.normalize(input), 'miracle@example.com',
            reason: input);
      }
    });

    test('existing format validation still accepts mixed case', () {
      expect(const EmailInput.dirty('Miracle@Example.com').isValid, isTrue);
      expect(const EmailInput.dirty('not-an-email').isValid, isFalse);
    });
  });

  group('requests send the normalised email', () {
    test('login: uppercase and mixed case become lowercase', () {
      for (final input in ['MIRACLE@EXAMPLE.COM', ' Miracle@Example.com ']) {
        final params = LoginCubit.loginParams(
          email: input,
          password: 'Secret#1',
          deviceName: 'iPhone',
        );
        expect(params.email, 'miracle@example.com', reason: input);
        // The password is untouched.
        expect(params.password, 'Secret#1');
        expect(params.toJson()['email'], 'miracle@example.com');
      }
    });

    test('signup: uppercase and mixed case become lowercase', () {
      for (final input in ['MIRACLE@example.com', 'Miracle@Example.COM']) {
        final cubit = SignupCubit(_MockAuthRepository())
          ..onFirstNameChanged('Miracle')
          ..onEmailChanged(input)
          ..onPasswordChanged('Secret#1');
        addTearDown(cubit.close);

        final params =
            SignupCubit.registerParams(cubit.state, deviceName: 'iPhone');

        expect(params.email, 'miracle@example.com', reason: input);
        expect(params.firstName, 'Miracle');
        expect(params.password, 'Secret#1');
      }
    });
  });

  group('duplicate email', () {
    RemoteException laravel422(Map<String, dynamic> body) =>
        HttpRequestExceptionMapper(ErrorResponseMapper()).map(
          DioException(
            requestOptions: RequestOptions(path: '/register/stylist'),
            type: DioExceptionType.badResponse,
            response: Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/register/stylist'),
              statusCode: 422,
              data: body,
            ),
          ),
        );

    test("Laravel's duplicate-email 422 becomes a friendly message", () {
      final error = laravel422({
        'message': 'The email has already been taken.',
        'errors': {
          'email': ['The email has already been taken.'],
        },
      });

      final shown = SignupCubit.friendlySignUpError(error) as RemoteException;

      expect(shown.errorResponse?.message, SignupCubit.duplicateEmailMessage);
      expect(shown.statusCode, 422);
    });

    test('other validation errors are left as they are', () {
      final error = laravel422({
        'message': 'The phone field is required.',
        'errors': {
          'phone': ['The phone field is required.'],
        },
      });

      expect(identical(SignupCubit.friendlySignUpError(error), error), isTrue);
    });

    test('non-422 failures are left as they are', () {
      const error = RemoteException.serverError(
        500,
        ServerError(message: 'Server Error'),
      );
      expect(identical(SignupCubit.friendlySignUpError(error), error), isTrue);
      final other = Exception('x');
      expect(identical(SignupCubit.friendlySignUpError(other), other), isTrue);
    });
  });
}
