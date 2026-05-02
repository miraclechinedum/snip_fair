import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/input/phone_input.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile_details.dart';

part 'customer_personal_details_state.dart';

@Injectable()
class CustomerPersonalDetailsCubit
    extends BaseCubit<CustomerPersonalDetailsState> {
  CustomerPersonalDetailsCubit(this._profileRepository)
      : super(const CustomerPersonalDetailsState.initial());

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

  void onAddressChanged(String value) {
    emit(state.copyWith(address: StringInput.dirty(value)));
  }

  void onGenderChanged(String value) {
    emit(state.copyWith(gender: StringInput.dirty(value)));
  }

  void onBioChanged(String value) {
    emit(state.copyWith(bio: StringInput.dirty(value)));
  }

  Future<void> updateProfile(CustomerProfileDetails details) async {
    await launchApiCall(
      () => _profileRepository.updateCustomerProfile(
        firstName: state.firstName.value,
        lastName: state.lastName.value,
        phone: state.phone.value,
        country: state.address.value,
        bio: state.bio.value,
        gender: state.gender.value,
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

  void onAvatarChanged(String s) {
    emit(state.copyWith(avatar: StringInput.dirty(s)));
  }

  void pickAndUploadAvatar() {}
}
