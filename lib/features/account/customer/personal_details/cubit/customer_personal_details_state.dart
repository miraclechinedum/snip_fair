part of 'customer_personal_details_cubit.dart';

class CustomerPersonalDetailsState extends BaseState {
  const CustomerPersonalDetailsState._({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    required this.bio,
    required this.updateProfile,
    required this.avatar,
    super.exception,
    super.isLoading,
  });

  const CustomerPersonalDetailsState.initial()
      : this._(
          updateProfile: const ProcessState.init(null),
          firstName: const StringInput.pure(),
          lastName: const StringInput.pure(),
          phone: const PhoneInput.pure(),
          address: const StringInput.pure(),
          bio: const StringInput.pure(),
          avatar: const StringInput.pure(),
        );

  final StringInput firstName;
  final StringInput lastName;
  final PhoneInput phone;
  final StringInput address;
  final StringInput bio;
  final StringInput avatar;
  final ProcessState<bool> updateProfile;

  bool get canSignupAsStylist =>
      Formz.validate([
        firstName,
        lastName,
        phone,
        address,
        bio,
        avatar,
      ]) &&
      !updateProfile.isLoading;

  bool get canSignupAsCustomer =>
      Formz.validate([
        firstName,
        lastName,
        phone,
      ]) &&
      !updateProfile.isLoading;

  @override
  CustomerPersonalDetailsState copyWith({
    StringInput? firstName,
    StringInput? lastName,
    PhoneInput? phone,
    StringInput? businessName,
    StringInput? address,
    StringInput? yearsOfExperience,
    StringInput? bio,
    ProcessState<bool>? updateProfile,
    StringInput? avatar,
    Exception? exception,
    bool? isLoading,
  }) {
    return CustomerPersonalDetailsState._(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      updateProfile: updateProfile ?? this.updateProfile,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phone,
        address,
        bio,
        updateProfile,
        avatar,
        exception,
        isLoading,
      ];
}
