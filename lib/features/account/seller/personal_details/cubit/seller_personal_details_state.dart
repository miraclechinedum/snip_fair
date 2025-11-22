part of 'seller_personal_details_cubit.dart';

class SellerPersonalDetailsState extends BaseState {
  const SellerPersonalDetailsState._({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.gender,
    required this.businessName,
    required this.address,
    required this.yearsOfExperience,
    required this.bio,
    required this.updateProfile,
    super.exception,
    super.isLoading,
  });

  const SellerPersonalDetailsState.initial()
      : this._(
          updateProfile: const ProcessState.init(null),
          firstName: const StringInput.pure(),
          lastName: const StringInput.pure(),
          phone: const PhoneInput.pure(),
          gender: const StringInput.pure(),
          businessName: const StringInput.pure(),
          address: const StringInput.pure(),
          yearsOfExperience: const StringInput.pure(),
          bio: const StringInput.pure(),
        );

  final StringInput firstName;
  final StringInput lastName;
  final StringInput gender;
  final PhoneInput phone;
  final StringInput businessName;
  final StringInput address;
  final StringInput yearsOfExperience;
  final StringInput bio;
  final ProcessState<bool> updateProfile;

  bool get canSignupAsStylist =>
      Formz.validate([
        firstName,
        lastName,
        phone,
        businessName,
        address,
        yearsOfExperience,
        gender,
        bio,
      ]) &&
      !updateProfile.isLoading;

  bool get canSignupAsCustomer =>
      Formz.validate([
        firstName,
        lastName,
        gender,
        phone,
      ]) &&
      !updateProfile.isLoading;

  @override
  SellerPersonalDetailsState copyWith({
    StringInput? firstName,
    StringInput? lastName,
    PhoneInput? phone,
    StringInput? businessName,
    StringInput? address,
    StringInput? yearsOfExperience,
    StringInput? bio,
    ProcessState<bool>? updateProfile,
    StringInput? gender,
    Exception? exception,
    bool? isLoading,
  }) {
    return SellerPersonalDetailsState._(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      updateProfile: updateProfile ?? this.updateProfile,
      gender: gender ?? this.gender,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phone,
        businessName,
        address,
        yearsOfExperience,
        bio,
        gender,
        updateProfile,
        exception,
        isLoading,
      ];
}
