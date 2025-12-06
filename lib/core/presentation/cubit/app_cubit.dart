import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart' hide Environment;
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';

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
    final localStorage = getIt<LocalKeyStorage>();
    final result = await _repository.getPlatformSettings();
    await result.when(
      success: (settings) async {
        await localStorage.storeString(
          key: SharedPrefKey.platformSettings,
          value: jsonEncode(settings.toJson()),
        );
        emit(AppState.initial(state.user, settings));
      },
      failure: (error) {
        final settingsString =
            localStorage.getString(SharedPrefKey.platformSettings);

        if (settingsString != null) {
          final settings = PlatformSettings.fromJson(
            jsonDecode(settingsString) as Map<String, dynamic>,
          );
          emit(AppState.initial(state.user, settings));
          return;
        }
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
        final fcmToken = await NotificationService.instance.getToken();
        log('FCM Token: $fcmToken');
        if (fcmToken != null) await updateDeviceToken(fcmToken);
      },
      failure: (error) {
        emit(AppState.unAuthenticated(state.platformSettings));
      },
    );
  }

  Future<void> onLogout() async {
    emit(AppState.initial(state.user, state.platformSettings));
    final result = await _repository.logout();
    result.when(
      success: (user) {
        emit(AppState.unAuthenticated(state.platformSettings));
      },
      failure: (error) {
        emit(AppState.unAuthenticated(state.platformSettings));
      },
    );
  }

  void onUpdateUser() {
    _getUserDetails();
  }

  Future<void> updateDeviceToken(String fcmToken) async {
    await _repository.updateUser(fcmToken: fcmToken);
  }

  void setGuestUser() {
    emit(AppState.guest(settings: state.platformSettings));
  }
}
