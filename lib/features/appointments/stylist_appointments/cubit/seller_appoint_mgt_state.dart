part of 'seller_appoint_mgt_cubit.dart';

class SellerAppointMgtState extends Equatable {
  const SellerAppointMgtState._(
      {required this.appointments, required this.updateAppointmentState});

  const SellerAppointMgtState.initial()
      : appointments = const ProcessState.init(null),
        updateAppointmentState = const ProcessState.init(null);

  final ProcessState<CustomerAppointmentList> appointments;
  final ProcessState<bool> updateAppointmentState;

  SellerAppointMgtState copyWith({
    ProcessState<CustomerAppointmentList>? appointments,
    ProcessState<bool>? updateAppointmentState,
  }) {
    return SellerAppointMgtState._(
      appointments: appointments ?? this.appointments,
      updateAppointmentState:
          updateAppointmentState ?? this.updateAppointmentState,
    );
  }

  @override
  List<Object> get props => [appointments, updateAppointmentState];
}
