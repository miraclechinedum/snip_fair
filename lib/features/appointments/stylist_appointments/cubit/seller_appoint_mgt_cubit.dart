import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment_list.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'seller_appoint_mgt_state.dart';

@Injectable()
class SellerAppointMgtCubit extends Cubit<SellerAppointMgtState> {
  SellerAppointMgtCubit(this._appointmentRepository)
      : super(const SellerAppointMgtState.initial());

  final AppointmentRepository _appointmentRepository;

  Future<void> getAppointments() async {
    emit(state.copyWith(appointments: const ProcessState.loading()));
    final response = await _appointmentRepository.getStylistAppointments();
    response.when(
      success: (data) {
        emit(state.copyWith(appointments: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(appointments: ProcessState.error(error)));
      },
    );
  }
}
