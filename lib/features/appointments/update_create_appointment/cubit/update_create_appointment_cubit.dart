import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show BuildContext, TimeOfDay;
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'update_create_appointment_state.dart';

@Injectable()
class UpdateCreateAppointmentCubit extends Cubit<UpdateCreateAppointmentState> {
  UpdateCreateAppointmentCubit(this._appointmentRepository)
      : super(UpdateCreateAppointmentState.initial());

  final AppointmentRepository _appointmentRepository;

  void initialize({
    String? portfolioId,
    String? appointmentId,
    SellerPortfolio? portfolio,
    CustomerAppointment? appointment,
  }) {
    if (portfolio != null) {
      emit(
        state.copyWith(
          fetchPortfolioState: ProcessState.success(portfolio),
        ),
      );
      fetchPortfolioById(
        portfolio.id.toString(),
      );
    } else if (portfolioId != null) {
      fetchPortfolioById(portfolioId);
    }

    if (appointment != null) {
      emit(
        state.copyWith(
          fetchAppointmentState: ProcessState.success(appointment),
        ),
      );
      if (appointment.appointmentDateTime != null) {
        emit(state.copyWith(selectedDate: appointment.appointmentDateTime));
      }
      if (appointment.appointmentTime != null) {
        final parsedTime = TimeOfDay.fromDateTime(
          DateTime.parse(
            appointment.appointmentTime!,
          ),
        );
        emit(state.copyWith(selectedTime: parsedTime));
      }
      fetchAppointmentById(appointmentId.toString(), silent: true);
    } else if (appointmentId != null) {
      fetchAppointmentById(appointmentId);
    }
  }

  Future<void> fetchPortfolioById(
    String portfolioId, {
    bool silent = false,
  }) async {
    if (!silent) {
      emit(state.copyWith(fetchPortfolioState: const ProcessState.loading()));
    }
    final response = await _appointmentRepository.customerFetchPortfolioById(
      id: portfolioId,
    );
    response.when(
      success: (data) {
        emit(state.copyWith(fetchPortfolioState: ProcessState.success(data)));
        _fetchStylistDetailsById(data.userId.toString());
      },
      failure: (error) {
        if (!silent) {
          emit(state.copyWith(fetchPortfolioState: ProcessState.error(error)));
        }
      },
    );
  }

  Future<void> fetchAppointmentById(
    String appointmentId, {
    bool silent = false,
  }) async {
    if (!silent) {
      emit(
        state.copyWith(
          fetchAppointmentState: const ProcessState.loading(),
        ),
      );
    }
    final response =
        await _appointmentRepository.getCustomerAppointmentById(appointmentId);
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            fetchAppointmentState: ProcessState.success(data),
          ),
        );
        if (data.createdAt != null) {
          emit(state.copyWith(selectedDate: data.appointmentDateTime));
        }
        if (data.appointmentTime != null) {
          final parsedTime = TimeOfDay.fromDateTime(
            DateTime.parse(
              data.appointmentTime!,
            ),
          );
          emit(state.copyWith(selectedTime: parsedTime));
        }
      },
      failure: (error) {
        if (!silent) {
          emit(
            state.copyWith(
              fetchAppointmentState: ProcessState.error(error),
            ),
          );
        }
      },
    );
  }

  Future<void> _fetchStylistDetailsById(
    String stylistId, {
    bool silent = false,
  }) async {
    if (!silent) {
      emit(
        state.copyWith(
          fetchSellerDetailsState: const ProcessState.loading(),
        ),
      );
    }
    final response =
        await _appointmentRepository.customerFetchStylistById(stylistId);
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            fetchSellerDetailsState: ProcessState.success(data),
          ),
        );
      },
      failure: (error) {
        if (!silent) {
          emit(
            state.copyWith(
              fetchSellerDetailsState: ProcessState.error(error),
            ),
          );
        }
      },
    );
  }

  void onSelectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
  }

  void onSelectTime(TimeOfDay time) {
    emit(state.copyWith(selectedTime: time));
  }

  void onAddressChanged(String address) {
    emit(state.copyWith(address: address));
  }

  void onNotesChanged(String notes) {
    emit(state.copyWith(notes: notes));
  }

  Future<void> createAppointment(BuildContext context) async {
    emit(
      state.copyWith(
        updateOrCreateAppointmentState: const ProcessState.loading(),
      ),
    );
    final response = await _appointmentRepository.createAppointment(
      portfolioId: state.fetchPortfolioState.data!.id!.toString(),
      date: DateFormat('yyyy-MM-dd').format(state.selectedDate!),
      time: state.selectedTime!.format(context),
      note: state.notes,
      address: state.address,
    );
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updateOrCreateAppointmentState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateOrCreateAppointmentState: ProcessState.error(error),
          ),
        );
      },
    );
  }
}
