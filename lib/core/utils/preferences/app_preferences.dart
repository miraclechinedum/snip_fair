import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/errors/exception/local_exception.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';

@Injectable()
class LocalKeyStorage {
  LocalKeyStorage(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  Future<bool> saveAccessToken(String token) {
    return _sharedPreferences
        .setString(SharedPrefKey.accessToken, token)
        .catchError(
          (dynamic error) => throw LocalException.sharedPreferenceError(
            'Can not save access token',
            error,
          ),
        );
  }

  String? get accessToken {
    return _sharedPreferences.getString(SharedPrefKey.accessToken);
  }

  Future<bool> saveCurrentUser(User user) {
    return _sharedPreferences
        .setString(SharedPrefKey.currentUser, jsonEncode(user.toJson()))
        .catchError(
          (dynamic error) => throw LocalException.sharedPreferenceError(
            'Can not save ${SharedPrefKey.currentUser}',
            error,
          ),
        );
  }

  User? get currentUser {
    final userString = _sharedPreferences.getString(SharedPrefKey.currentUser);
    return userString != null
        ? User.fromJson(jsonDecode(userString) as Map<String, dynamic>)
        : null;
  }

  Future<void> clearData() async {
    await _sharedPreferences.clear();
  }

  Future<bool> storeString({required String key, required String value}) async {
    return _sharedPreferences.setString(key, value).catchError(
          (dynamic error) => throw LocalException.sharedPreferenceError(
            'Could not save $key',
            error,
          ),
        );
  }

  String? getString(String key) {
    return _sharedPreferences.getString(key);
  }
}
