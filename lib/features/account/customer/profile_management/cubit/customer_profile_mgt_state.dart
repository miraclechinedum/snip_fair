part of 'customer_profile_mgt_cubit.dart';

class CustomerProfileMgtState extends Equatable {
  const CustomerProfileMgtState._({
    required this.profileDetails,
    required this.customerStats,
    required this.walletState,
    required this.transactionsState,
    required this.initializePaymentState,
    required this.transactionsPaginationData,
    required this.updateAvatarState,
  });

  const CustomerProfileMgtState.initial()
      : profileDetails = const ProcessState.init(null),
        customerStats = const ProcessState.init(null),
        walletState = const ProcessState.init(null),
        transactionsState = const ProcessState.init(null),
        transactionsPaginationData = const PaginationData(),
        updateAvatarState = const ProcessState.init(null),
        initializePaymentState = const ProcessState.init(null);

  final ProcessState<CustomerProfileDetails> profileDetails;
  final ProcessState<CustomerStats> customerStats;
  final ProcessState<CustomerWallet> walletState;
  final ProcessState<List<CustomerTransaction>> transactionsState;
  final ProcessState<PayfastPaymentData> initializePaymentState;
  final ProcessState<bool> updateAvatarState;

  final PaginationData transactionsPaginationData;

  CustomerProfileMgtState copyWith({
    ProcessState<CustomerProfileDetails>? profileDetails,
    ProcessState<CustomerStats>? customerStats,
    ProcessState<CustomerWallet>? walletState,
    ProcessState<List<CustomerTransaction>>? transactionsState,
    ProcessState<PayfastPaymentData>? initializePaymentState,
    PaginationData? transactionsPaginationData,
    ProcessState<bool>? updateAvatarState,
  }) {
    return CustomerProfileMgtState._(
      profileDetails: profileDetails ?? this.profileDetails,
      customerStats: customerStats ?? this.customerStats,
      walletState: walletState ?? this.walletState,
      transactionsState: transactionsState ?? this.transactionsState,
      initializePaymentState:
          initializePaymentState ?? this.initializePaymentState,
      transactionsPaginationData:
          transactionsPaginationData ?? this.transactionsPaginationData,
      updateAvatarState: updateAvatarState ?? this.updateAvatarState,
    );
  }

  @override
  List<Object> get props => [
        profileDetails,
        customerStats,
        walletState,
        transactionsState,
        initializePaymentState,
        transactionsPaginationData,
        updateAvatarState,
      ];
}
