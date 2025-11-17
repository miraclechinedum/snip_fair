import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/notifications.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'customer_notif_settings_state.dart';

@Injectable()
class CustomerNotifSettingsCubit extends Cubit<CustomerNotifSettingsState> {
  CustomerNotifSettingsCubit(this._profileRepository)
      : super(const CustomerNotifSettingsState.initial());

  final ProfileRepository _profileRepository;

  void setNotificationSettings(Notifications settings) {
    emit(state.copyWith(notificationSettings: settings));
  }

  Future<void> updateNotificationSettings() async {
    emit(
      state.copyWith(
        updateSettingsState: const ProcessState.loading(),
      ),
    );

    final result = await _profileRepository.updateCustomerNotificationSettings(
      state.notificationSettings!,
    );

    await result.when(
      success: (_) async {
        emit(
          state.copyWith(
            updateSettingsState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateSettingsState: ProcessState.error(error),
          ),
        );
      },
    );
  }
}
