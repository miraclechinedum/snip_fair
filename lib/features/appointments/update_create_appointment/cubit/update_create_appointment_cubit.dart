import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'
    show BuildContext, MaterialLocalizations, TimeOfDay;
import 'package:fluttertoast/fluttertoast.dart';
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

  late BuildContext context;

  void initialize(
    BuildContext context, {
    String? portfolioId,
    String? appointmentId,
  }) {
    this.context = context;
    if (portfolioId != null) {
      fetchPortfolioById(portfolioId);
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
        onAddressChanged(data.user?.country ?? '');
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
          final parsedTime = TimeOfDay(
            hour: int.parse(data.appointmentTime!.split(':')[0]),
            minute: int.parse(data.appointmentTime!.split(':')[1]),
          );
          emit(state.copyWith(selectedTime: parsedTime));
        }
        onNotesChanged(data.extra?.toString() ?? '');
        fetchPortfolioById(
          data.portfolioId.toString(),
        );
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
    if (state.fetchAppointmentState.hasSuccess) return;

    emit(state.copyWith(selectedDate: date));
  }

  void onSelectTime(TimeOfDay time) {
    if (state.fetchAppointmentState.hasSuccess) return;

    emit(state.copyWith(selectedTime: time));
  }

  void onAddressChanged(String address) {
    if (state.fetchAppointmentState.hasSuccess) return;
    emit(state.copyWith(address: address));
  }

  void onNotesChanged(String notes) {
    if (state.fetchAppointmentState.hasSuccess) return;
    emit(state.copyWith(notes: notes));
  }

  Future<void> createAppointment() async {
    emit(
      state.copyWith(
        updateOrCreateAppointmentState: const ProcessState.loading(),
      ),
    );
    final localizations = MaterialLocalizations.of(context);
    final response = await _appointmentRepository.createAppointment(
      portfolioId: state.fetchPortfolioState.data!.id!.toString(),
      date: DateFormat('yyyy-MM-dd').format(state.selectedDate!),
      time: localizations.formatTimeOfDay(state.selectedTime!),
      note: state.notes,
      address: state.address,
    );
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updateOrCreateAppointmentState: const ProcessState.success(true),
            fetchAppointmentState: ProcessState.success(data),
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

  Future<void> cancelAppointment() async {
    emit(state.copyWith(cancelBookingState: const ProcessState.loading()));
    final response = await _appointmentRepository.updateCustomerAppointment(
      state.fetchAppointmentState.data!.id!.toString(),
      verdict: 'cancel',
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            cancelBookingState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(cancelBookingState: ProcessState.error(error)));
      },
    );
  }

  Future<void> rescheduleAppointment() async {
    emit(state.copyWith(rescheduleBookingState: const ProcessState.loading()));
    final response = await _appointmentRepository.updateCustomerAppointment(
      state.fetchAppointmentState.data!.id!.toString(),
      verdict: 'reschedule',
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            rescheduleBookingState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(rescheduleBookingState: ProcessState.error(error)));
      },
    );
  }

  Future<void> reviewAppointment({required int rating, String? comment}) async {
    Fluttertoast.showToast(msg: 'Submitting review...');
    final response = await _appointmentRepository.reviewCustomerAppointment(
      state.fetchAppointmentState.data!.id!.toString(),
      rating: rating,
      comment: comment,
    );

    response.when(
      success: (data) {
        Fluttertoast.showToast(msg: 'Review submitted');
      },
      failure: (error) {
        Fluttertoast.showToast(msg: 'Failed to submit review');
      },
    );
  }

  Future<void> submitDispute(
      {required String comment, required List<String> images}) async {
    Fluttertoast.showToast(msg: 'Initiating dispute...');
    final response = await _appointmentRepository.disputeCustomerAppointment(
      state.fetchAppointmentState.data!.id!.toString(),
      images: images,
      comment: comment,
    );

    response.when(
      success: (data) {
        Fluttertoast.showToast(msg: 'Dispute submitted');
      },
      failure: (error) {
        Fluttertoast.showToast(msg: 'Failed to submit dispute');
      },
    );
  }
}
