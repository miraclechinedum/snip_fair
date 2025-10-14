import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/stylist_stats.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'seller_profile_mgt_state.dart';

@Injectable()
class SellerProfileMgtCubit extends Cubit<SellerProfileMgtState> {
  SellerProfileMgtCubit(this._profileRepository)
      : super(const SellerProfileMgtState.initial());

  final ProfileRepository _profileRepository;

  Future<void> getProfileDetails([bool silent = false]) async {
    if (!silent) {
      emit(state.copyWith(profileDetails: const ProcessState.loading()));
    }
    final result = await _profileRepository.getStylistProfile();
    await result.when(
      success: (profile) async {
        emit(
          state.copyWith(profileDetails: ProcessState.success(profile)),
        );
      },
      failure: (error) {
        if (!silent) {
          emit(state.copyWith(profileDetails: ProcessState.error(error)));
        }
      },
    );
  }

  Future<void> getStats() async {
    emit(state.copyWith(stylistStats: const ProcessState.loading()));

    final result = await _profileRepository.getStylistStats();
    await result.when(
      success: (stats) async {
        emit(
          state.copyWith(stylistStats: ProcessState.success(stats)),
        );
      },
      failure: (error) {
        emit(state.copyWith(stylistStats: ProcessState.error(error)));
      },
    );
  }

  Future<void> updateLocationSettings({
    required String address,
    required bool useLocation,
  }) async {
    emit(
      state.copyWith(
        updateLocationSettingsState: const ProcessState.loading(),
      ),
    );

    final result = await _profileRepository.updateUser(
      useLocation: useLocation,
      address: address,
    );
    result.when(
      success: (stats) {
        emit(
          state.copyWith(
            updateLocationSettingsState: const ProcessState.success(true),
          ),
        );
        getProfileDetails(true);
      },
      failure: (error) {
        emit(state.copyWith(
            updateLocationSettingsState: ProcessState.error(error)));
      },
    );
  }

  Future<void> updateAvailability({
    required bool isAvailable,
  }) async {
    emit(
      state.copyWith(
        updateAvailabilityState: const ProcessState.loading(),
      ),
    );

    final result = await _profileRepository.updateAvailability(
      isAvailable: isAvailable,
    );
    result.when(
      success: (stats) {
        emit(
          state.copyWith(
            updateAvailabilityState: const ProcessState.success(true),
          ),
        );
        getProfileDetails(true);
      },
      failure: (error) {
        emit(
            state.copyWith(updateAvailabilityState: ProcessState.error(error)));
      },
    );
  }

  Future<void> pickAndUploadAvatar() async {
    final imagePath = await _pickImage();
    if (imagePath == null) return;
    emit(state.copyWith(updateAvatarState: const ProcessState.loading()));
    unawaited(Fluttertoast.showToast(msg: 'Uploading...'));
    final response = await _profileRepository.updateAvatar(imagePath);
    response.when(
      success: (data) {
        getProfileDetails(true);
        emit(
          state.copyWith(
            updateAvatarState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateAvatarState: ProcessState.error(
              error.errorResponse?.message ?? 'Upload failed',
            ),
          ),
        );
      },
    );
  }

  Future<void> pickAndUploadBanner() async {
    final imagePath = await _pickImage();
    if (imagePath == null) return;
    emit(state.copyWith(updateBannerState: const ProcessState.loading()));
    unawaited(Fluttertoast.showToast(msg: 'Uploading...'));
    final response = await _profileRepository.updateBanner(imagePath);
    response.when(
      success: (data) {
        getProfileDetails(true);
        emit(
          state.copyWith(
            updateBannerState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateBannerState: ProcessState.error(
              error.errorResponse?.message ?? 'Upload failed',
            ),
          ),
        );
      },
    );
  }

  Future<String?> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    return result?.paths.single;
  }
}
