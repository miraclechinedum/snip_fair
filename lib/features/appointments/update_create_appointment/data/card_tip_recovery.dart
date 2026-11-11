import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/services/peach_deposit_reconciler.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/data/card_tip_attempt_store.dart';

/// What one check of a card tip established, from Laravel's `tip.status`.
enum CardTipVerdict {
  /// `tipped`: the stylist received the tip.
  tipped,

  /// `credited_to_wallet`: card paid, booking already tipped — the money is
  /// in the customer's wallet; the stylist did not receive this tip.
  creditedToWallet,

  /// `not_paid`: cancelled or abandoned; no tip. A new attempt may start.
  notPaid,

  /// `pending`, no tip block, or a status this app does not know: not
  /// decided — fail closed, keep checking.
  pending,

  /// No verdict (503, network, timeout, 401): keep the attempt.
  unknown,

  /// 404 / 422: not a verifiable card payment of this customer. Dropped.
  unverifiable;

  /// The attempt is finished; it leaves the unresolved queue.
  bool get isTerminal =>
      this == tipped ||
      this == creditedToWallet ||
      this == notPaid ||
      this == unverifiable;
}

class CardTipCheck {
  const CardTipCheck({
    required this.appointmentId,
    required this.verdict,
    this.amount,
    this.message,
    this.source,
  });

  final String appointmentId;
  final CardTipVerdict verdict;
  final double? amount;

  /// Laravel's explanation, when it gave one.
  final String? message;

  /// Who asked for the check (a booking screen's token); null for app-level
  /// recovery (start-up / resume), whose outcomes are announced app-wide.
  final Object? source;
}

/// Keeps the signed-in customer's unresolved card tips, across app restarts,
/// and checks them with Laravel
/// (`GET /customer/payment/peach/{deposit}/status`) — the counterpart of
/// `ConversationsCubit`'s payment request card attempts.
///
/// - An attempt is saved as soon as Laravel hands out its checkout, before
///   the checkout opens, and only removed once its outcome is final.
/// - Only `tip.status` decides. Closing checkout, a redirect or the deposit
///   status alone never do.
/// - One status request per deposit at a time; concurrent callers share it.
/// - Recovery is bounded: one check per attempt at start-up and on resume
///   (no background loop), and attempts older than [maxAge] are dropped.
@LazySingleton()
class CardTipRecovery {
  CardTipRecovery(
    this._repository, {
    @ignoreParam CardTipAttemptStore? store,
  }) : _store = store ?? const LocalCardTipAttemptStore();

  final AppointmentRepository _repository;
  final CardTipAttemptStore _store;

  /// Card tips settle within minutes; a week-old attempt is long decided.
  @visibleForTesting
  static Duration maxAge = const Duration(days: 7);

  /// When attempts are recorded and aged; replaceable in tests.
  static DateTime Function() clock = DateTime.now;

  String? _ownerId;
  Map<String, CardTipAttempt> _attempts = {};
  final Map<String, Future<CardTipCheck>> _checks = {};
  /// Synchronous, so every listener has seen an outcome before the check
  /// that produced it completes. Listeners only update state.
  final _events = StreamController<CardTipCheck>.broadcast(sync: true);

  /// Every check's outcome. Booking screens follow their booking; the main
  /// screen announces app-level recovery outcomes ([CardTipCheck.source]
  /// null).
  Stream<CardTipCheck> get events => _events.stream;

  String? get ownerId => _ownerId;

  /// The unresolved card tip for [appointmentId], if any.
  CardTipAttempt? unresolvedFor(String appointmentId) =>
      _attempts[appointmentId];

  List<CardTipAttempt> get unresolved => List.unmodifiable(_attempts.values);

  /// Loads [ownerId]'s attempts (only theirs) the first time, then checks
  /// every unresolved one once. Called after sign-in and on app resume.
  Future<void> restore({required String ownerId}) async {
    if (_ownerId != ownerId) {
      _ownerId = ownerId;
      final now = clock();
      final stored = _store.load(ownerId);
      final kept = {
        for (final attempt in stored)
          if (now.difference(attempt.createdAt) <= maxAge &&
              now.difference(attempt.createdAt) >= const Duration(days: -1))
            attempt.appointmentId: attempt,
      };
      _attempts = kept;
      if (kept.length != stored.length) unawaited(_persist());
      peachLog('Restored ${kept.length} unresolved card tip(s)');
    }
    await recheckAll();
  }

  /// One check of every unresolved attempt (concurrent checks share it).
  Future<void> recheckAll() async {
    for (final appointmentId in _attempts.keys.toList()) {
      await check(appointmentId);
    }
  }

