import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/portfolio.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/social.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/input.dart';

part 'seller_profile_verification_state.dart';

class SellerProfileVerificationCubit
    extends Cubit<SellerProfileVerificationState> {
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

  void onAddSocialAccount() {
    final social =
        Social(socialApp: state.socialApp.value, url: state.socialLink.value);

    emit(
      state.copyWith(
        socials: [...state.socials, social],
        socialApp: const StringInput.pure(),
        socialLink: const StringInput.pure(),
      ),
    );
  }

  void onRemoveSocialAccount(Social social) {
    emit(state.copyWith(socials: [...state.socials]..remove(social)));
  }

  void onSelectImages(List<String> filePaths) {
    emit(state.copyWith(pastWorksFilePaths: filePaths));
  }

  void onRemoveImage(String image) {
    emit(state.copyWith(
        pastWorksFilePaths: [...state.pastWorksFilePaths]..remove(image)));
  }

  Future<void> submitRequirements() async {
    emit(state.copyWith(submitState: const ProcessState.loading()));
    final response = await _repository.updateStylistProfile(
      businessName: state.businessName.value,
      socials: state.socials,
      medias: state.pastWorksFilePaths,
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
