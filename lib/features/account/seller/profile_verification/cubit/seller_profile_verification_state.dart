part of 'seller_profile_verification_cubit.dart';

class SellerProfileVerificationState extends Equatable {
  SellerProfileVerificationState._({
    required this.businessName,
    required this.pastWorksFilePaths,
    required this.socials,
    required this.socialApp,
    required this.socialLink,
    required this.submitState,
    required this.portfolios,
  });

  SellerProfileVerificationState.initial(StylistProfileDetails profile)
      : businessName = profile.user?.stylistProfile?.businessName != null
            ? StringInput.dirty(profile.user!.stylistProfile!.businessName!)
            : const StringInput.pure(),
        pastWorksFilePaths = profile.user?.stylistProfile?.works ?? [],
        portfolios = profile.portfolios ?? [],
        socials = profile.user?.stylistProfile?.socials ?? [],
        socialApp = const StringInput.pure(),
        socialLink = const StringInput.pure(),
        submitState = const ProcessState.init(null);

  final StringInput businessName;
  final List<String> pastWorksFilePaths;
  final List<Social> socials;
  final List<Portfolio> portfolios;
  final StringInput socialApp;
  final StringInput socialLink;
  final ProcessState<bool> submitState;

  bool get canAddSocial => Formz.validate([socialApp, socialLink]);

  bool get canSubmitRequirements =>
      Formz.validate([businessName]) &&
      pastWorksFilePaths.isNotEmpty &&
      socials.isNotEmpty;

  SellerProfileVerificationState copyWith({
    StringInput? businessName,
    List<String>? pastWorksFilePaths,
    List<Social>? socials,
    List<Portfolio>? portfolios,
    StringInput? socialApp,
    StringInput? socialLink,
    ProcessState<bool>? submitState,
  }) {
    return SellerProfileVerificationState._(
      businessName: businessName ?? this.businessName,
      pastWorksFilePaths: pastWorksFilePaths ?? this.pastWorksFilePaths,
      socials: socials ?? this.socials,
      portfolios: portfolios ?? this.portfolios,
      socialApp: socialApp ?? this.socialApp,
      socialLink: socialLink ?? this.socialLink,
      submitState: submitState ?? this.submitState,
    );
  }

  @override
  List<Object> get props {
    return [
      businessName,
      pastWorksFilePaths,
      socials,
      socialApp,
      socialLink,
      submitState,
      portfolios,
    ];
  }
}