  /// Saves a card tip whose checkout Laravel just handed out — before the
  /// checkout opens, so a closed or killed app can still recover it.
  Future<void> record(CardTipAttempt attempt) async {
    _attempts = {..._attempts, attempt.appointmentId: attempt};
    await _persist();
  }

  /// Checks [appointmentId]'s unresolved card tip with Laravel. With
  /// [retryDelays] it polls a little longer (right after checkout).
  Future<CardTipCheck> check(
    String appointmentId, {
    List<Duration> retryDelays = const [],
    Object? source,
  }) {
    final attempt = _attempts[appointmentId];
    if (attempt == null) {
      return Future.value(
        CardTipCheck(
          appointmentId: appointmentId,
          verdict: CardTipVerdict.unknown,
          source: source,
        ),
      );
    }
    final inFlight = _checks[attempt.depositId];
    if (inFlight != null) return inFlight;
    // Block body: an arrow would return the removed future (this one) to
    // whenComplete, which would then wait on itself forever.
    final request =
        _runCheck(attempt, retryDelays: retryDelays, source: source)
            .whenComplete(() {
      _checks.remove(attempt.depositId);
    });
    _checks[attempt.depositId] = request;
    return request;
  }

  Future<CardTipCheck> _runCheck(
    CardTipAttempt attempt, {
    required List<Duration> retryDelays,
    required Object? source,
  }) async {
    PeachDepositCheck check;
    try {
      check = await PeachDepositReconciler(
        _repository.reconcilePeachPayment,
      ).reconcile(
        attempt.depositId,
        // Only a final `tip.status` ends polling early.
        isVerified: (payment) => payment.tip?.isFinal ?? false,
        retryDelays: retryDelays,
        logLabel: 'tip deposit',
      );
    } catch (e) {
      peachLog('Card tip check threw ${e.runtimeType}');
      check = const PeachDepositCheck(PeachDepositVerdict.unknown);
    }
    final result = _classify(attempt, check, source);
    peachLog('Card tip appointment=${attempt.appointmentId} '
        'deposit=${attempt.depositId} verdict=${result.verdict.name}');

    if (_attempts[attempt.appointmentId]?.depositId == attempt.depositId) {
      if (result.verdict.isTerminal) {
        _attempts = {..._attempts}..remove(attempt.appointmentId);
      } else {
        _attempts = {
          ..._attempts,
          attempt.appointmentId: attempt.copyWith(
            lastStatus: result.verdict == CardTipVerdict.unknown
                ? CardTipAttempt.statusUnknown
                : CardTipAttempt.statusPending,
            reference: check.payment?.transactionReference,
          ),
        };
      }
      await _persist();
    }
    if (!_events.isClosed) _events.add(result);
    return result;
  }

  static CardTipCheck _classify(
    CardTipAttempt attempt,
    PeachDepositCheck check,
    Object? source,
  ) {
    final payment = check.payment;
    final tip = payment?.tip;
    final message = payment?.message?.trim();
    CardTipCheck result(CardTipVerdict verdict) => CardTipCheck(
          appointmentId: attempt.appointmentId,
          verdict: verdict,
          amount: (tip?.amount ?? attempt.amount)?.toDouble(),
          message: message == null || message.isEmpty ? null : message,
          source: source,
        );

    if (payment != null) {
      if (tip?.isTipped ?? false) return result(CardTipVerdict.tipped);
      if (tip?.isCreditedToWallet ?? false) {
        return result(CardTipVerdict.creditedToWallet);
      }
      if (tip?.isNotPaid ?? false) return result(CardTipVerdict.notPaid);
      // `pending`, no tip block, or an unknown status: fail closed.
      return result(CardTipVerdict.pending);
    }
    final status = check.error?.statusCode;
    if (status == 404 || status == 422) {
      return result(CardTipVerdict.unverifiable);
    }
    return result(CardTipVerdict.unknown);
  }

  /// Sign-out: forget the customer in memory. Their saved attempts stay
  /// under their own key (see `LocalKeyStorage.clearData`) and are loaded
  /// again only when they sign back in.
  void onLogout() {
    _ownerId = null;
    _attempts = {};
  }

  Future<void> _persist() async {
    final owner = _ownerId;
    if (owner == null) {
      peachLog('Card tip attempt kept in memory only: no signed-in customer');
      return;
    }
    try {
      await _store.save(owner, _attempts.values.toList());
    } catch (e) {
      peachLog('Saving card tip attempts failed: ${e.runtimeType}');
    }
  }

  @visibleForTesting
  Future<void> dispose() => _events.close();
}
