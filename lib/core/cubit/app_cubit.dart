import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart' hide Environment;
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';

part 'app_state.dart';

@Injectable()
class AppCubit extends Cubit<AppState> {
  AppCubit(this._repository) : super(const AppState.initial());

  final AuthenticationRepository _repository;

  Future<void> onAppStarted() async {
    await Future.delayed(Duration(seconds: 2));

    emit(const AppState.unAuthenticated());
  }

  Future<void> onLogin() async {}

  void onLogout() {}

  void onUpdateUser() {}
}
