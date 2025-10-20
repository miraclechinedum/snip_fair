import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/domain/entities/seller_details/appointment.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'seller_appointment_details_state.dart';

@Injectable()
class SellerAppointmentDetailsCubit
    extends Cubit<SellerAppointmentDetailsState> {
  SellerAppointmentDetailsCubit(this._appointmentRepository)
      : super(const SellerAppointmentDetailsState.initial());

  final AppointmentRepository _appointmentRepository;

  Future<void> getAppointmentDetails(String appointmentId) async {
    emit(
      state.copyWith(
        fetchAppointmentDetailsState: const ProcessState.loading(),
      ),
    );

    final response =
        await _appointmentRepository.getStylistAppointmentById(appointmentId);

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            fetchAppointmentDetailsState: ProcessState.success(data),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            fetchAppointmentDetailsState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> acceptAppointment() async {
    emit(
      state.copyWith(
        updateAppointmentState: const ProcessState.loading(),
      ),
    );

    final appointmentId =
        state.fetchAppointmentDetailsState.data?.id.toString() ?? '';

    final response = await _appointmentRepository
        .updateStylistAppointment(appointmentId, verdict: 'approve');

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updateAppointmentState: const ProcessState.success(true),
          ),
        );
        getAppointmentDetails(appointmentId);
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateAppointmentState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> rejectAppointment() async {
    emit(
      state.copyWith(
        updateAppointmentState: const ProcessState.loading(),
      ),
    );

    final appointmentId =
        state.fetchAppointmentDetailsState.data?.id.toString() ?? '';

    final response = await _appointmentRepository
        .updateStylistAppointment(appointmentId, verdict: 'reject');

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updateAppointmentState: const ProcessState.success(true),
          ),
        );
        getAppointmentDetails(appointmentId);
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateAppointmentState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> confirmAppointment(String confirmCode) async {
    emit(
      state.copyWith(
        updateAppointmentState: const ProcessState.loading(),
      ),
    );

    final appointmentId =
        state.fetchAppointmentDetailsState.data?.id.toString() ?? '';

    final response = await _appointmentRepository.updateStylistAppointment(
      appointmentId,
      verdict: 'confirm',
      code: confirmCode,
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updateAppointmentState: const ProcessState.success(true),
          ),
        );

        getAppointmentDetails(appointmentId);
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateAppointmentState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> completeAppointment(String completeCode) async {
    emit(
      state.copyWith(
        updateAppointmentState: const ProcessState.loading(),
      ),
    );

    final appointmentId =
        state.fetchAppointmentDetailsState.data?.id.toString() ?? '';

    final response = await _appointmentRepository.updateStylistAppointment(
      appointmentId,
      verdict: 'complete',
      code: completeCode,
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updateAppointmentState: const ProcessState.success(true),
          ),
        );

        getAppointmentDetails(appointmentId);
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateAppointmentState: ProcessState.error(error),
          ),
        );
      },
    );
  }
}
