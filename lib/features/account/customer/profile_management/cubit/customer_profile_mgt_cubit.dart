import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile_details.dart';
import 'package:snip_fair/core/domain/entities/customer_stats/customer_stats.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/customer_wallet.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';
import 'package:snip_fair/core/domain/entities/payfast_payment_data/payfast_payment_data.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';

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

  Future<void> getWalletTransactions({bool loadMore = false}) async {
    if (!loadMore) {
      emit(state.copyWith(transactionsState: const ProcessState.loading()));
    } else {
      // When loading more, set loadingMore flag
      emit(
        state.copyWith(
          transactionsPaginationData: PaginationData(
            isLoadingMore: true,
            nextPageCursor: state.transactionsPaginationData.nextPageCursor,
            prevPageCursor: state.transactionsPaginationData.prevPageCursor,
            hasReachedMax: state.transactionsPaginationData.hasReachedMax,
          ),
        ),
      );
    }

    final result = await _profileRepository.getWalletTransactions(
      page: loadMore ? state.transactionsPaginationData.nextPageCursor : null,
    );
    await result.when(
      success: (transactions) async {
        if (loadMore) {
          final currentTransactions = state.transactionsState.data ?? [];
          final updatedTransactions = [
            ...currentTransactions,
            ...?transactions.data,
          ];
          emit(
            state.copyWith(
              transactionsState: ProcessState.success(updatedTransactions),
              transactionsPaginationData: PaginationData(
                nextPageCursor: transactions.nextCursor,
                prevPageCursor: transactions.prevCursor,
                hasReachedMax: transactions.nextCursor == null,
              ),
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            transactionsState: ProcessState.success(transactions.data ?? []),
            transactionsPaginationData: PaginationData(
              nextPageCursor: transactions.nextCursor,
              prevPageCursor: transactions.prevCursor,
              hasReachedMax: transactions.nextCursor == null,
            ),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            transactionsState:
                ProcessState.error(error, state.transactionsState.data),
          ),
        );
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

  Future<void> pickAndUploadAvatar() async {
    final imagePath = await _pickImage();
    if (imagePath == null) return;
    emit(state.copyWith(updateAvatarState: const ProcessState.loading()));
    unawaited(Fluttertoast.showToast(msg: 'Uploading...'));
    final response =
        await _profileRepository.updateCustomerProfile(avatar: imagePath);
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

  Future<String?> _pickImage() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery);
    return result?.path;
  }

  void onLogout() {
    emit(const CustomerProfileMgtState.initial());
  }
}
