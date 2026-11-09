import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_attempt.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';

/// What [WithdrawalAttemptStore.load] found.
sealed class StoredWithdrawalAttempt {
  const StoredWithdrawalAttempt();
}

/// Nothing is pending for the signed-in stylist.
class NoStoredWithdrawalAttempt extends StoredWithdrawalAttempt {
  const NoStoredWithdrawalAttempt();
}

class FoundWithdrawalAttempt extends StoredWithdrawalAttempt {
  const FoundWithdrawalAttempt(this.attempt);

  final WithdrawalAttempt attempt;
}

/// An entry exists but cannot be used (corrupt, unknown version, or storage
/// could not be read). Its request may still have reached the backend, so
/// this must be surfaced, never silently treated as "nothing pending".
class UnreadableWithdrawalAttempt extends StoredWithdrawalAttempt {
  const UnreadableWithdrawalAttempt();
}

/// Keeps the stylist's unresolved withdrawal attempt (idempotency key,
/// amount, payout method, status) on the device, so a retry after an app
/// restart, a logout or leaving the earnings screen resends the same key.
///
/// Stored in [SharedPreferences] under `withdrawal_attempt.v1.<userId>`, the
/// project's convention for per-user attempt data (see
/// `LocalPaymentRequestAttemptStore`), next to the access token. The key is
/// an opaque UUID that only works with that token. At most one attempt per
/// user; it is removed once resolved — not on logout.
@Injectable()
class WithdrawalAttemptStore {
  WithdrawalAttemptStore(this._prefs);

  final SharedPreferences _prefs;

  static const _version = 1;

  /// The backend's key format; a UUID always satisfies it.
  static final _keyFormat = RegExp(r'^[A-Za-z0-9._:-]{8,100}$');

  /// The signed-in user's id, read straight from the cached user JSON so a
  /// change to the `User` model cannot make the attempt unreachable.
  String? _currentUserId() {
    final raw = _prefs.getString(SharedPrefKey.currentUser);
    if (raw == null) return null;
    final json = jsonDecode(raw);
    final id = json is Map<String, dynamic> ? json['id'] : null;
    return id is int || id is String ? '$id' : null;
  }

  String? _storageKey() {
    final userId = _currentUserId();
    return userId == null || userId.isEmpty
        ? null
        : '${SharedPrefKey.pendingWithdrawalPrefix}$userId';
  }

  StoredWithdrawalAttempt load() {
    try {
      final key = _storageKey();
      // Without a user nothing can have been saved (see [save]).
      if (key == null) return const NoStoredWithdrawalAttempt();
      final raw = _prefs.getString(key);
      if (raw == null) return const NoStoredWithdrawalAttempt();
      final attempt = _decode(raw);
      return attempt == null
          ? const UnreadableWithdrawalAttempt()
          : FoundWithdrawalAttempt(attempt);
    } catch (_) {
      return const UnreadableWithdrawalAttempt();
    }
  }

  /// False when the attempt could not be stored; the caller must then not
  /// send a new request it could not recover after a restart.
  Future<bool> save(WithdrawalAttempt attempt) async {
    try {
      final key = _storageKey();
      if (key == null) return false;
      return await _prefs.setString(key, jsonEncode(_encode(attempt)));
    } catch (_) {
      return false;
    }
  }

  /// Removes the saved attempt once it is resolved. With [idempotencyKey],
  /// only when that attempt is still the one saved, so a cubit never removes
  /// an attempt another screen saved in the meantime.
  Future<bool> clear({String? idempotencyKey}) async {
    try {
      final key = _storageKey();
      if (key == null) return true;
      if (idempotencyKey != null) {
        final raw = _prefs.getString(key);
        if (raw == null) return true;
        final stored = _decode(raw);
        if (stored?.idempotencyKey != idempotencyKey) return false;
      }
      return await _prefs.remove(key);
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> _encode(WithdrawalAttempt attempt) => {
        'v': _version,
        'key': attempt.idempotencyKey,
        'method': attempt.paymentMethodId,
        'amount_cents': WithdrawalAttempt.toCents(attempt.amount),
        'status': attempt.status.name,
      };

  /// Null when the key or the exact payload cannot be recovered — then the
  /// request cannot be safely retried. Anything else that is off (another
  /// version, a missing or unknown status) is recovered as
  /// [WithdrawalAttemptStatus.unknown], the most cautious status, rather
  /// than lose a key that may belong to an accepted withdrawal.
  static Object? _tryJson(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static WithdrawalAttempt? _decode(String raw) {
    final json = _tryJson(raw);
    if (json is! Map<String, dynamic>) return null;
    final key = json['key'];
    final rawMethod = json['method'];
    final method = rawMethod is int ? '$rawMethod' : rawMethod;
    final cents = json['amount_cents'];
    if (key is! String ||
        !_keyFormat.hasMatch(key) ||
        method is! String ||
        int.tryParse(method) == null ||
        cents is! int ||
        cents <= 0) {
      return null;
    }
    final status = json['v'] == _version
        ? WithdrawalAttemptStatus.values
            .where((s) => s.name == json['status'])
            .firstOrNull
        : null;
    return WithdrawalAttempt(
      idempotencyKey: key,
      paymentMethodId: method,
      amount: cents / 100,
      status: status ?? WithdrawalAttemptStatus.unknown,
    );
  }
}
