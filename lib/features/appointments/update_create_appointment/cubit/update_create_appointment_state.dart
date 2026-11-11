part of 'update_create_appointment_cubit.dart';

enum CardPaymentPhase {
  idle,
  initializing,
  checkoutOpen,
  verifying,
  successful,
  pending,
  failed,
  cancelled,
  unknown;

  bool get isTerminal =>
      this == successful || this == failed || this == cancelled;
}

/// Where tipping the stylist stands (`POST .../tip`, and for a card tip the
/// deposit status endpoint's `tip.status`).
enum TipPaymentPhase {
  idle,

  /// `POST .../tip` is in flight (wallet or card).
  submitting,

  /// The card tip's hosted checkout is open.
  checkoutOpen,

  /// Asking Laravel what became of the card tip.
  verifying,

  /// `tip.status: tipped` (card) or `code: tipped` (wallet): the stylist
  /// received the tip.
  tipped,

  /// `tip.status: pending`: Peach has not confirmed the card payment yet.
  pending,

  /// `tip.status: credited_to_wallet`: the card was charged, but the money
  /// went to the customer's wallet — the booking could no longer be tipped.
  creditedToWallet,

  /// `tip.status: not_paid`: the card payment was cancelled or abandoned; no
  /// tip was sent. A new attempt may be made.
  notPaid,

  /// No verdict (HTTP 503, network): the card tip must be checked again
  /// before another attempt.
  unknown,

  /// The tip was refused or could not be started (nothing was paid).
  failed;

  bool get isBusy =>
      this == submitting || this == checkoutOpen || this == verifying;

  /// A card tip whose outcome is not known: checked, never paid again.
  bool get isUnresolved => this == pending || this == unknown;
}

class TipPaymentProgress extends Equatable {
  const TipPaymentProgress({
    this.phase = TipPaymentPhase.idle,
    this.checkout,
    this.amount,
    this.paymentMethod,
    this.message,
    this.revision = 0,
    this.announced = false,
  });

  final TipPaymentPhase phase;

  /// The card tip's checkout (its `deposit_id` is what gets verified). Kept
  /// while the outcome is unresolved.
  final CheckoutPaymentData? checkout;
  final double? amount;
  final String? paymentMethod;

  /// Laravel's (or a safe fallback) customer-facing explanation.
  final String? message;

  /// Increments on every transition, so repeated outcomes still notify.
  final int revision;

  /// The outcome was already shown to the customer elsewhere (app-level
  /// recovery), so the booking screen does not announce it again.
  final bool announced;

  @override
  List<Object?> get props => [
        phase,
        checkout?.depositId,
        amount,
        paymentMethod,
        message,
        revision,
        announced,
      ];
}

class UpdateCreateAppointmentState extends Equatable {
  factory UpdateCreateAppointmentState.initial() =>
      const UpdateCreateAppointmentState._(
        fetchPortfolioState: ProcessState.init(null),
        fetchAppointmentState: ProcessState.init(null),
        updateOrCreateAppointmentState: ProcessState.init(null),
        selectedDate: null,
        selectedTime: null,
        address: null,
        notes: null,
        fetchSellerDetailsState: ProcessState.init(null),
        cancelBookingState: ProcessState.init(null),
        rescheduleBookingState: ProcessState.init(null),
        tipAppointmentState: ProcessState.init(null),
        paymentMethod: 'wallet',
        cardPaymentPhase: CardPaymentPhase.idle,
        cardCheckoutState: ProcessState.init(null),
        cardVerificationState: ProcessState.init(null),
        retryAppointmentId: null,
        addressPlace: null,
        tipPayment: TipPaymentProgress(),
      );

  const UpdateCreateAppointmentState._({
    required this.fetchPortfolioState,
    required this.fetchAppointmentState,
    required this.updateOrCreateAppointmentState,
    required this.selectedDate,
    required this.selectedTime,
    required this.address,
    required this.notes,
    required this.fetchSellerDetailsState,
    required this.cancelBookingState,
    required this.rescheduleBookingState,
    required this.tipAppointmentState,
    required this.paymentMethod,
    required this.cardPaymentPhase,
    required this.cardCheckoutState,
    required this.cardVerificationState,
    required this.retryAppointmentId,
    required this.addressPlace,
    required this.tipPayment,
  });

  final ProcessState<SellerPortfolio> fetchPortfolioState;
  final ProcessState<CustomerAppointment> fetchAppointmentState;
  final ProcessState<SellerDetails> fetchSellerDetailsState;
  final ProcessState<void> updateOrCreateAppointmentState;
  final ProcessState<void> cancelBookingState;
  final ProcessState<void> rescheduleBookingState;
  final ProcessState<TipResponse> tipAppointmentState;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String? address;
  final String? notes;
  final String paymentMethod;
  final CardPaymentPhase cardPaymentPhase;
  final ProcessState<CheckoutPaymentData> cardCheckoutState;
  final ProcessState<PaymentReconciliation> cardVerificationState;

