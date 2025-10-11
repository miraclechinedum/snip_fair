part of 'seller_payment_methods_cubit.dart';

class SellerPaymentMethodsState extends Equatable {
  const SellerPaymentMethodsState._({
    required this.paymentMethods,
    required this.banks,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.branchName,
    required this.addPaymentMethodState,
    required this.selectedBank,
    required this.updatePaymentMethodState,
  });

  const SellerPaymentMethodsState.initial()
      : paymentMethods = const ProcessState.init(null),
        accountName = const StringInput.pure(),
        accountNumber = const StringInput.pure(),
        bankName = const StringInput.pure(),
        branchName = const StringInput.pure(),
        banks = const ProcessState.init(null),
        selectedBank = null,
        updatePaymentMethodState = const ProcessState.init(null),
        addPaymentMethodState = const ProcessState.init(null);

  final ProcessState<List<PaymentMethod>> paymentMethods;
  final ProcessState<List<Bank>> banks;

  /// Create
  final StringInput accountName;
  final StringInput accountNumber;
  final StringInput bankName;
  final StringInput branchName;
  final Bank? selectedBank;
  final ProcessState<bool> addPaymentMethodState;
  final ProcessState<bool> updatePaymentMethodState;

  bool get canSubmit =>
      Formz.validate([accountName, accountNumber]) &&
      selectedBank != null &&
      !addPaymentMethodState.isLoading;

  SellerPaymentMethodsState copyWith({
    ProcessState<List<PaymentMethod>>? paymentMethods,
    ProcessState<List<Bank>>? banks,
    StringInput? accountName,
    StringInput? accountNumber,
    StringInput? bankName,
    StringInput? branchName,
    Bank? selectedBank,
    ProcessState<bool>? addPaymentMethodState,
    ProcessState<bool>? updatePaymentMethodState,
  }) {
    return SellerPaymentMethodsState._(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedBank: selectedBank ?? this.selectedBank,
      banks: banks ?? this.banks,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      addPaymentMethodState:
          addPaymentMethodState ?? this.addPaymentMethodState,
      updatePaymentMethodState:
          updatePaymentMethodState ?? this.updatePaymentMethodState,
    );
  }

  @override
  List<Object?> get props {
    return [
      paymentMethods,
      banks,
      accountName,
      accountNumber,
      bankName,
      branchName,
      addPaymentMethodState,
      selectedBank,
      updatePaymentMethodState,
    ];
  }
}
