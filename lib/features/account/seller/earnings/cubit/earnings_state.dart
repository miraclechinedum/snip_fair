part of 'earnings_cubit.dart';

class EarningsState extends Equatable {
  const EarningsState._({
    required this.earnings,
    required this.settings,
    required this.updatePayoutSettingState,
    required this.paymentMethods,
    required this.transactionsState,
    required this.transactionsPaginationData,
    required this.requestPayoutState,
  });

  const EarningsState.initial()
      : earnings = const ProcessState.init(null),
        paymentMethods = const ProcessState.init([]),
        updatePayoutSettingState = const ProcessState.init(null),
        transactionsState = const ProcessState.init(null),
          requestPayoutState = const ProcessState.init(null),
        transactionsPaginationData = const PaginationData(),
        settings = null;

  final ProcessState<StylistEarnings> earnings;
  final Settings? settings;
  final ProcessState<bool> updatePayoutSettingState;
  final ProcessState<bool> requestPayoutState;
  final ProcessState<List<PaymentMethod>> paymentMethods;
  final ProcessState<List<UserTransaction>> transactionsState;
  final PaginationData transactionsPaginationData;

  EarningsState copyWith({
    ProcessState<StylistEarnings>? earnings,
    Settings? settings,
    ProcessState<bool>? updatePayoutSettingState,
    ProcessState<List<PaymentMethod>>? paymentMethods,
    ProcessState<List<UserTransaction>>? transactionsState,
    PaginationData? transactionsPaginationData,
    ProcessState<bool>? requestPayoutState,
  }) {
    return EarningsState._(
      earnings: earnings ?? this.earnings,
      settings: settings ?? this.settings,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      transactionsState: transactionsState ?? this.transactionsState,
      requestPayoutState: requestPayoutState ?? this.requestPayoutState,
      transactionsPaginationData:
          transactionsPaginationData ?? this.transactionsPaginationData,
      updatePayoutSettingState:
          updatePayoutSettingState ?? this.updatePayoutSettingState,
    );
  }

  @override
  List<Object?> get props => [
        earnings,
        settings,
        updatePayoutSettingState,
        paymentMethods,
        transactionsState,
        transactionsPaginationData,
        requestPayoutState,
      ];
}
