import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/domain/entities/stylist_account/stylist_account_status.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/stylist_stats.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'seller_profile_mgt_state.dart';

@Injectable()
class SellerProfileMgtCubit extends Cubit<SellerProfileMgtState> {
  SellerProfileMgtCubit(this._profileRepository)
      : super(const SellerProfileMgtState.initial()) {
    _notifSub = NotificationService.instance.updates.listen((data) {
      final type = data['type'] as String?;
      // Backend fires this when an admin approves the stylist. The approval
      // handler already sets `status='approved'` and `is_available=true`
      // server-side, so we just silently re-fetch the profile to pick up the
      // new values — the availability toggle and status card update on their
      // own without any UI action from the user.
      if (type == 'stylist_approved') {
        getProfileDetails(true);
      }
    });
  }

  final ProfileRepository _profileRepository;
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  Future<void> close() {
    _notifSub?.cancel();
    return super.close();
  }

  Future<void> getProfileDetails([bool silent = false]) async {
    final previous = state.profileDetails;
    if (!silent) {
      emit(state.copyWith(profileDetails: const ProcessState.loading()));
    }
    final result = await _profileRepository.getStylistProfile();
    await result.when(
      success: (profile) async {
        emit(
          state.copyWith(
            profileDetails: ProcessState.success(profile),
            // Keep the last known verdict if this response lacks one.
            stylistAccount: profile.stylistAccount,
          ),
        );
      },
      failure: (error) {
        if (error.code == 'VERIFY_EMAIL') {
          // An unverified-email stylist cannot read this endpoint yet. That
          // is an expected step, not an error: keep whatever was loaded and
          // the account status received when signing in.
          emit(state.copyWith(profileDetails: previous));
          return;
        }
        if (!silent) {
          emit(state.copyWith(profileDetails: ProcessState.error(error)));
        }
      },
    );
  }

  /// Submits a complete profile for admin approval.
  ///
  /// Laravel has no separate submit endpoint: every profile-changing call
  /// re-checks the requirements and, when all are complete and the status is
  /// `unverified` or `rejected`, sets it to `pending` and notifies the
  /// admins. This sends that call with nothing changed — the stored business
  /// name, no socials, no media — then re-reads the backend's verdict.
  Future<void> submitForApproval() async {
    if (state.submitForApprovalState.isLoading) return;
    emit(
      state.copyWith(submitForApprovalState: const ProcessState.loading()),
    );
    final businessName =
        state.profileDetails.data?.user?.stylistProfile?.businessName ?? '';
    final result = await _profileRepository.updateStylistProfile(
      // Empty is ignored by the backend (`?: existing`), never cleared.
      businessName: businessName,
    );
    await result.when(
      success: (_) async {
        await getProfileDetails(true);
        final pending =
            state.stylistAccount?.state == StylistAccountState.pendingApproval;
        emit(
          state.copyWith(
            submitForApprovalState: ProcessState.success(pending),
          ),
        );
      },
      failure: (error) async {
        emit(
          state.copyWith(submitForApprovalState: ProcessState.error(error)),
        );
      },
    );
  }

  /// Seeds the activation status from a login/registration response, before
  /// `GET /stylist/profile` is reachable (e.g. the email is unverified).
  void seedStylistAccount(StylistAccountStatus? account) {
    if (account == null) return;
    emit(state.copyWith(stylistAccount: account));
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
        emit(
          state.copyWith(
            updateLocationSettingsState: ProcessState.error(error),
          ),
        );
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
          state.copyWith(updateAvailabilityState: ProcessState.error(error)),
        );
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
    final result = await ImagePicker().pickImage(source: ImageSource.gallery);
    return result?.path;
  }

  Future<void> updateLocationConsent({required bool consentGiven}) async {
    await _profileRepository.updateLocationConsent(consentGiven);
  }

  Future<void> updateUserPosition({
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    await _profileRepository.updateUserLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }

  Future<void> deleteAccount() async {
    emit(state.copyWith(deleteAccountState: const ProcessState.loading()));

    final result = await _profileRepository.deleteAccount();
    result.when(
      success: (data) {
        emit(
          state.copyWith(
            deleteAccountState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(deleteAccountState: ProcessState.error(error)),
        );
      },
    );
  }

  void onLogout() {
    emit(const SellerProfileMgtState.initial());
  }
}
