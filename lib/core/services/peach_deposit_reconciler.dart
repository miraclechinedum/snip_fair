import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';

/// Outcome of polling `GET /customer/payment/peach/{deposit}/status`.
enum PeachDepositVerdict {
  /// HTTP 200 and the caller's success rule held.
  verified,

  /// HTTP 200, not (yet) paid — e.g. `pending`, or `successful` without the
  /// caller's stricter rule.
  pending,

  /// HTTP 200 `failed` — the customer may start a new payment.
  failed,

  /// HTTP 200 `cancelled` — the customer may start a new payment.
  cancelled,

  /// No HTTP 200 verdict (503 `unknown`, network failure, 404/422). Never a
  /// success; the deposit must be kept and checked again.
  unknown,
}

class PeachDepositCheck {
  const PeachDepositCheck(this.verdict, {this.payment, this.error});

  final PeachDepositVerdict verdict;

  /// The last HTTP 200 status body seen, if any.
  final PaymentReconciliation? payment;

  /// The last request failure, if the final attempt failed.
  final RemoteException? error;
}

/// A bounded back-off for background status checks: wait each delay in turn
/// (the first before the first check), never past [maxDuration] in total.
class PeachPollSchedule {
  const PeachPollSchedule({required this.delays, required this.maxDuration});

  final List<Duration> delays;
  final Duration maxDuration;
}

/// Stateless polling of a Peach deposit's status. Callers own every state
/// transition, message and navigation; this only turns status responses into
/// a [PeachDepositVerdict].
class PeachDepositReconciler {
  PeachDepositReconciler(
    this._fetchStatus, {
    Future<void> Function(Duration)? sleep,
    DateTime Function()? now,
  })  : _sleep = sleep ?? _delay,
        _now = now ?? DateTime.now;

  final Future<ApiResult<PaymentReconciliation>> Function(String depositId)
      _fetchStatus;
  final Future<void> Function(Duration) _sleep;
  final DateTime Function() _now;

  static Future<void> _delay(Duration duration) =>
      Future<void>.delayed(duration);

  /// Checks [depositId] after [initialDelay], then once more after each of
  /// [retryDelays] until the verdict is verified, failed or cancelled.
  ///
  /// [isVerified] is the caller's success rule. [shouldStop] lets a caller
  /// abandon polling between attempts. With [maxDuration], no wait starts
  /// that would end past it (measured from the call, request time
  /// included), so the loop is bounded.
  Future<PeachDepositCheck> reconcile(
    String depositId, {
    required bool Function(PaymentReconciliation) isVerified,
    List<Duration> retryDelays = const [],
    Duration initialDelay = Duration.zero,
    Duration? maxDuration,
    bool Function()? shouldStop,
    String logLabel = 'deposit',
  }) async {
    PaymentReconciliation? lastSeen;
    RemoteException? lastError;
    final started = _now();
    final attempts = retryDelays.length + 1;

    for (var i = 0; i < attempts; i++) {
      final wait = i == 0 ? initialDelay : retryDelays[i - 1];
      if (wait > Duration.zero) {
        if (maxDuration != null &&
            _now().difference(started) + wait > maxDuration) {
          peachLog('Reconcile $logLabel=$depositId: polling window ended');
          break;
        }
        await _sleep(wait);
      }
      if (shouldStop?.call() ?? false) break;
      peachLog('Reconcile $logLabel=$depositId ${i + 1}/$attempts');
      final result = await _fetchStatus(depositId);
      lastError = null;
      result.when(
        success: (payment) => lastSeen = payment,
        failure: (error) {
          lastError = error;
          final bodyStatus = error.responseBody?['status'];
          final message = (error.errorResponse?.message ?? '')
              .replaceAll(RegExp(r'\s+'), ' ');
          peachLog(
            'Reconcile $logLabel=$depositId failed: '
            'kind=${error.kind.name} http=${error.statusCode ?? 'none'} '
            'status=${bodyStatus ?? 'none'} '
            'message="${message.length > 120 ? message.substring(0, 120) : message}"',
          );
        },
      );
      final seen = lastSeen;
      if (seen != null &&
          lastError == null &&
          (isVerified(seen) || seen.isFailed || seen.isCancelled)) {
        break;
      }
    }

    final seen = lastSeen;
    if (seen == null) {
      return PeachDepositCheck(PeachDepositVerdict.unknown, error: lastError);
    }
    final verdict = isVerified(seen)
        ? PeachDepositVerdict.verified
        : seen.isFailed
            ? PeachDepositVerdict.failed
            : seen.isCancelled
                ? PeachDepositVerdict.cancelled
                : PeachDepositVerdict.pending;
    peachLog(
      'Reconcile $logLabel=$depositId verdict=${verdict.name} '
      'status=${seen.status ?? 'unknown'} settled=${seen.settled ?? false}',
    );
    return PeachDepositCheck(verdict, payment: seen, error: lastError);
  }
}
