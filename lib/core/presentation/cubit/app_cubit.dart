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
import 'package:snip_fair/core/services/analytics_service.dart';
import 'package:snip_fair/core/services/chat_draft_service.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';

part 'app_state.dart';

@Injectable()
class AppCubit extends Cubit<AppState> {
  AppCubit(this._repository) : super(const AppState.initial()) {
    // Firebase can rotate FCM tokens at any time (uninstall/reinstall,
    // long inactivity, iCloud restore, etc.). When that happens the old
    // token stored on the backend becomes invalid and pushes silently
    // drop. Re-register on every rotation so the backend always has a
    // deliverable token.
    _tokenRefreshSub = NotificationService.instance.tokenRefreshes.listen(
      (newToken) {
        log('AppCubit: FCM token rotated, re-registering with backend');
        updateDeviceToken(newToken);
      },
    );
  }

  final ProfileRepository _repository;
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    return super.close();
  }

  Future<void> onAppStarted() {
    return _getPlatformSettings().then((_) {
      _getUserDetails();
    });
  }

  Future<void> onLogin({String method = 'email'}) {
    unawaited(AnalyticsService.instance.logLogin(method: method));
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
        if (fcmToken != null && fcmToken.isNotEmpty) {
          log('FCM token obtained (${fcmToken.length} chars) — registering '
              'with backend');
          try {
            await updateDeviceToken(fcmToken);
            log('FCM token registered with backend successfully');
          } catch (e, s) {
            log(
              'FCM token registration FAILED: $e',
              error: e,
              stackTrace: s,
            );
          }
        } else {
          // No token — most common causes: user denied push permission,
          // iOS Simulator without APNs simulation, or Firebase not fully
          // initialized. Backend won't be able to reach this device.
          log('FCM token is null/empty — backend cannot push to this device');
        }
      },
      failure: (error) {
        emit(AppState.unAuthenticated(state.platformSettings));
      },
    );
  }

  Future<void> onLogout() async {
    // Snapshot the departing user id before the state is torn down — used
    // below to wipe their chat drafts so the next user on this device can't
    // see them.
    final departingUserId = state.user.id?.toString();

    emit(AppState.initial(state.user, state.platformSettings));
    final result = await _repository.logout();
    // Clear the stored access token so it can't be attached to later
    // (guest-mode) requests. The backend has already invalidated it.
    await getIt<LocalKeyStorage>().deleteAccessToken();
    if (departingUserId != null) {
      unawaited(
        ChatDraftService.instance.clearAllForUser(departingUserId),
      );
    }
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
    // Any leftover access token from a prior session must not be attached to
    // requests made in guest mode — that has caused the backend to 500 on
    // otherwise-anonymous list endpoints.
    unawaited(getIt<LocalKeyStorage>().deleteAccessToken());
    emit(AppState.guest(settings: state.platformSettings));
  }
}
