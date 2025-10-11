import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/schedule.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/timeslot.dart';
import 'package:snip_fair/core/domain/params/schedule_params.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';

part 'seller_availability_schedule_state.dart';

@Injectable()
class SellerAvailabilityScheduleCubit
    extends Cubit<SellerAvailabilityScheduleState> {
  SellerAvailabilityScheduleCubit(this._profileRepository)
      : super(SellerAvailabilityScheduleState.initial());

  final ProfileRepository _profileRepository;

  Future<void> getAvailabilitySchedule() async {
    emit(state.copyWith(schedules: const ProcessState.init(null)));
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
        (value) => schedule.slots ?? [],
      );
    }
  }

  void onFromChanged(String value) {
    emit(state.copyWith(timeFrom: StringInput.dirty(value)));
  }

  void onToChanged(String value) {
    emit(state.copyWith(timeTo: StringInput.dirty(value)));
  }

  void resetForm() {
    emit(
      state.copyWith(
        timeTo: const StringInput.pure(),
        timeFrom: const StringInput.pure(),
      ),
    );
  }

  void addTimeSlot(String day) {
    final scheduleTimeSlotsMap = {...state.scheduleTimeSlots};
    final timeSlot =
        TimeSlot(from: state.timeFrom.value, to: state.timeTo.value);
    scheduleTimeSlotsMap.update(day, (value) {
      return value..add(timeSlot);
    });
    emit(state.copyWith(scheduleTimeSlots: scheduleTimeSlotsMap));
    resetForm();
  }

  void updateTimeSlot({required String day, required int index}) {
    final scheduleTimeSlotsMap = {...state.scheduleTimeSlots};
    final timeSlot =
        TimeSlot(from: state.timeFrom.value, to: state.timeTo.value);
    scheduleTimeSlotsMap.update(day, (value) {
      final list = [...value];
      list[index] = timeSlot;
      return list;
    });
    emit(state.copyWith(scheduleTimeSlots: scheduleTimeSlotsMap));
    resetForm();
  }

  void deleteTimeSlot({required String day, required int index}) {
    final scheduleTimeSlotsMap = {...state.scheduleTimeSlots}
      ..update(day, (value) {
        final list = [...value]..removeAt(index);
        return list;
      });
    emit(state.copyWith(scheduleTimeSlots: scheduleTimeSlotsMap));
    resetForm();
  }

  void updateAvailabilitu({required String day, required bool newValue}) {
    final scheduleAvailabilityMap = {...state.scheduleAvailability}
      ..update(day, (value) => newValue);
    emit(state.copyWith(scheduleAvailability: scheduleAvailabilityMap));
    resetForm();
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
      },
      failure: (error) {
        emit(state.copyWith(updateScheduleState: ProcessState.error(error)));
      },
    );
  }
}
