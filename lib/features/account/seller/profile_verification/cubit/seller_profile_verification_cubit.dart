import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:equatable/equatable.dart';
import 'package:snip_fair/core/utils/input/input.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/utils/social_links.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/social.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/portfolio.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';

part 'seller_profile_verification_state.dart';

class SellerProfileVerificationCubit extends Cubit<SellerProfileVerificationState> {
  SellerProfileVerificationCubit(this._repository, this._profileDetails)
      : super(SellerProfileVerificationState.initial(_profileDetails));

  final ProfileRepository _repository;
  final StylistProfileDetails _profileDetails;

  void onBusinessNameChanged(String value) {
    emit(state.copyWith(businessName: StringInput.dirty(value)));
  }

  void onSocialAppChanged(String value) {
    emit(state.copyWith(socialApp: StringInput.dirty(value)));
  }

  void onSocialUrlChanged(String value) {
    emit(state.copyWith(socialLink: StringInput.dirty(value)));
  }

  /// Adds the entered link, or saves it over the one being edited. Only a
  /// full https URL is accepted — the backend rejects bare handles.
  void onAddSocialAccount() {
    if (!state.canAddSocial) return;
    final social = Social(
      socialApp: state.socialApp.value.trim(),
      url: state.socialLink.value.trim(),
    );
    final editing = state.editingSocialIndex;
    final socials = [...state.socials];
    if (editing != null && editing >= 0 && editing < socials.length) {
      socials[editing] = social;
    } else {
      socials.add(social);
    }
    emit(
      state.copyWith(
        socials: socials,
        socialApp: const StringInput.pure(),
        socialLink: const StringInput.pure(),
        editingSocialIndex: () => null,
      ),
    );
  }

  /// Loads an existing link into the form for editing.
  void onEditSocialAccount(int index) {
    if (index < 0 || index >= state.socials.length) return;
    final social = state.socials[index];
    emit(
      state.copyWith(
        socialApp: StringInput.dirty(social.socialApp ?? ''),
        socialLink: StringInput.dirty(social.url ?? ''),
        editingSocialIndex: () => index,
      ),
    );
  }

  void onCancelSocialEdit() {
    emit(
      state.copyWith(
        socialApp: const StringInput.pure(),
        socialLink: const StringInput.pure(),
        editingSocialIndex: () => null,
      ),
    );
  }

  void onRemoveSocialAccount(Social social) {
    final index = state.socials.indexOf(social);
    final editing = state.editingSocialIndex;
    emit(
      state.copyWith(
        socials: [...state.socials]..remove(social),
        editingSocialIndex: () => editing == null || index == editing
            ? null
            : (index < editing ? editing - 1 : editing),
        socialApp: index == editing ? const StringInput.pure() : null,
        socialLink: index == editing ? const StringInput.pure() : null,
      ),
    );
  }

  void onSelectImages(List<String> filePaths) {
    emit(state.copyWith(pastWorksFilePaths: filePaths));
  }

  void onRemoveImage(String image) {
    emit(
      state.copyWith(
        pastWorksFilePaths: [...state.pastWorksFilePaths]..remove(image),
      ),
    );
  }

  /// Updates only the social links (for approved stylists): `media` is
  /// omitted so work images are kept, and the business name is sent as is.
  /// The backend keeps the approval; availability is only affected if a
  /// requirement becomes incomplete, which [canSaveSocialLinks] prevents for
  /// social links.
  Future<void> saveSocialLinks() async {
    if (!state.canSaveSocialLinks) return;
    emit(state.copyWith(submitState: const ProcessState.loading()));
    final response = await _repository.updateStylistProfile(
      businessName: state.businessName.value,
      socials: state.socials,
    );
    response.when(
      success: (data) {
        emit(state.copyWith(submitState: const ProcessState.success(true)));
      },
      failure: (error) {
        emit(state.copyWith(submitState: ProcessState.error(error)));
      },
    );
  }

  Future<void> submitRequirements() async {
    emit(state.copyWith(submitState: const ProcessState.loading()));
    final response = await _repository.updateStylistProfile(
      businessName: state.businessName.value,
      socials: state.socials,
      // Omitted (null) unless the work images changed: the backend keeps
      // existing works when `media` is absent, so a socials-only save never
      // re-uploads or replaces them.
      medias: state.worksChanged ? state.pastWorksFilePaths : null,
    );
    response.when(
      success: (data) {
        emit(state.copyWith(submitState: const ProcessState.success(true)));
      },
      failure: (error) {
        emit(state.copyWith(submitState: ProcessState.error(error)));
      },
    );
  }
}
