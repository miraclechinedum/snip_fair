part of 'customer_appointments_cubit.dart';

class CustomerAppointmentsState extends Equatable {
  const CustomerAppointmentsState._({
    required this.appointments,
    required this.updateAppointmentState,
    required this.paginationData,
    required this.calendarAppointments,
  });

  const CustomerAppointmentsState.initial()
      : appointments = const ProcessState.init(null),
        calendarAppointments = const ProcessState.init(null),
        updateAppointmentState = const ProcessState.init(null),
        paginationData = const PaginationData();

  final ProcessState<List<CustomerAppointment>> appointments;
  final ProcessState<List<CustomerAppointment>> calendarAppointments;
  final ProcessState<bool> updateAppointmentState;
  final PaginationData paginationData;

  CustomerAppointmentsState copyWith({
    ProcessState<List<CustomerAppointment>>? appointments,
    ProcessState<List<CustomerAppointment>>? calendarAppointments,
    ProcessState<bool>? updateAppointmentState,
    PaginationData? paginationData,
  }) {
    return CustomerAppointmentsState._(
      appointments: appointments ?? this.appointments,
      calendarAppointments: calendarAppointments ?? this.calendarAppointments,
      updateAppointmentState: updateAppointmentState ?? this.updateAppointmentState,
      paginationData: paginationData ?? this.paginationData,
    );
  }

  @override
  List<Object> get props => [
        appointments,
        updateAppointmentState,
        paginationData,
        calendarAppointments,
      ];
}
