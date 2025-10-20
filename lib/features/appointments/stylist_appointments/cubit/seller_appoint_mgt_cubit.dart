import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment_list.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment_list.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';

part 'seller_appoint_mgt_state.dart';

@Injectable()
class SellerAppointMgtCubit extends Cubit<SellerAppointMgtState> {
  SellerAppointMgtCubit(this._appointmentRepository)
      : super(const SellerAppointMgtState.initial());

  final AppointmentRepository _appointmentRepository;

  Future<void> getAppointments({bool loadMore = false}) async {
    if (!loadMore) {
      emit(
        state.copyWith(
          appointments: const ProcessState.loading(),
          paginationData: const PaginationData(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          paginationData: PaginationData(
            isLoadingMore: true,
            nextPageCursor: state.paginationData.nextPageCursor,
            prevPageCursor: state.paginationData.prevPageCursor,
            hasReachedMax: state.paginationData.hasReachedMax,
          ),
        ),
      );
    }
    final response = await _appointmentRepository.getStylistAppointments(
      page: loadMore ? state.paginationData.nextPageCursor : null,
      perPage: 5,
    );
    response.when(
      success: (data) {
        if (loadMore) {
          final currentAppointments = state.appointments.data ?? [];
          final updatedAppointments = [...currentAppointments, ...?data.data];
          emit(
            state.copyWith(
              appointments: ProcessState.success(updatedAppointments),
              paginationData: PaginationData(
                nextPageCursor: data.nextCursor,
                prevPageCursor: data.prevCursor,
                hasReachedMax: data.nextCursor == null,
              ),
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            appointments: ProcessState.success(data.data ?? []),
            paginationData: PaginationData(
              nextPageCursor: data.nextCursor,
              prevPageCursor: data.prevCursor,
              hasReachedMax: data.nextCursor == null,
            ),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            appointments: ProcessState.error(error, state.appointments.data),
          ),
        );
      },
    );
  }

  Future<void> getCalendarAppointment() async {
    emit(
      state.copyWith(
        calendarAppointments:
            ProcessState.loading(state.calendarAppointments.data),
      ),
    );
    final response =
        await _appointmentRepository.getStylistAppointments(perPage: 50);
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            calendarAppointments: ProcessState.success(data.data ?? []),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            calendarAppointments:
                ProcessState.error(error, state.calendarAppointments.data),
          ),
        );
      },
    );
  }
}
