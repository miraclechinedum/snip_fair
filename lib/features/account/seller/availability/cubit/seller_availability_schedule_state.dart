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
        userChangedSomething = false,
        updateScheduleState = const ProcessState.init(null);

  const SellerAvailabilityScheduleState._({
    required this.schedules,
    required this.scheduleAvailability,
    required this.scheduleTimeSlots,
    required this.updateScheduleState,
    required this.userChangedSomething,
  });
  final ProcessState<List<Schedule>> schedules;
  final Map<String, bool> scheduleAvailability;
  final Map<String, List<TimeSlot>> scheduleTimeSlots;
  final bool userChangedSomething;
  final ProcessState<bool> updateScheduleState;

  SellerAvailabilityScheduleState copyWith({
    ProcessState<List<Schedule>>? schedules,
    Map<String, bool>? scheduleAvailability,
    Map<String, List<TimeSlot>>? scheduleTimeSlots,
    ProcessState<bool>? updateScheduleState,
    bool? userChangedSomething,
  }) {
    return SellerAvailabilityScheduleState._(
      schedules: schedules ?? this.schedules,
      scheduleAvailability: scheduleAvailability ?? this.scheduleAvailability,
      scheduleTimeSlots: scheduleTimeSlots ?? this.scheduleTimeSlots,
      updateScheduleState: updateScheduleState ?? this.updateScheduleState,
      userChangedSomething: userChangedSomething ?? this.userChangedSomething,
    );
  }

  @override
  List<Object> get props {
    return [
      schedules,
      scheduleAvailability,
      scheduleTimeSlots,
      updateScheduleState,
      userChangedSomething,
    ];
  }
}
