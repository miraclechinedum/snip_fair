import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/utils/input/input.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';

part 'verify_email_state.dart';

@Injectable()
class VerifyEmailCubit extends BaseCubit<VerifyEmailState> {
  VerifyEmailCubit(
    this._repository,
  ) : super(const VerifyEmailState.initial());

  final AuthenticationRepository _repository;

  void onOtpChanged(String value) {
    emit(state.copyWith(otp: OtpInput.dirty(value)));
  }

  Future<void> verifyEmail() async {
    await launchApiCall(
      () => _repository.verifyEmail(state.otp.value),
      doOnLoading: () => emit(state.copyWith(result: const ProcessState.loading())),
      doOnError: (p0) => emit(state.copyWith(result: ProcessState.error(p0))),
      doOnSuccess: (p0) => emit(state.copyWith(result: ProcessState.success(p0))),
    );
  }

  Future<void> resendVerificationEmail(String email) async {
    Fluttertoast.showToast(
      msg: 'Resending verification email...',
    );

    final response = await _repository.resendVerificationEmail(email);
    response.when(
      success: (data) {
        Fluttertoast.showToast(
          msg: data.message ?? 'Verification email resent successfully.',
        );
      },
      failure: (error) {
        Fluttertoast.showToast(
          msg: error.errorResponse?.message ?? 'Failed to resend verification email.',
        );
      },
    );
  }
}
