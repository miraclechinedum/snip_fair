import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/bank/bank.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';

part 'seller_payment_methods_state.dart';

@Injectable()
class SellerPaymentMethodsCubit extends Cubit<SellerPaymentMethodsState> {
  SellerPaymentMethodsCubit(this._profileRepository)
      : super(const SellerPaymentMethodsState.initial());

  final ProfileRepository _profileRepository;

  Future<void> getPaymentMethods() async {
    emit(state.copyWith(paymentMethods: const ProcessState.loading()));
    final response = await _profileRepository.getPaymentMethods();
    response.when(
      success: (data) {
        emit(state.copyWith(paymentMethods: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(paymentMethods: ProcessState.error(error)));
      },
    );
  }

  Future<void> getBanks() async {
    emit(state.copyWith(banks: const ProcessState.loading()));
    final response = await _profileRepository.getBanks();
    response.when(
      success: (data) {
        emit(state.copyWith(banks: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(banks: ProcessState.error(error)));
      },
    );
  }

  Future<void> togglePaymentMethodActive(int id) async {
    emit(
      state.copyWith(updatePaymentMethodState: const ProcessState.loading()),
    );
    final response =
        await _profileRepository.togglePaymentMethodActive(id.toString());
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updatePaymentMethodState: const ProcessState.success(true),
          ),
        );
        getPaymentMethods();
        Fluttertoast.showToast(msg: 'Successfull...');
      },
      failure: (error) {
        emit(
          state.copyWith(
            updatePaymentMethodState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> makePaymentMethodDefault(int id) async {
    emit(
      state.copyWith(updatePaymentMethodState: const ProcessState.loading()),
    );
    final response =
        await _profileRepository.makePaymentMethodDefault(id.toString());
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updatePaymentMethodState: const ProcessState.success(true),
          ),
        );
        getPaymentMethods();
        Fluttertoast.showToast(msg: 'Successfull...');
      },
      failure: (error) {
        emit(
          state.copyWith(
            updatePaymentMethodState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> deletePaymentMethod(int id) async {
    emit(
      state.copyWith(updatePaymentMethodState: const ProcessState.loading()),
    );
    final response =
        await _profileRepository.deletePaymentMethod(id.toString());
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updatePaymentMethodState: const ProcessState.success(true),
          ),
        );
        getPaymentMethods();
        Fluttertoast.showToast(msg: 'Deleted...');
      },
      failure: (error) {
        emit(
          state.copyWith(
            updatePaymentMethodState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  void edit(PaymentMethod? paymentMethod) {
    if (paymentMethod == null) return;
    emit(
      state.copyWith(
        accountName: StringInput.dirty(paymentMethod.accountName ?? ''),
        accountNumber: StringInput.dirty(paymentMethod.accountNumber ?? ''),
        bankName: StringInput.dirty(paymentMethod.bankName ?? ''),
        branchName: StringInput.dirty(paymentMethod.routingNumber ?? ''),
      ),
    );
  }

  void resetForm() {
    emit(
      state.copyWith(
        accountName: const StringInput.pure(),
        accountNumber: const StringInput.pure(),
        bankName: const StringInput.pure(),
        branchName: const StringInput.pure(),
      ),
    );
  }

  void onAccountNameChanged(String value) {
    emit(state.copyWith(accountName: StringInput.dirty(value)));
  }

  void onBranchNameChanged(String value) {
    emit(state.copyWith(branchName: StringInput.dirty(value)));
  }

  void onAccountNumberChanged(String value) {
    emit(state.copyWith(accountNumber: StringInput.dirty(value)));
  }

  void onSelectBank(Bank value) {
    emit(state.copyWith(selectedBank: value));
  }

  Future<void> updateOrCreatePaymentMethod(int? id) async {
    emit(state.copyWith(addPaymentMethodState: const ProcessState.loading()));
    if (id != null) {
      final response = await _profileRepository.updatePaymentMethod(
        paymentMethodId: id.toString(),
        accountName: state.accountName.value,
        accountNumber: state.accountNumber.value,
        bankName: state.selectedBank!.name!,
        routingNumber: state.selectedBank!.branchCode!,
      );
      response.when(
        success: (data) {
          resetForm();
          emit(
            state.copyWith(
              addPaymentMethodState: const ProcessState.success(true),
            ),
          );
          getPaymentMethods();
        },
        failure: (error) {
          emit(
            state.copyWith(addPaymentMethodState: ProcessState.error(error)),
          );
        },
      );
    } else {
      final response = await _profileRepository.createPaymentMethod(
        accountName: state.accountName.value,
        accountNumber: state.accountNumber.value,
        bankName: state.selectedBank!.name!,
        routingNumber: state.selectedBank!.branchCode!,
      );
      response.when(
        success: (data) {
          resetForm();
          emit(
            state.copyWith(
              addPaymentMethodState: const ProcessState.success(true),
            ),
          );
          getPaymentMethods();
        },
        failure: (error) {
          emit(
            state.copyWith(addPaymentMethodState: ProcessState.error(error)),
          );
        },
      );
    }
  }
}
