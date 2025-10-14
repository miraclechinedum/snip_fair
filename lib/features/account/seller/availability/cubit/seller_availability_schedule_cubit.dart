import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/schedule.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/timeslot.dart';
import 'package:snip_fair/core/domain/params/schedule_params.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'seller_availability_schedule_state.dart';

@Injectable()
class SellerAvailabilityScheduleCubit
    extends Cubit<SellerAvailabilityScheduleState> {
  SellerAvailabilityScheduleCubit(this._profileRepository)
      : super(SellerAvailabilityScheduleState.initial());

  final ProfileRepository _profileRepository;

  Future<void> getAvailabilitySchedule() async {
    emit(state.copyWith(schedules: const ProcessState.loading()));
    final response = await _profileRepository.getAvailability();
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            schedules: ProcessState.success(data.schedules ?? []),
          ),
        );
        _generateSchedule(data.schedules ?? []);
      },
      failure: (error) {
        emit(state.copyWith(schedules: ProcessState.error(error)));
      },
    );
  }

  void _generateSchedule(List<Schedule> schedules) {
    final scheduleTimeSlotsMap = {...state.scheduleTimeSlots};
    final scheduleAvailabilityMap = {...state.scheduleAvailability};
    for (final schedule in schedules) {
      scheduleAvailabilityMap.update(
        schedule.day!,
        (value) => schedule.available ?? false,
      );

      scheduleTimeSlotsMap.update(
        schedule.day!,
        (value) =>
            schedule.slots
                ?.map(
                  (slot) => slot.copyWith(
                    from: slot.from?.split(':').take(2).join(':'),
                    to: slot.to?.split(':').take(2).join(':'),
                  ),
                )
                .toList() ??
            [],
      );
    }
    emit(
      state.copyWith(
        scheduleAvailability: scheduleAvailabilityMap,
        scheduleTimeSlots: scheduleTimeSlotsMap,
      ),
    );
  }

  void addTimeSlot(String day) {
    final scheduleTimeSlotsMap = {...state.scheduleTimeSlots};
    final timeSlot = TimeSlot();
    scheduleTimeSlotsMap.update(day, (value) {
      final list = [...value, timeSlot];
      return list;
    });
    emit(state.copyWith(scheduleTimeSlots: scheduleTimeSlotsMap));
  }

  void updateTimeSlot({
    required String day,
    required int index,
    required TimeSlot slot,
  }) {
    final scheduleTimeSlotsMap = {...state.scheduleTimeSlots};
    final timeSlot = slot;
    scheduleTimeSlotsMap.update(day, (value) {
      final list = [...value];
      list[index] = timeSlot;
      return list;
    });
    emit(state.copyWith(scheduleTimeSlots: scheduleTimeSlotsMap));
  }

  void deleteTimeSlot({required String day, required int index}) {
    final scheduleTimeSlotsMap = {...state.scheduleTimeSlots}
      ..update(day, (value) {
        final list = [...value]..removeAt(index);
        return list;
      });
    emit(state.copyWith(scheduleTimeSlots: scheduleTimeSlotsMap));
  }

  void updateAvailabilitu({required String day, required bool newValue}) {
    final scheduleAvailabilityMap = {...state.scheduleAvailability}
      ..update(day, (value) => newValue);
    emit(state.copyWith(scheduleAvailability: scheduleAvailabilityMap));
  }

  Future<void> submitAvailability() async {
    emit(state.copyWith(updateScheduleState: const ProcessState.loading()));
    final schedules = [
      for (final day in scheduleDays)
        ScheduleParams(
          day: day,
          available: state.scheduleAvailability[day],
          timeSlots: state.scheduleTimeSlots[day],
        ),
    ];
    final response =
        await _profileRepository.updateAvailability(schedules: schedules);

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updateScheduleState: const ProcessState.success(true),
          ),
        );
        getAvailabilitySchedule();
      },
      failure: (error) {
        emit(state.copyWith(updateScheduleState: ProcessState.error(error)));
      },
    );
  }
}
