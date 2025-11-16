import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/preferences.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'customer_prefs_settings_state.dart';

@Injectable()
class CustomerPrefsSettingsCubit extends Cubit<CustomerPrefsSettingsState> {
  CustomerPrefsSettingsCubit(this._profileRepository)
      : super(CustomerPrefsSettingsState.initial());

  final ProfileRepository _profileRepository;

  void setPreferences(Preferences preferences) {
    emit(state.copyWith(preferences: preferences));
  }

  Future<void> updatePreferences() async {
    emit(
      state.copyWith(
        updatePrefsState: const ProcessState.loading(),
      ),
    );

    final result = await _profileRepository.updateCustomerPreferences(
      state.preferences!,
    );

    result.when(
      success: (_) {
        emit(
          state.copyWith(
            updatePrefsState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            updatePrefsState: ProcessState.error(error),
          ),
        );
      },
    );
  }
}
