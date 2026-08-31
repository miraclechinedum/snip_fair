import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/settings.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/stylist_settings/stylist_settings.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';

part 'earnings_state.dart';

@Injectable()
class EarningsCubit extends Cubit<EarningsState> {
  EarningsCubit(this._profileRepository) : super(const EarningsState.initial());

  final ProfileRepository _profileRepository;

  Future<void> getEarnings() async {
    emit(state.copyWith(earnings: const ProcessState.loading()));
    final response = await _profileRepository.getEarnings();
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            earnings: ProcessState.success(data),
            settings: data.settings,
            // `/stylist/earnings` carries the stylist's own ledger,
            // including the holding-pouch rows that `/wallet/transactions`
            // omits. Fold them in so the Transactions tab shows escrow
            // entries the moment a booking is approved.
            transactionsState: ProcessState.success(
              _mergeTransactions(
                state.transactionsState.data,
                data.transactions,
              ),
            ),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(earnings: ProcessState.error(error)));
      },
    );
  }

  /// Unions two transaction collections, de-duplicating on `id` and keeping
  /// the newest row for any repeated id. Sorted newest-first.
  ///
  /// Pure display-layer plumbing — no amounts are computed or synthesised;
  /// every row is exactly what the server sent.
  static List<UserTransaction> _mergeTransactions(
    List<UserTransaction>? existing,
    List<UserTransaction>? incoming,
  ) {
    final byId = <int, UserTransaction>{};
    final unidentified = <UserTransaction>[];

    for (final t in [...?existing, ...?incoming]) {
      final id = t.id;
      if (id == null) {
        unidentified.add(t);
      } else {
        byId[id] = t;
      }
    }

    final merged = [...byId.values, ...unidentified]..sort((a, b) {
        final left = a.createdAt;
        final right = b.createdAt;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });
    return merged;
  }

  void onAutomaticPayoutChanged(bool value) {
    if (!value) return;

    emit(
      state.copyWith(
        settings: state.settings
            ?.copyWith(automaticPayout: value, instantPayout: !value),
      ),
    );
  }

  void onManualPayoutChanged(bool value) {
    if (!value) return;
    emit(
      state.copyWith(
        settings: state.settings
            ?.copyWith(automaticPayout: !value, instantPayout: value),
      ),
    );
  }

  void onPayoutFrequencyChanged(String value) {
    emit(
      state.copyWith(
        settings: state.settings?.copyWith(payoutFrequency: value),
      ),
    );
  }

  void onPayoutDayChanged(String value) {
    emit(
      state.copyWith(
        settings: state.settings?.copyWith(payoutDay: value),
      ),
    );
  }

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

  Future<void> updatePayoutSettings() async {
    emit(
      state.copyWith(updatePayoutSettingState: const ProcessState.loading()),
    );
    final response = await _profileRepository.updateStylistSettings(
      StylistSettings(
        automaticPayout: state.settings?.automaticPayout,
        instantPayout: state.settings?.instantPayout,
        payoutDay: state.settings?.payoutDay,
        payoutFrequency: state.settings?.payoutFrequency,
        enableMobileAppointments: state.settings?.enableMobileAppointments,
        enableShopAppointments: state.settings?.enableShopAppointments,
      ),
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updatePayoutSettingState: const ProcessState.success(true),
          ),
        );
        getEarnings();
      },
      failure: (error) {
        emit(
          state.copyWith(
            updatePayoutSettingState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> requestPayout(PaymentMethod paymentMethod, double amount) async {
    emit(
      state.copyWith(requestPayoutState: const ProcessState.loading()),
    );
    final response = await _profileRepository.requestPayout(
      paymentMethod.id.toString(),
      amount,
    );
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            requestPayoutState: const ProcessState.success(true),
          ),
        );
        getEarnings();
        fetchTransactions(isInitial: true);
      },
      failure: (error) {
        emit(
          state.copyWith(
            requestPayoutState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> fetchTransactions({bool isInitial = false}) async {
    if (isInitial) {
      emit(
        state.copyWith(
          transactionsState: const ProcessState.loading(),
          transactionsPaginationData: const PaginationData(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          transactionsPaginationData: PaginationData(
            isLoadingMore: true,
            nextPageCursor: state.transactionsPaginationData.nextPageCursor,
            prevPageCursor: state.transactionsPaginationData.prevPageCursor,
          ),
        ),
      );
    }

    final result = await _profileRepository.getWalletTransactions(
      page: state.transactionsPaginationData.nextPageCursor,
      perPage: 20,
    );

    result.when(
      success: (data) {
        final transactions = data.data ?? [];
        // On a full refresh, re-seed from the earnings ledger so the
        // holding-pouch rows survive a pull-to-refresh; on load-more, just
        // append the next wallet page.
        final updatedList = isInitial
            ? _mergeTransactions(
                state.earnings.data?.transactions,
                transactions,
              )
            : _mergeTransactions(
                state.transactionsState.data,
                transactions,
              );

        final updatedPaginationData = PaginationData(
          nextPageCursor: data.nextCursor,
          prevPageCursor: data.prevCursor,
          hasReachedMax: data.nextCursor == null,
        );

        emit(
          state.copyWith(
            transactionsState: ProcessState.success(updatedList),
            transactionsPaginationData: updatedPaginationData,
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
}
