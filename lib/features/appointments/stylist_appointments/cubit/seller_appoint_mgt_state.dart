part of 'seller_appoint_mgt_cubit.dart';

class SellerAppointMgtState extends Equatable {
  const SellerAppointMgtState._({
    required this.appointments,
    required this.updateAppointmentState,
    required this.paginationData,
    required this.calendarAppointments,
  });

  const SellerAppointMgtState.initial()
      : appointments = const ProcessState.init(null),
        updateAppointmentState = const ProcessState.init(null),
        paginationData = const PaginationData(),
        calendarAppointments = const ProcessState.init(null);

  final ProcessState<List<StylistAppointment>> appointments;
  final ProcessState<List<StylistAppointment>> calendarAppointments;
  final ProcessState<bool> updateAppointmentState;
  final PaginationData paginationData;

  SellerAppointMgtState copyWith({
    ProcessState<List<StylistAppointment>>? appointments,
    ProcessState<bool>? updateAppointmentState,
    PaginationData? paginationData,
    ProcessState<List<StylistAppointment>>? calendarAppointments,
  }) {
    return SellerAppointMgtState._(
      appointments: appointments ?? this.appointments,
      calendarAppointments: calendarAppointments ?? this.calendarAppointments,
      updateAppointmentState:
          updateAppointmentState ?? this.updateAppointmentState,
      paginationData: paginationData ?? this.paginationData,
    );
  }

  @override
  List<Object> get props => [
        appointments,
        updateAppointmentState,
        paginationData,
        calendarAppointments
      ];
}
