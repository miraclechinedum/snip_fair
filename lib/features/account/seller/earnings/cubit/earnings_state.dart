part of 'earnings_cubit.dart';

/// Where checking an unresolved withdrawal with the lookup API stands.
enum WithdrawalRecoveryStatus {
  /// Not checked (yet) in this session.
  idle,

  /// A lookup is running.
  checking,

  /// Nothing is recorded under the key yet: resend the original request.
  notFound,

  /// 503: the backend is still writing a withdrawal; check again shortly.
  busy,

  /// The lookup failed (network, 5xx, 401, unreadable answer).
  unavailable,

  /// 403: the account may not look up withdrawals.
  forbidden,
}

class EarningsState extends Equatable {
  const EarningsState._({
    required this.earnings,
    required this.settings,
    required this.updatePayoutSettingState,
    required this.paymentMethods,
    required this.transactionsState,
    required this.transactionsPaginationData,
    required this.requestPayoutState,
    required this.pendingWithdrawal,
    required this.pendingWithdrawalUnreadable,
    required this.withdrawalRecovery,
    required this.recoveredWithdrawal,
  });

  const EarningsState.initial()
      : earnings = const ProcessState.init(null),
        paymentMethods = const ProcessState.init([]),
        updatePayoutSettingState = const ProcessState.init(null),
        transactionsState = const ProcessState.init(null),
          requestPayoutState = const ProcessState.init(null),
        transactionsPaginationData = const PaginationData(),
        settings = null,
        pendingWithdrawal = null,
        pendingWithdrawalUnreadable = false,
        withdrawalRecovery = WithdrawalRecoveryStatus.idle,
        recoveredWithdrawal = null;

  final ProcessState<StylistEarnings> earnings;
  final Settings? settings;
  final ProcessState<bool> updatePayoutSettingState;
  final ProcessState<WithdrawalSubmission> requestPayoutState;
  final ProcessState<List<PaymentMethod>> paymentMethods;
  final ProcessState<List<UserTransaction>> transactionsState;
  final PaginationData transactionsPaginationData;

  /// The withdrawal attempt being sent, or not yet accepted (see
  /// [WithdrawalAttemptStatus]). Mirrored in `WithdrawalAttemptStore`, so it
  /// survives this screen, a logout and an app restart.
  final WithdrawalAttempt? pendingWithdrawal;

  /// A saved attempt exists but could not be read. Withdrawals stay blocked
  /// until the stylist confirms they have checked their transactions.
  final bool pendingWithdrawalUnreadable;

  /// Progress of looking up [pendingWithdrawal] by its idempotency key.
  final WithdrawalRecoveryStatus withdrawalRecovery;

  /// The withdrawal a lookup found for an earlier attempt (which is then
  /// resolved), shown to the stylist once.
  final WithdrawalRecord? recoveredWithdrawal;

  EarningsState copyWith({
    ProcessState<StylistEarnings>? earnings,
    Settings? settings,
    ProcessState<bool>? updatePayoutSettingState,
    ProcessState<List<PaymentMethod>>? paymentMethods,
    ProcessState<List<UserTransaction>>? transactionsState,
    PaginationData? transactionsPaginationData,
    ProcessState<WithdrawalSubmission>? requestPayoutState,
    WithdrawalAttempt? pendingWithdrawal,
    bool clearPendingWithdrawal = false,
    bool? pendingWithdrawalUnreadable,
    WithdrawalRecoveryStatus? withdrawalRecovery,
    WithdrawalRecord? recoveredWithdrawal,
    bool clearRecoveredWithdrawal = false,
  }) {
    return EarningsState._(
      earnings: earnings ?? this.earnings,
      settings: settings ?? this.settings,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      transactionsState: transactionsState ?? this.transactionsState,
      requestPayoutState: requestPayoutState ?? this.requestPayoutState,
      transactionsPaginationData:
          transactionsPaginationData ?? this.transactionsPaginationData,
      updatePayoutSettingState:
          updatePayoutSettingState ?? this.updatePayoutSettingState,
      pendingWithdrawal: clearPendingWithdrawal
          ? null
          : pendingWithdrawal ?? this.pendingWithdrawal,
      pendingWithdrawalUnreadable:
          pendingWithdrawalUnreadable ?? this.pendingWithdrawalUnreadable,
      withdrawalRecovery: withdrawalRecovery ?? this.withdrawalRecovery,
      recoveredWithdrawal: clearRecoveredWithdrawal
          ? null
          : recoveredWithdrawal ?? this.recoveredWithdrawal,
    );
  }

  @override
  List<Object?> get props => [
        earnings,
        settings,
        updatePayoutSettingState,
        paymentMethods,
        transactionsState,
        transactionsPaginationData,
        requestPayoutState,
        pendingWithdrawal,
        pendingWithdrawalUnreadable,
        withdrawalRecovery,
        recoveredWithdrawal,
      ];
}
