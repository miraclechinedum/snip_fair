import 'package:snip_fair/core/errors/exception/remote_exception.dart';

/// How a failed `POST /wallet/withdraw` must be treated.
///
/// Laravel stores an idempotency key only once it has recorded a withdrawal,
/// so after a definite refusal (400/403/422/429/503) of a first send the key
/// was not used and may be resent with the same details. Most refusals
/// (middleware, kill switch, validation) happen before Laravel's replay
/// check, so a refusal of a *retry* says nothing about the earlier send.
enum WithdrawalFailureKind {
  /// 503: withdrawals are switched off (`PAYOUT_REQUESTS_DISABLED`) or
  /// misconfigured. Nothing was recorded or deducted.
  disabled,

  /// 409 `IDEMPOTENCY_KEY_REUSED`: the key was already used for a different
  /// amount or method. Nothing new was recorded.
  conflict,

  /// 400 `IDEMPOTENCY_KEY_REQUIRED` / `IDEMPOTENCY_KEY_INVALID`: the backend
  /// would not accept this app's request at all.
  keyRejected,

  /// 401: the session has expired (the HTTP layer also signs the user out).
  unauthorized,

  /// 403: profile incomplete or email not verified.
  forbidden,

  /// 429: throttled before reaching the withdrawal logic.
  rateLimited,

  /// Any other 4xx (validation, insufficient balance, invalid method, …):
  /// a definite refusal; nothing was recorded or deducted.
  rejected,

  /// Timeout, lost connection or a server error: the request may or may not
  /// have been recorded. Only the same key may be resent.
  uncertain,
}

const _disabledCode = 'PAYOUT_REQUESTS_DISABLED';
const _keyReusedCode = 'IDEMPOTENCY_KEY_REUSED';
const _keyRequiredCode = 'IDEMPOTENCY_KEY_REQUIRED';
const _keyInvalidCode = 'IDEMPOTENCY_KEY_INVALID';

WithdrawalFailureKind classifyWithdrawalFailure(Object? error) {
  if (error is! RemoteException) return WithdrawalFailureKind.uncertain;

  final status = error.statusCode;
  if (error.code == _disabledCode || status == 503) {
    return WithdrawalFailureKind.disabled;
  }
  if (error.code == _keyReusedCode || status == 409) {
    return WithdrawalFailureKind.conflict;
  }
  if (error.code == _keyRequiredCode || error.code == _keyInvalidCode) {
    return WithdrawalFailureKind.keyRejected;
  }
  if (status == 401) return WithdrawalFailureKind.unauthorized;
  if (status == 403) return WithdrawalFailureKind.forbidden;
  if (status == 429) return WithdrawalFailureKind.rateLimited;
  // 408 means the server gave up waiting: treated as an unknown outcome.
  if (status != null && status >= 400 && status < 500 && status != 408) {
    return WithdrawalFailureKind.rejected;
  }
  // No response (timeout, no connection, cancelled) or a 5xx.
  return WithdrawalFailureKind.uncertain;
}

extension WithdrawalFailureKindX on WithdrawalFailureKind {
  /// The request may have been recorded: the stylist is offered a retry and
  /// the balance and history are reloaded.
  bool get isUncertain => this == WithdrawalFailureKind.uncertain;
}

/// Why the app refused to send a withdrawal itself (nothing was sent).
enum WithdrawalBlockReason {
  /// An earlier attempt may have been recorded and is not yet resolved.
  unresolvedAttempt,

  /// A saved attempt could not be read; it may have gone through.
  unreadableAttempt,

  /// The attempt could not be saved on the device, so a retry after a
  /// restart could not reuse its key.
  storageUnavailable,
}

class WithdrawalBlockedException implements Exception {
  const WithdrawalBlockedException(this.reason);

  final WithdrawalBlockReason reason;

  @override
  String toString() => 'WithdrawalBlockedException(${reason.name})';
}
