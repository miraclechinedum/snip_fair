import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/idempotency_key.dart';
import 'package:snip_fair/core/utils/preferences/withdrawal_attempt_store.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/settings.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/stylist_settings/stylist_settings.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_attempt.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_failure.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_lookup.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';

part 'earnings_state.dart';

@Injectable()
class EarningsCubit extends Cubit<EarningsState> {
  EarningsCubit(
    this._profileRepository,
    this._attemptStore, {
    @ignoreParam IdempotencyKeyGenerator? newIdempotencyKey,
  })  : _newIdempotencyKey = newIdempotencyKey ?? generateUuidV4,
        super(const EarningsState.initial());

  final ProfileRepository _profileRepository;
  final WithdrawalAttemptStore _attemptStore;
  final IdempotencyKeyGenerator _newIdempotencyKey;

  /// Requests (a withdrawal in particular) can finish after the screen has
  /// closed; their result is already saved, so a late state is dropped.
  @override
  void emit(EarningsState state) {
    if (!isClosed) super.emit(state);
  }

  Future<void> getEarnings() async {
    emit(state.copyWith(earnings: const ProcessState.loading()));
    final response = await _profileRepository.getEarnings();
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            earnings: ProcessState.success(data),
            settings: data.settings,
            // `/stylist/earnings` carries the holding-pouch (escrow) rows
            // that `/wallet/transactions` omits. Fold them in so the
            // Transactions tab shows escrow entries the moment a booking is
            // approved. Its other rows duplicate the wallet's own (richer)
            // rows, and earlier escrow rows are replaced, not accumulated.
            transactionsState: ProcessState.success(
              _mergeTransactions(
                state.transactionsState.data?.where((t) => !t.isEscrow),
                _escrowRows(data.transactions),
              ),
            ),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(earnings: ProcessState.error(error)));
      },
    );
  }

  /// Unions two transaction collections, de-duplicating on `id` and keeping
  /// the newest row for any repeated id. Sorted newest-first.
  ///
  /// Pure display-layer plumbing — no amounts are computed or synthesised;
  /// every row is exactly what the server sent.
  static List<UserTransaction> _mergeTransactions(
    Iterable<UserTransaction>? existing,
    Iterable<UserTransaction>? incoming,
  ) {
    final byId = <int, UserTransaction>{};
    final unidentified = <UserTransaction>[];

    for (final t in [...?existing, ...?incoming]) {
      final id = t.id;
      if (id == null) {
        unidentified.add(t);
      } else {
        byId[id] = t;
      }
    }

    final merged = [...byId.values, ...unidentified]..sort((a, b) {
        final left = a.createdAt;
        final right = b.createdAt;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });
    return merged;
  }

  static Iterable<UserTransaction>? _escrowRows(
    List<UserTransaction>? earningsRows,
  ) =>
      earningsRows?.where((t) => t.isEscrow);

  void onAutomaticPayoutChanged(bool value) {
    if (!value) return;

    emit(
      state.copyWith(
        settings: state.settings
            ?.copyWith(automaticPayout: value, instantPayout: !value),
      ),
    );
  }

  void onManualPayoutChanged(bool value) {
    if (!value) return;
    emit(
      state.copyWith(
        settings: state.settings
            ?.copyWith(automaticPayout: !value, instantPayout: value),
      ),
    );
  }

  void onPayoutFrequencyChanged(String value) {
    emit(
      state.copyWith(
        settings: state.settings?.copyWith(payoutFrequency: value),
      ),
    );
  }

  void onPayoutDayChanged(String value) {
    emit(
      state.copyWith(
        settings: state.settings?.copyWith(payoutDay: value),
      ),
    );
  }

  Future<void> getPaymentMethods() async {
    emit(state.copyWith(paymentMethods: const ProcessState.loading()));
    final response = await _profileRepository.getPaymentMethods();
    response.when(
      success: (data) {
        emit(state.copyWith(paymentMethods: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(paymentMethods: ProcessState.error(error)));
      },
    );
  }

  Future<void> updatePayoutSettings() async {
    emit(
      state.copyWith(updatePayoutSettingState: const ProcessState.loading()),
    );
    final response = await _profileRepository.updateStylistSettings(
      StylistSettings(
        automaticPayout: state.settings?.automaticPayout,
        instantPayout: state.settings?.instantPayout,
        payoutDay: state.settings?.payoutDay,
        payoutFrequency: state.settings?.payoutFrequency,
        enableMobileAppointments: state.settings?.enableMobileAppointments,
        enableShopAppointments: state.settings?.enableShopAppointments,
      ),
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updatePayoutSettingState: const ProcessState.success(true),
          ),
        );
        getEarnings();
      },
      failure: (error) {
        emit(
          state.copyWith(
            updatePayoutSettingState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  /// Loads the attempt saved by an earlier screen or app run (original key,
  /// amount and payout method) and, if unresolved, looks it up. A request
  /// that was being sent when the app stopped is treated as unknown.
  Future<void> restorePendingWithdrawal() async {
    _syncFromStore();
    if (state.pendingWithdrawalUnreadable) {
      // Show the server's view; it cannot resolve the attempt, though.
      unawaited(fetchTransactions(isInitial: true));
      return;
    }
    final attempt = state.pendingWithdrawal;
    if (attempt == null) return;
    if (attempt.status == WithdrawalAttemptStatus.sending) {
      final unknown = attempt.withStatus(WithdrawalAttemptStatus.unknown);
      await _attemptStore.save(unknown);
      emit(state.copyWith(pendingWithdrawal: unknown));
    }
    await checkPendingWithdrawal();
  }

  /// Asks the backend what became of the unresolved attempt, by its stored
  /// idempotency key (never a new one). Read-only: it never sends a
  /// withdrawal.
  /// - found → the attempt is resolved; its status is shown;
  /// - 404 → nothing recorded *yet*: the stylist may resend the original
  ///   request (same key and payload) — never start a fresh one;
  /// - 503 busy, 401/403, network or 5xx → the attempt stays, blocked.
  Future<void> checkPendingWithdrawal() async {
    if (state.requestPayoutState.isLoading ||
        state.withdrawalRecovery == WithdrawalRecoveryStatus.checking) {
      return;
    }
    _syncFromStore();
    final attempt = state.pendingWithdrawal;
    if (attempt == null || !attempt.isUnresolved) return;
    if (attempt.status == WithdrawalAttemptStatus.conflict) {
      return resolveWithdrawalConflict();
    }

    final lookup = await _lookUp(attempt);
    switch (lookup) {
      case null:
        return;
      case WithdrawalLookupFound(:final withdrawal):
        await _resolveFound(attempt, withdrawal);
      case WithdrawalLookupNotFound():
        emit(
          state.copyWith(withdrawalRecovery: WithdrawalRecoveryStatus.notFound),
        );
    }
  }

  /// Runs the lookup for [attempt]; null when it failed (the recovery
  /// status then says why) or the attempt changed meanwhile.
  Future<WithdrawalLookup?> _lookUp(WithdrawalAttempt attempt) async {
    emit(
      state.copyWith(
        withdrawalRecovery: WithdrawalRecoveryStatus.checking,
        clearRecoveredWithdrawal: true,
      ),
    );
    final result =
        await _profileRepository.lookupWithdrawal(attempt.idempotencyKey);
    // Resolved, replaced or being resent meanwhile: that outcome wins.
    if (state.pendingWithdrawal?.idempotencyKey != attempt.idempotencyKey ||
        state.requestPayoutState.isLoading) {
      emit(state.copyWith(withdrawalRecovery: WithdrawalRecoveryStatus.idle));
      return null;
    }
    return result.when(
      success: (lookup) => lookup,
      failure: (error) {
        emit(state.copyWith(withdrawalRecovery: _recoveryFailure(error)));
        return null;
      },
    );
  }

  static WithdrawalRecoveryStatus _recoveryFailure(RemoteException error) {
    if (error.code == 'WITHDRAWAL_LOOKUP_BUSY' || error.statusCode == 503) {
      return WithdrawalRecoveryStatus.busy;
    }
    if (error.statusCode == 403) return WithdrawalRecoveryStatus.forbidden;
    return WithdrawalRecoveryStatus.unavailable;
  }

  /// A withdrawal is recorded under the attempt's key: exactly one exists,
  /// whatever its status, so the attempt is resolved.
  Future<void> _resolveFound(
    WithdrawalAttempt attempt,
    WithdrawalRecord withdrawal,
  ) async {
    await _attemptStore.clear(idempotencyKey: attempt.idempotencyKey);
    emit(
      state.copyWith(
        clearPendingWithdrawal: true,
        withdrawalRecovery: WithdrawalRecoveryStatus.idle,
        recoveredWithdrawal: withdrawal,
      ),
    );
    unawaited(_refreshAfterWithdrawal());
  }

  /// The device's saved attempt is the source of truth: another earnings
  /// screen (another cubit) may have saved one since this cubit loaded.
  /// Synchronous, so the check and the following save cannot interleave
  /// with another cubit. An empty read never drops an attempt held here.
  void _syncFromStore() {
    switch (_attemptStore.load()) {
      case NoStoredWithdrawalAttempt():
        return;
      case UnreadableWithdrawalAttempt():
        if (!state.pendingWithdrawalUnreadable) {
          emit(state.copyWith(pendingWithdrawalUnreadable: true));
        }
      case FoundWithdrawalAttempt(:final attempt):
        if (state.pendingWithdrawal != attempt ||
            state.pendingWithdrawalUnreadable) {
          emit(
            state.copyWith(
              pendingWithdrawal: attempt,
              pendingWithdrawalUnreadable: false,
            ),
          );
        }
    }
  }

  /// Sends a withdrawal and reports whether the backend accepted it.
  ///
  /// The same amount and method as [EarningsState.pendingWithdrawal] reuse
  /// its idempotency key. Different details start a new withdrawal with a
  /// new key — refused while the pending attempt is unresolved (it may have
  /// been accepted) or a saved attempt is unreadable. Ignored (returns
  /// false) while a withdrawal is already being sent.
  Future<bool> requestPayout(PaymentMethod paymentMethod, double amount) {
    // Synchronous guard: checked here and set by [_send] before any await.
    if (state.requestPayoutState.isLoading) return Future.value(false);

    _syncFromStore();
    if (state.pendingWithdrawalUnreadable) {
      return _block(WithdrawalBlockReason.unreadableAttempt);
    }
    final paymentMethodId = paymentMethod.id.toString();
    final pending = state.pendingWithdrawal;
    if (pending?.status == WithdrawalAttemptStatus.conflict) {
      // Its key is on record for other details: resending cannot help.
      unawaited(resolveWithdrawalConflict());
      return _block(WithdrawalBlockReason.unresolvedAttempt);
    }
    if (pending != null && pending.matches(paymentMethodId, amount)) {
      return _send(pending);
    }
    if (pending != null && pending.isUnresolved) {
      return _block(WithdrawalBlockReason.unresolvedAttempt);
    }
    return _send(
      WithdrawalAttempt(
        idempotencyKey: _newIdempotencyKey(),
        paymentMethodId: paymentMethodId,
        amount: amount,
      ),
    );
  }

  /// Resends the pending attempt: same key, amount and method. This is the
  /// only way an unknown outcome is resolved: a 204 (new or replayed) proves
  /// exactly one withdrawal exists for the key. There is deliberately no
  /// "discard": transaction history cannot prove a request was not accepted.
  Future<bool> retryPendingWithdrawal() {
    if (state.requestPayoutState.isLoading) return Future.value(false);
    _syncFromStore();
    final pending = state.pendingWithdrawal;
    if (state.pendingWithdrawalUnreadable || pending == null) {
      return Future.value(false);
    }
    if (pending.status == WithdrawalAttemptStatus.conflict) {
      return resolveWithdrawalConflict().then((_) => false);
    }
    return _send(pending);
  }

  /// After a 409: looks the key up to show what it is recorded as; failing
  /// that, reloads the balance and history, then drops the attempt. If the
  /// reload fails too the attempt stays, so this runs again later.
  Future<void> resolveWithdrawalConflict() async {
    final conflict = state.pendingWithdrawal;
    if (conflict?.status != WithdrawalAttemptStatus.conflict ||
        state.withdrawalRecovery == WithdrawalRecoveryStatus.checking) {
      return;
    }
    final lookup = await _lookUp(conflict!);
    if (lookup is WithdrawalLookupFound) {
      return _resolveFound(conflict, lookup.withdrawal);
    }
    if (state.withdrawalRecovery == WithdrawalRecoveryStatus.checking) {
      // 404 contradicts the 409; the 409 still proves the key is on record.
      emit(state.copyWith(withdrawalRecovery: WithdrawalRecoveryStatus.idle));
    }
    final refreshed = await _refreshAfterWithdrawal();
    if (!refreshed || state.pendingWithdrawal != conflict) return;
    // A 409 proves a withdrawal exists under this key (with other details):
    // the outcome is known, not uncertain. Only the reload was outstanding.
    await _attemptStore.clear(idempotencyKey: conflict.idempotencyKey);
    emit(
      state.copyWith(
        clearPendingWithdrawal: true,
        withdrawalRecovery: WithdrawalRecoveryStatus.idle,
      ),
    );
  }

  Future<bool> _block(WithdrawalBlockReason reason) {
    emit(
      state.copyWith(
        requestPayoutState: ProcessState.error(
          WithdrawalBlockedException(reason),
        ),
      ),
    );
    return Future.value(false);
  }

  Future<bool> _send(WithdrawalAttempt attempt) async {
    final previous = state.pendingWithdrawal;
    final wasUncertain = attempt.outcomeUnknown &&
        previous?.idempotencyKey == attempt.idempotencyKey;
    final sending = attempt.withStatus(WithdrawalAttemptStatus.sending);
    emit(
      state.copyWith(
        requestPayoutState: const ProcessState.loading(),
        pendingWithdrawal: sending,
        withdrawalRecovery: WithdrawalRecoveryStatus.idle,
        clearRecoveredWithdrawal: true,
      ),
    );

    // Saved before sending, so a restart mid-request still knows the key.
    if (!await _attemptStore.save(sending)) {
      emit(
        state.copyWith(
          requestPayoutState: const ProcessState.error(
            WithdrawalBlockedException(
              WithdrawalBlockReason.storageUnavailable,
            ),
          ),
          pendingWithdrawal: previous,
          clearPendingWithdrawal: previous == null,
        ),
      );
      return false;
    }

    final response = await _profileRepository.requestPayout(
      sending.paymentMethodId,
      sending.amount,
      idempotencyKey: sending.idempotencyKey,
    );
    return response.when(
      success: (data) async {
        // Accepted (or replayed): the attempt is resolved. Should the clear
        // fail, a later retry is answered as a replay — still safe.
        await _attemptStore.clear(idempotencyKey: sending.idempotencyKey);
        emit(
          state.copyWith(
            requestPayoutState: ProcessState.success(data),
            clearPendingWithdrawal: true,
          ),
        );
        unawaited(_refreshAfterWithdrawal());
        return true;
      },
      failure: (error) async {
        final kind = classifyWithdrawalFailure(error);
        if (kind == WithdrawalFailureKind.keyRejected && !wasUncertain) {
          // The key itself was refused on a first send, so nothing was ever
          // recorded under it.
          await _attemptStore.clear(idempotencyKey: sending.idempotencyKey);
          emit(
            state.copyWith(
              requestPayoutState: ProcessState.error(error),
              clearPendingWithdrawal: true,
            ),
          );
          return false;
        }

        final next = sending.withStatus(
          switch (kind) {
            WithdrawalFailureKind.conflict => WithdrawalAttemptStatus.conflict,
            // A refusal of a retry happens before Laravel's replay check
            // (middleware, kill switch, validation) or proves nothing about
            // the earlier send: it stays unknown.
            _ when kind.isUncertain || wasUncertain =>
              WithdrawalAttemptStatus.unknown,
            _ => WithdrawalAttemptStatus.rejected,
          },
        );
        await _attemptStore.save(next);
        emit(
          state.copyWith(
            requestPayoutState: ProcessState.error(error),
            pendingWithdrawal: next,
          ),
        );
        if (next.status == WithdrawalAttemptStatus.conflict) {
          await resolveWithdrawalConflict();
        } else if (kind.isUncertain) {
          // The request may have been recorded: show the server's view.
          unawaited(_refreshAfterWithdrawal());
        }
        return false;
      },
    );
  }

  /// Reloads the balance (from `/stylist/earnings`) and the transaction
  /// history from its first page; true when both loaded.
  Future<bool> _refreshAfterWithdrawal() async {
    await Future.wait([getEarnings(), fetchTransactions(isInitial: true)]);
    return state.earnings.hasSuccess && state.transactionsState.hasSuccess;
  }

  /// Bumped by every full refresh, so a load-more page requested before it
  /// is not appended to the refreshed list.
  int _transactionsGeneration = 0;

  Future<void> fetchTransactions({bool isInitial = false}) async {
    if (!isInitial &&
        (state.transactionsState.isLoading ||
            state.transactionsPaginationData.isLoadingMore ||
            state.transactionsPaginationData.hasReachedMax)) {
      return;
    }
    final generation = isInitial
        ? ++_transactionsGeneration
        : _transactionsGeneration;

    if (isInitial) {
      emit(
        state.copyWith(
          transactionsState: const ProcessState.loading(),
          transactionsPaginationData: const PaginationData(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          transactionsPaginationData: PaginationData(
            isLoadingMore: true,
            nextPageCursor: state.transactionsPaginationData.nextPageCursor,
            prevPageCursor: state.transactionsPaginationData.prevPageCursor,
          ),
        ),
      );
    }

    final result = await _profileRepository.getWalletTransactions(
      page: state.transactionsPaginationData.nextPageCursor,
      perPage: 20,
    );
    if (generation != _transactionsGeneration) return;

    result.when(
      success: (data) {
        final transactions = data.data ?? [];
        // On a full refresh, re-seed from the earnings ledger so the
        // holding-pouch rows survive a pull-to-refresh; on load-more, just
        // append the next wallet page.
        final updatedList = isInitial
            ? _mergeTransactions(
                _escrowRows(state.earnings.data?.transactions),
                transactions,
              )
            : _mergeTransactions(
                state.transactionsState.data,
                transactions,
              );

        final updatedPaginationData = PaginationData(
          nextPageCursor: data.nextCursor,
          prevPageCursor: data.prevCursor,
          hasReachedMax: data.nextCursor == null,
        );

        emit(
          state.copyWith(
            transactionsState: ProcessState.success(updatedList),
            transactionsPaginationData: updatedPaginationData,
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            transactionsState:
                ProcessState.error(error, state.transactionsState.data),
            // Keep the cursor so the same page can be asked for again.
            transactionsPaginationData: PaginationData(
              nextPageCursor: state.transactionsPaginationData.nextPageCursor,
              prevPageCursor: state.transactionsPaginationData.prevPageCursor,
              hasReachedMax: state.transactionsPaginationData.hasReachedMax,
            ),
          ),
        );
      },
    );
  }
}
