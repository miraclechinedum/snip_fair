import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';

abstract class ProfileRepository {
  Future<ApiResult<User>> getUser();
  Future<ApiResult<SimpleResponse>> logout();
  Future<ApiResult<SimpleResponse>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<ApiResult<SimpleResponse>> updateLocationConsent(bool value);

  Future<ApiResult<SimpleResponse>> updateUserLocation({
    required num latitude,
    required num longitude,
    required num accuracy,
  });
}

@Injectable(as: ProfileRepository)
class ProfileRepoImpl implements ProfileRepository {
  ProfileRepoImpl(this._localKeyStorage, this._remoteSource);

  final LocalKeyStorage _localKeyStorage;
  final SnipFairBackendRemoteSource _remoteSource;

  @override
  Future<ApiResult<User>> getUser() async {
    final result = await _remoteSource.getUser();
    return result.map(
      success: (data) {
        _localKeyStorage.saveCurrentUser(data.data);
        return data;
      },
      failure: (f) => f,
    );
  }

  @override
  Future<ApiResult<SimpleResponse>> logout() async {
    final result = await _remoteSource.logout();
    await _localKeyStorage.clearData();
    return result;
  }

  @override
  Future<ApiResult<SimpleResponse>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _remoteSource.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateLocationConsent(bool value) =>
      _remoteSource.updateLocationConsent(value);

  @override
  Future<ApiResult<SimpleResponse>> updateUserLocation({
    required num latitude,
    required num longitude,
    required num accuracy,
  }) =>
      _remoteSource.updateUserLocation(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
}
