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

  CheckoutPaymentData? get activeCardCheckout => cardCheckoutState.data;
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
        cardVerificationState
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
  }) =>
      UpdateCreateAppointmentState._(
        fetchPortfolioState: fetchPortfolioState ?? this.fetchPortfolioState,
        fetchAppointmentState:
            fetchAppointmentState ?? this.fetchAppointmentState,
        updateOrCreateAppointmentState: updateOrCreateAppointmentState ??
            this.updateOrCreateAppointmentState,
        selectedDate: selectedDate ?? this.selectedDate,
        selectedTime: selectedTime ?? this.selectedTime,
        address: address ?? this.address,
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
      );
}
