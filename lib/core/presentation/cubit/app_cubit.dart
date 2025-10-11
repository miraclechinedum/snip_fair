import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart' hide Environment;
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/network/api_result.dart';

part 'app_state.dart';

@Injectable()
class AppCubit extends Cubit<AppState> {
  AppCubit(this._repository) : super(const AppState.initial());

  final ProfileRepository _repository;

  Future<void> onAppStarted() {
    return _getPlatformSettings().then((_) {
      _getUserDetails();
    });
  }

  Future<void> onLogin() {
    return _getUserDetails();
  }

  Future<void> _getPlatformSettings() async {
    emit(AppState.initial(state.user, state.platformSettings));
    final result = await _repository.getPlatformSettings();
    result.when(
      success: (settings) {
        emit(AppState.initial(state.user, settings));
      },
      failure: (error) {
        emit(AppState.initial(state.user));
      },
    );
  }

  Future<void> _getUserDetails() async {
    emit(AppState.initial(state.user, state.platformSettings));
    final result = await _repository.getUser();
    await result.when(
      success: (user) async {
        emit(
          AppState.authenticated(
            user: user,
            settings: state.platformSettings,
          ),
        );
      },
      failure: (error) {
        emit(AppState.unAuthenticated(state.platformSettings));
      },
    );
  }

  Future<void> onLogout() async {
    emit(AppState.initial(state.user));
    final result = await _repository.logout();
    result.when(
      success: (user) {
        emit(AppState.unAuthenticated(state.platformSettings));
      },
      failure: (error) {
        emit(
          AppState.authenticated(
            user: state.user,
            settings: state.platformSettings,
          ),
        );
      },
    );
  }

  void onUpdateUser() {
    _getUserDetails();
  }
}
