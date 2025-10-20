part of 'seller_appointment_details_cubit.dart';

class SellerAppointmentDetailsState extends Equatable {
  const SellerAppointmentDetailsState._({
    required this.fetchAppointmentDetailsState,
    required this.updateAppointmentState,
  });

  const SellerAppointmentDetailsState.initial()
      : fetchAppointmentDetailsState = const ProcessState.init(null),
        updateAppointmentState = const ProcessState.init(null);

  final ProcessState<StylistAppointment> fetchAppointmentDetailsState;
  final ProcessState<bool> updateAppointmentState;

  SellerAppointmentDetailsState copyWith({
    ProcessState<StylistAppointment>? fetchAppointmentDetailsState,
    ProcessState<bool>? updateAppointmentState,
  }) {
    return SellerAppointmentDetailsState._(
      fetchAppointmentDetailsState:
          fetchAppointmentDetailsState ?? this.fetchAppointmentDetailsState,
      updateAppointmentState:
          updateAppointmentState ?? this.updateAppointmentState,
    );
  }

  @override
  List<Object?> get props => [
        fetchAppointmentDetailsState,
        updateAppointmentState,
      ];
}
