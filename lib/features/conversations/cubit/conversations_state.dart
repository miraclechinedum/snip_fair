part of 'conversations_cubit.dart';

class ConversationsState extends Equatable {
  factory ConversationsState.initial() {
    return const ConversationsState._(
      conversationsState: ProcessState.init(null),
      chatMessagesState: ProcessState.init(null),
      chatPaginationData: PaginationData(),
      createPaymentRequestState: ProcessState.init(null),
    );
  }

  const ConversationsState._({
    required this.conversationsState,
    required this.chatMessagesState,
    required this.chatPaginationData,
    required this.createPaymentRequestState,
    this.lastUpdatedPaymentRequestId,
    this.paymentRequestUpdateSeq = 0,
    this.unreadConversationsCount,
    this.paymentProgress = const {},
  });

  final ProcessState<List<ChatConversation>> conversationsState;
  final ProcessState<List<ChatMessage>> chatMessagesState;
  final PaginationData chatPaginationData;
  final ProcessState<PaymentRequest> createPaymentRequestState;

  /// Ticks up when a `payment_request` push handler refreshes the cache for
  /// a specific id. `PaymentRequestCard` observes this to know when to re-read
  /// its data from the cubit's in-memory cache.
  final int? lastUpdatedPaymentRequestId;

  /// Increments on every payment request refresh, so two consecutive updates
  /// for the same [lastUpdatedPaymentRequestId] still notify listeners.
  final int paymentRequestUpdateSeq;

  /// Customer-side payment progress, keyed by payment request id. Lives in
  /// state (not in the card) so a rebuilt chat bubble shows the same phase.
  final Map<int, PaymentRequestPaymentProgress> paymentProgress;

  /// Total unread messages across all conversations, populated by the
  /// 4-second polling loop against `GET /conversations/unread-count`.
  /// Preferred over the client-derived sum from `conversationsState` — the
  /// count endpoint is cheap and always current.
  final int? unreadConversationsCount;

  @override
  List<Object?> get props => [
        conversationsState,
        chatMessagesState,
        chatPaginationData,
        createPaymentRequestState,
        lastUpdatedPaymentRequestId,
        paymentRequestUpdateSeq,
        unreadConversationsCount,
        paymentProgress,
      ];

  ConversationsState copyWith({
    ProcessState<List<ChatConversation>>? conversationsState,
    ProcessState<List<ChatMessage>>? chatMessagesState,
    PaginationData? chatPaginationData,
    ProcessState<PaymentRequest>? createPaymentRequestState,
    int? lastUpdatedPaymentRequestId,
    int? paymentRequestUpdateSeq,
    int? unreadConversationsCount,
    Map<int, PaymentRequestPaymentProgress>? paymentProgress,
  }) {
    return ConversationsState._(
      conversationsState: conversationsState ?? this.conversationsState,
      chatMessagesState: chatMessagesState ?? this.chatMessagesState,
      chatPaginationData: chatPaginationData ?? this.chatPaginationData,
      createPaymentRequestState:
          createPaymentRequestState ?? this.createPaymentRequestState,
      lastUpdatedPaymentRequestId:
          lastUpdatedPaymentRequestId ?? this.lastUpdatedPaymentRequestId,
      paymentRequestUpdateSeq:
          paymentRequestUpdateSeq ?? this.paymentRequestUpdateSeq,
      unreadConversationsCount:
          unreadConversationsCount ?? this.unreadConversationsCount,
      paymentProgress: paymentProgress ?? this.paymentProgress,
    );
  }
}

/// Where a customer's payment of one payment request currently stands.
///
/// Card payments are either
/// - native (Phase 6B.2.5A): `POST /payment-requests/{id}/pay` with
///   `payment_method: card`, verified only by the payer-only status endpoint
///   (`paid: true` is the only success) — tracked by
///   [PaymentRequestPaymentProgress.cardPaymentId]; or
/// - a wallet top-up (`POST /payment/topup`, verified with the Peach deposit
///   status endpoint) followed by a wallet `/pay` — tracked by
///   [PaymentRequestPaymentProgress.depositId]. Used only when the customer
///   chooses it, e.g. while native card payment is unavailable.
///
/// The checkout, verifying, pending and unknown phases cover both kinds.
enum PaymentRequestPaymentPhase {
  idle,
  initializingTopUp,

  /// `POST /pay` with `payment_method: card` is in flight.
  initializingCardCheckout,
  checkoutOpen,
  verifyingTopUp,

  /// The status endpoint says the card payment is still pending.
  topUpPending,

  /// The status endpoint could not give a verdict (503 / network).
  topUpUnknown,

  /// Laravel answered `payment_method_unavailable`: native card payment is
  /// switched off. Nothing was charged. The customer may pay from the wallet,
  /// or choose to add the amount to the wallet by card first.
  cardUnavailable,
  payingFromWallet,

  /// The card top-up is verified (money is in the wallet) but `/pay` has not
  /// succeeded. Only a wallet retry is offered — never a second card charge.
  topUpSucceededPaymentPending,

  /// `/pay` answered `insufficient_wallet_balance`: the wallet is short by
  /// [PaymentRequestPaymentProgress.shortfall]. The customer may add exactly
  /// that by card, or retry once the wallet holds enough. Nothing is charged
  /// automatically.
  awaitingWalletFunds,
  successful,
  failed,
  cancelled;

  /// A request to the backend or the hosted checkout is in progress.
  bool get isBusy =>
      this == initializingTopUp ||
      this == initializingCardCheckout ||
      this == checkoutOpen ||
      this == verifyingTopUp ||
      this == payingFromWallet;

  /// A card checkout whose outcome is not known; it must be checked again
  /// before any new checkout may start.
  bool get isUnresolvedTopUp => this == topUpPending || this == topUpUnknown;
}

class PaymentRequestPaymentProgress extends Equatable {
  const PaymentRequestPaymentProgress({
    this.phase = PaymentRequestPaymentPhase.idle,
    this.depositId,
    this.cardPaymentId,
    this.message,
    this.revision = 0,
    this.shortfall,
    this.walletBalance,
    this.requiredAmount,
  });

  final PaymentRequestPaymentPhase phase;

  /// The card top-up deposit of the current attempt: kept while it is
  /// unverified and until `/pay` succeeds after it, so the card is never
  /// charged again for this attempt (and a restart can resume it).
  final String? depositId;

  /// The native card attempt (`payment_id`) of the current attempt: kept
  /// while its outcome is unknown, so it is checked — never paid again.
  final String? cardPaymentId;

  /// Customer-facing explanation of the latest transition, if any.
  final String? message;

  /// Increments on every transition, so a repeated outcome (e.g. two failed
  /// attempts in a row) still notifies listeners.
  final int revision;

  /// From `insufficient_wallet_balance`: what the wallet still needs, its
  /// balance and the amount required — the backend's figures, not local
  /// arithmetic.
  final num? shortfall;
  final num? walletBalance;
  final num? requiredAmount;

  @override
  List<Object?> get props => [
        phase,
        depositId,
        cardPaymentId,
        message,
        revision,
        shortfall,
        walletBalance,
        requiredAmount,
      ];
}
