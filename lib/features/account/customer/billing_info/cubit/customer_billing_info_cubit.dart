import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/utils/input/input.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';

part 'customer_billing_info_state.dart';

@Injectable()
class CustomerBillingInfoCubit extends BaseCubit<CustomerBillingInfoState> {
  CustomerBillingInfoCubit(this._profileRepository)
      : super(CustomerBillingInfoState.initial());

  final ProfileRepository _profileRepository;

  void nameChanged(String value) {
    final name = StringInput.dirty(value);
    emit(
      state.copyWith(
        name: name,
      ),
    );
  }

  void emailChanged(String value) {
    final email = StringInput.dirty(value);
    emit(
      state.copyWith(
        email: email,
      ),
    );
  }

  void cityChanged(String value) {
    final city = StringInput.dirty(value);
    emit(
      state.copyWith(
        city: city,
      ),
    );
  }

  void zipCodeChanged(String value) {
    final zipCode = StringInput.dirty(value);
    emit(
      state.copyWith(
        zipCode: zipCode,
      ),
    );
  }

  void locationChanged(String value) {
    final location = StringInput.dirty(value);
    emit(
      state.copyWith(
        location: location,
      ),
    );
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;

    await launchApiCall(
      () => _profileRepository.updateCustomerBillingInfo(
        name: state.name.value,
        email: state.email.value,
        city: state.city.value,
        zipCode: state.zipCode.value,
        location: state.location.value,
      ),
      doOnLoading: () => emit(
        state.copyWith(updateBillingInfoState: const ProcessState.loading()),
      ),
      doOnError: (p0) =>
          emit(state.copyWith(updateBillingInfoState: ProcessState.error(p0))),
      doOnSuccess: (p0) => emit(
        state.copyWith(
            updateBillingInfoState: const ProcessState.success(true),),
      ),
    );
  }
}
