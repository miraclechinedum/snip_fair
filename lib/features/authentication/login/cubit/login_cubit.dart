import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';

import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/domain/params/login_params.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/email_input.dart';
import 'package:snip_fair/core/utils/input/password_input.dart';

part 'login_state.dart';

@Injectable()
class LoginCubit extends BaseCubit<LoginState> {
  LoginCubit(
    this._repository,
  ) : super(LoginState.initial());

  final AuthenticationRepository _repository;

  void onEmailChanged(String value) {
    emit(state.copyWith(email: EmailInput.dirty(value)));
  }

  void onPasswordChanged(String value) {
    emit(state.copyWith(password: PasswordInput.dirty(value: value)));
  }

  Future<void> login() async {
    await launchApiCall(
      () => _repository.login(
        LoginParams(email: state.email.value, password: state.password.value),
      ),
      doOnLoading: () =>
          emit(state.copyWith(loginResult: const ProcessState.loading())),
      doOnError: (p0) =>
          emit(state.copyWith(loginResult: ProcessState.error(p0))),
      doOnSuccess: (p0) =>
          emit(state.copyWith(loginResult: ProcessState.success(p0))),
    );
  }
}