  /// The unpaid booking whose card payment Peach confirmed cancelled or
  /// failed, and that may be paid again. Booking by card then retries THIS
  /// booking (`POST .../payment/card`) instead of creating another one.
  final String? retryAppointmentId;

  /// The address suggestion the customer picked, with its coordinates; null
  /// when the address was typed by hand (or none was picked).
  final GeoPlace? addressPlace;

  /// Tipping the stylist on this booking.
  final TipPaymentProgress tipPayment;

  CheckoutPaymentData? get activeCardCheckout => cardCheckoutState.data;
  /// A card checkout whose outcome is not known yet. A new card checkout
  /// must not start until it is checked, or the customer could be charged
  /// twice.
  bool get hasUnresolvedCardPayment =>
      activeCardCheckout?.depositId != null &&
      (cardPaymentPhase == CardPaymentPhase.pending ||
          cardPaymentPhase == CardPaymentPhase.unknown);

  bool get isCardPaymentBusy =>
      cardPaymentPhase == CardPaymentPhase.initializing ||
      cardPaymentPhase == CardPaymentPhase.checkoutOpen ||
      cardPaymentPhase == CardPaymentPhase.verifying;
  bool get canBookAppointment =>
      selectedDate != null &&
      selectedTime != null &&
      fetchPortfolioState.data?.userId != null;
  String get appointmentStatus => fetchAppointmentState.data?.status ?? '';

  @override
  List<Object?> get props => [
        fetchPortfolioState,
        fetchAppointmentState,
        updateOrCreateAppointmentState,
        selectedDate,
        selectedTime,
        address,
        notes,
        fetchSellerDetailsState,
        cancelBookingState,
        rescheduleBookingState,
        tipAppointmentState,
        paymentMethod,
        cardPaymentPhase,
        cardCheckoutState,
        cardVerificationState,
        retryAppointmentId,
        addressPlace,
        tipPayment,
      ];

  UpdateCreateAppointmentState copyWith({
    ProcessState<SellerPortfolio>? fetchPortfolioState,
    ProcessState<CustomerAppointment>? fetchAppointmentState,
    ProcessState<void>? updateOrCreateAppointmentState,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    String? address,
    String? notes,
    ProcessState<SellerDetails>? fetchSellerDetailsState,
    ProcessState<void>? cancelBookingState,
    ProcessState<void>? rescheduleBookingState,
    ProcessState<TipResponse>? tipAppointmentState,
    String? paymentMethod,
    CardPaymentPhase? cardPaymentPhase,
    ProcessState<CheckoutPaymentData>? cardCheckoutState,
    ProcessState<PaymentReconciliation>? cardVerificationState,
    String? retryAppointmentId,
    bool clearRetryAppointmentId = false,
    GeoPlace? addressPlace,
    bool clearAddress = false,
    TipPaymentProgress? tipPayment,
  }) =>
      UpdateCreateAppointmentState._(
        fetchPortfolioState: fetchPortfolioState ?? this.fetchPortfolioState,
        fetchAppointmentState:
            fetchAppointmentState ?? this.fetchAppointmentState,
        updateOrCreateAppointmentState: updateOrCreateAppointmentState ??
            this.updateOrCreateAppointmentState,
        selectedDate: selectedDate ?? this.selectedDate,
        selectedTime: selectedTime ?? this.selectedTime,
        address: clearAddress ? null : address ?? this.address,
        notes: notes ?? this.notes,
        fetchSellerDetailsState:
            fetchSellerDetailsState ?? this.fetchSellerDetailsState,
        cancelBookingState: cancelBookingState ?? this.cancelBookingState,
        rescheduleBookingState:
            rescheduleBookingState ?? this.rescheduleBookingState,
        tipAppointmentState: tipAppointmentState ?? this.tipAppointmentState,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        cardPaymentPhase: cardPaymentPhase ?? this.cardPaymentPhase,
        cardCheckoutState: cardCheckoutState ?? this.cardCheckoutState,
        cardVerificationState:
            cardVerificationState ?? this.cardVerificationState,
        retryAppointmentId: clearRetryAppointmentId
            ? null
            : retryAppointmentId ?? this.retryAppointmentId,
        addressPlace: clearAddress || (address != null && addressPlace == null)
            ? null
            : addressPlace ?? this.addressPlace,
        tipPayment: tipPayment ?? this.tipPayment,
      );
}
