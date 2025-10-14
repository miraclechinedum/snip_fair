import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile_details.dart';
import 'package:snip_fair/core/domain/entities/customer_stats/customer_stats.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/customer_wallet.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/core/domain/entities/payfast_payment_data/payfast_payment_data.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'customer_profile_mgt_state.dart';

@Injectable()
class CustomerProfileMgtCubit extends Cubit<CustomerProfileMgtState> {
  CustomerProfileMgtCubit(this._profileRepository)
      : super(const CustomerProfileMgtState.initial());

  final ProfileRepository _profileRepository;

  Future<void> getProfileDetails([bool silent = false]) async {
    if (!silent) {
      emit(state.copyWith(profileDetails: const ProcessState.loading()));
    }
    final result = await _profileRepository.getCustomerProfile();
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
    emit(state.copyWith(customerStats: const ProcessState.loading()));

    final result = await _profileRepository.getCustomerStats();
    await result.when(
      success: (stats) async {
        emit(
          state.copyWith(customerStats: ProcessState.success(stats)),
        );
      },
      failure: (error) {
        emit(state.copyWith(customerStats: ProcessState.error(error)));
      },
    );
  }

  Future<void> getWallet([bool silent = false]) async {
    if (!silent) {
      emit(state.copyWith(walletState: const ProcessState.loading()));
    }
    final result = await _profileRepository.getWallet();
    await result.when(
      success: (wallet) async {
        emit(
          state.copyWith(walletState: ProcessState.success(wallet)),
        );
      },
      failure: (error) {
        if (!silent) {
          emit(state.copyWith(walletState: ProcessState.error(error)));
        }
      },
    );
  }

  Future<void> getWalletTransactions() async {
    emit(state.copyWith(transactionsState: const ProcessState.loading()));

    final result = await _profileRepository.getWalletTransactions();
    await result.when(
      success: (transactions) async {
        emit(
          state.copyWith(transactionsState: ProcessState.success(transactions)),
        );
      },
      failure: (error) {
        emit(state.copyWith(transactionsState: ProcessState.error(error)));
      },
    );
  }

  Future<void> initialisePayfastDeposit({
    required String type,
    required String amount,
    String? email,
    String? firstName,
    String? lastName,
    String? portfolioId,
  }) async {
    emit(state.copyWith(initializePaymentState: const ProcessState.loading()));

    final result = await _profileRepository.initialisePayfastDeposit(
      type: type,
      amount: amount,
      email: email,
      firstName: firstName,
      lastName: lastName,
      portfolioId: portfolioId,
    );
    await result.when(
      success: (paymentData) async {
        emit(
          state.copyWith(
            initializePaymentState: ProcessState.success(paymentData),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            initializePaymentState: ProcessState.error(error),
          ),
        );
      },
    );
  }
}
