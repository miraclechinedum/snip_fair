import 'package:auto_route/auto_route.dart';
import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/phone_input.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';

part 'seller_personal_details_state.dart';

@Injectable()
class SellerPersonalDetailsCubit extends BaseCubit<SellerPersonalDetailsState> {
  SellerPersonalDetailsCubit(this._profileRepository)
      : super(const SellerPersonalDetailsState.initial());

  final ProfileRepository _profileRepository;

  void onFirstNameChanged(String value) {
    emit(state.copyWith(firstName: StringInput.dirty(value.trim())));
  }

  void onLastNameChanged(String value) {
    emit(state.copyWith(lastName: StringInput.dirty(value.trim())));
  }

  void onPhoneChanged(String value) {
    emit(state.copyWith(phone: PhoneInput.dirty(value.trim())));
  }

  void onBusinessNameChanged(String value) {
    emit(state.copyWith(businessName: StringInput.dirty(value)));
  }

  void onAddressChanged(String value) {
    emit(state.copyWith(address: StringInput.dirty(value)));
  }

  void onYearsOfExperienceChanged(String value) {
    emit(state.copyWith(yearsOfExperience: StringInput.dirty(value)));
  }

  void onBioChanged(String value) {
    emit(state.copyWith(bio: StringInput.dirty(value)));
  }

  Future<void> updateBusinessInfo(StylistProfileDetails details) async {
    await launchApiCall(
      () => _profileRepository.updateStylistProfile(
        socials: details.user?.stylistProfile?.socials ?? [],
        medias: details.user?.stylistProfile?.works ?? [],
        businessName: state.businessName.value,
        country: state.address.value,
        yearsOfExperience: state.yearsOfExperience.value,
        bio: state.bio.value,
      ),
      doOnLoading: () => emit(
        state.copyWith(
          updateProfile: const ProcessState.loading(),
        ),
      ),
      doOnError: (p0) => emit(
        state.copyWith(updateProfile: ProcessState.error(p0)),
      ),
      doOnSuccess: (p0) => emit(
        state.copyWith(
          updateProfile: const ProcessState.success(true),
        ),
      ),
    );
  }
}
