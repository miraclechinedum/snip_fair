import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';

import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/email_input.dart';

part 'forgot_password_state.dart';

@Injectable()
class ForgotPasswordCubit extends BaseCubit<ForgotPasswordState> {
  ForgotPasswordCubit(
    this._repository,
  ) : super(const ForgotPasswordState.initial());

  final AuthenticationRepository _repository;

  void onEmailChanged(String value) {
    emit(state.copyWith(email: EmailInput.dirty(value)));
  }

  Future<void> forgotPassword() async {
    await launchApiCall(
      () => _repository.forgotPassowrd(state.email.value),
      doOnLoading: () =>
          emit(state.copyWith(result: const ProcessState.loading())),
      doOnError: (p0) => emit(state.copyWith(result: ProcessState.error(p0))),
      doOnSuccess: (p0) =>
          emit(state.copyWith(result: ProcessState.success(p0))),
    );
  }
}
