part of 'update_create_appointment_cubit.dart';

class UpdateCreateAppointmentState extends Equatable {
  factory UpdateCreateAppointmentState.initial() {
    return const UpdateCreateAppointmentState._(
      fetchPortfolioState: ProcessState.init(null),
      fetchAppointmentState: ProcessState.init(null),
      updateOrCreateAppointmentState: ProcessState.init(null),
      selectedDate: null,
      selectedTime: null,
      address: null,
      notes: null,
      fetchSellerDetailsState: ProcessState.init(null),
    );
  }

  const UpdateCreateAppointmentState._({
    required this.fetchPortfolioState,
    required this.fetchAppointmentState,
    required this.updateOrCreateAppointmentState,
    required this.selectedDate,
    required this.selectedTime,
    required this.address,
    required this.notes,
    required this.fetchSellerDetailsState,
  });
  final ProcessState<SellerPortfolio> fetchPortfolioState;
  final ProcessState<CustomerAppointment> fetchAppointmentState;
  final ProcessState<SellerDetails> fetchSellerDetailsState;
  final ProcessState<void> updateOrCreateAppointmentState;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String? address;
  final String? notes;

  

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
  }) {
    return UpdateCreateAppointmentState._(
      fetchPortfolioState: fetchPortfolioState ?? this.fetchPortfolioState,
      fetchAppointmentState:
          fetchAppointmentState ?? this.fetchAppointmentState,
      updateOrCreateAppointmentState:
          updateOrCreateAppointmentState ?? this.updateOrCreateAppointmentState,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      fetchSellerDetailsState:
          fetchSellerDetailsState ?? this.fetchSellerDetailsState,
    );
  }
}
