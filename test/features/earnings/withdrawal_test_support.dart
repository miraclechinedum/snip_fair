import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';
import 'package:snip_fair/core/utils/preferences/withdrawal_attempt_store.dart';

const testStylistId = 42;

/// A fresh preferences store with [userId] signed in.
Future<SharedPreferences> stylistPrefs({
  int userId = testStylistId,
  Map<String, Object> values = const {},
}) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({
    SharedPrefKey.currentUser: jsonEncode({'id': userId, 'type': 'stylist'}),
    ...values,
  });
  return SharedPreferences.getInstance();
}

Future<WithdrawalAttemptStore> stylistAttemptStore() async =>
    WithdrawalAttemptStore(await stylistPrefs());

/// Simulates an app restart: a brand-new [SharedPreferences] instance loaded
/// only from what [prefs] persisted.
Future<SharedPreferences> restartPrefs(SharedPreferences prefs) async {
  final persisted = {for (final key in prefs.getKeys()) key: prefs.get(key)!};
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(persisted);
  return SharedPreferences.getInstance();
}

String attemptStorageKey([int userId = testStylistId]) =>
    '${SharedPrefKey.pendingWithdrawalPrefix}$userId';
