import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/settings.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/stylist_settings/stylist_settings.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'earnings_state.dart';

@Injectable()
class EarningsCubit extends Cubit<EarningsState> {
  EarningsCubit(this._profileRepository) : super(const EarningsState.initial());

  final ProfileRepository _profileRepository;

  Future<void> getEarnings() async {
    emit(state.copyWith(earnings: const ProcessState.loading()));
    final response = await _profileRepository.getEarnings();
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            earnings: ProcessState.success(data),
            settings: data.settings,
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(earnings: ProcessState.error(error)));
      },
    );
  }

  void onAutomaticPayoutChanged(bool value) {
    if (!value) return;

    emit(
      state.copyWith(
        settings: state.settings
            ?.copyWith(automaticPayout: value, instantPayout: !value),
      ),
    );
  }

  void onManualPayoutChanged(bool value) {
    if (!value) return;
    emit(
      state.copyWith(
        settings: state.settings
            ?.copyWith(automaticPayout: !value, instantPayout: value),
      ),
    );
  }

  void onPayoutFrequencyChanged(String value) {
    emit(
      state.copyWith(
        settings: state.settings?.copyWith(payoutFrequency: value),
      ),
    );
  }

  void onPayoutDayChanged(String value) {
    emit(
      state.copyWith(
        settings: state.settings?.copyWith(payoutDay: value),
      ),
    );
  }

  Future<void> updatePayoutSettings() async {
    emit(
      state.copyWith(updatePayoutSettingState: const ProcessState.loading()),
    );
    final response = await _profileRepository.updateStylistSettings(
      StylistSettings(
        automaticPayout: state.settings?.automaticPayout,
        instantPayout: state.settings?.instantPayout,
        payoutDay: state.settings?.payoutDay,
        payoutFrequency: state.settings?.payoutFrequency,
        enableMobileAppointments: state.settings?.enableMobileAppointments,
        enableShopAppointments: state.settings?.enableShopAppointments,
      ),
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updatePayoutSettingState: const ProcessState.success(true),
          ),
        );
        getEarnings();
      },
      failure: (error) {
        emit(
          state.copyWith(
            updatePayoutSettingState: ProcessState.error(error),
          ),
        );
      },
    );
  }
}
