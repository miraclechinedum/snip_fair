part of 'customer_billing_info_cubit.dart';

class CustomerBillingInfoState extends BaseState {
  CustomerBillingInfoState._({
    required this.name,
    required this.email,
    required this.city,
    required this.zipCode,
    required this.location,
    required this.updateBillingInfoState,
    super.exception,
    super.isLoading,
  });

  factory CustomerBillingInfoState.initial() {
    return CustomerBillingInfoState._(
      name: const StringInput.pure(),
      email: const StringInput.pure(),
      city: const StringInput.pure(),
      zipCode: const StringInput.pure(),
      location: const StringInput.pure(),
      updateBillingInfoState: const ProcessState.init(null),
    );
  }

  final StringInput name;
  final StringInput email;
  final StringInput city;
  final StringInput zipCode;
  final StringInput location;
  final ProcessState<Object?> updateBillingInfoState;

  bool get canSubmit => Formz.validate([
        name,
        email,
        city,
        zipCode,
        location,
      ]);

  @override
  CustomerBillingInfoState copyWith({
    StringInput? name,
    StringInput? email,
    StringInput? city,
    StringInput? zipCode,
    StringInput? location,
    ProcessState<Object?>? updateBillingInfoState,
    Exception? exception,
    bool? isLoading,
  }) {
    return CustomerBillingInfoState._(
      name: name ?? this.name,
      email: email ?? this.email,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      location: location ?? this.location,
      updateBillingInfoState:
          updateBillingInfoState ?? this.updateBillingInfoState,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props {
    return [
      name,
      email,
      city,
      zipCode,
      location,
      updateBillingInfoState,
      exception,
      isLoading,
    ];
  }
}
