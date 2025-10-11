part of 'seller_availability_schedule_cubit.dart';

List<String> scheduleDays = [
  'sunday',
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday'
];

class SellerAvailabilityScheduleState extends Equatable {
  SellerAvailabilityScheduleState.initial()
      : schedules = const ProcessState.init(null),
        scheduleAvailability = {
          for (var day in scheduleDays) day: false,
        },
        scheduleTimeSlots = {
          for (var day in scheduleDays) day: [],
        },
        timeFrom = const StringInput.pure(),
        timeTo = const StringInput.pure(),
        updateScheduleState = const ProcessState.init(null);

  const SellerAvailabilityScheduleState._({
    required this.schedules,
    required this.scheduleAvailability,
    required this.scheduleTimeSlots,
    required this.timeFrom,
    required this.timeTo,
    required this.updateScheduleState,
  });
  final ProcessState<List<Schedule>> schedules;
  final Map<String, bool> scheduleAvailability;
  final Map<String, List<TimeSlot>> scheduleTimeSlots;
  final StringInput timeFrom;
  final StringInput timeTo;
  final ProcessState<bool> updateScheduleState;

  bool get canAddTimeSlot => Formz.validate([timeFrom, timeTo]);

  SellerAvailabilityScheduleState copyWith({
    ProcessState<List<Schedule>>? schedules,
    Map<String, bool>? scheduleAvailability,
    Map<String, List<TimeSlot>>? scheduleTimeSlots,
    StringInput? timeFrom,
    StringInput? timeTo,
    ProcessState<bool>? updateScheduleState,
  }) {
    return SellerAvailabilityScheduleState._(
      schedules: schedules ?? this.schedules,
      scheduleAvailability: scheduleAvailability ?? this.scheduleAvailability,
      scheduleTimeSlots: scheduleTimeSlots ?? this.scheduleTimeSlots,
      timeFrom: timeFrom ?? this.timeFrom,
      timeTo: timeTo ?? this.timeTo,
      updateScheduleState: updateScheduleState ?? this.updateScheduleState,
    );
  }

  @override
  List<Object> get props {
    return [
      schedules,
      scheduleAvailability,
      scheduleTimeSlots,
      timeFrom,
      timeTo,
      updateScheduleState,
    ];
  }
}
