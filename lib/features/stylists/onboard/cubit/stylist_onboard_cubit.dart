import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';

part 'stylist_onboard_state.dart';

@Injectable()
class StylistOnboardCubit extends BaseCubit<StylistOnboardState> {
  StylistOnboardCubit(this._profileRepository)
      : super(const StylistOnboardState.initial());

  final ProfileRepository _profileRepository;

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

  void onDocNumberChanged(String value) {
    emit(state.copyWith(documentNumber: StringInput.dirty(value)));
  }

  void onImagePathChanged(String value) {
    emit(state.copyWith(imagePath: StringInput.dirty(value)));
  }

  Future<void> updateBusinessInfo() async {
    await launchApiCall(
      () => _profileRepository.updateBusinessInfo(
        businessName: state.businessName.value,
        country: state.address.value,
        yearsOfExperience: state.yearsOfExperience.value,
        bio: state.bio.value,
      ),
      doOnLoading: () => emit(
        state.copyWith(
          updateBusinessInfoResult: const ProcessState.loading(),
        ),
      ),
      doOnError: (p0) => emit(
        state.copyWith(updateBusinessInfoResult: ProcessState.error(p0)),
      ),
      doOnSuccess: (p0) => emit(
        state.copyWith(
          updateBusinessInfoResult: const ProcessState.success(true),
        ),
      ),
    );
  }

  Future<void> updateIdentityInfo() async {
    await launchApiCall(
      () => _profileRepository.updateIdentityInfo(
          documentNumber: state.documentNumber.value,
          filePath: state.imagePath.value),
      doOnLoading: () => emit(
        state.copyWith(
          updateIdentityInfoResult: const ProcessState.loading(),
        ),
      ),
      doOnError: (p0) => emit(
        state.copyWith(updateIdentityInfoResult: ProcessState.error(p0)),
      ),
      doOnSuccess: (p0) => emit(
        state.copyWith(
          updateIdentityInfoResult: const ProcessState.success(true),
        ),
      ),
    );
  }
}
