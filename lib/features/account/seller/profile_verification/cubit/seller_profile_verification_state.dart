part of 'seller_profile_verification_cubit.dart';

class SellerProfileVerificationState extends Equatable {
  const SellerProfileVerificationState._({
    required this.businessName,
    required this.pastWorksFilePaths,
    required this.socials,
    required this.socialApp,
    required this.socialLink,
    required this.submitState,
    required this.portfolios,
    required this.initialWorks,
    required this.initialSocials,
    this.editingSocialIndex,
  });

  SellerProfileVerificationState.initial(StylistProfileDetails profile)
      : businessName = profile.user?.stylistProfile?.businessName != null
            ? StringInput.dirty(profile.user!.stylistProfile!.businessName!)
            : const StringInput.pure(),
        pastWorksFilePaths = profile.user?.stylistProfile?.works ?? [],
        initialWorks = List.unmodifiable(
          profile.user?.stylistProfile?.works ?? const <String>[],
        ),
        initialSocials = List.unmodifiable(
          profile.user?.stylistProfile?.socials ?? const <Social>[],
        ),
        editingSocialIndex = null,
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

  /// The work images loaded from the profile. While [pastWorksFilePaths]
  /// still equals this, a save omits `media` so the backend keeps them.
  final List<String> initialWorks;

  /// The social links loaded from the profile.
  final List<Social> initialSocials;

  /// Whether the links differ from the saved ones (app name or URL).
  bool get socialsChanged {
    if (socials.length != initialSocials.length) return true;
    for (var i = 0; i < socials.length; i++) {
      if (socials[i].socialApp != initialSocials[i].socialApp ||
          socials[i].url != initialSocials[i].url) {
        return true;
      }
    }
    return false;
  }

  /// Approved stylists can update their links on their own. At least one is
  /// kept: with none, the backend makes the account unavailable.
  bool get canSaveSocialLinks =>
      socialsChanged && socials.isNotEmpty && !submitState.isLoading;

  /// The social link being edited, or null when adding a new one.
  final int? editingSocialIndex;

  /// The backend's message for a link that is not a full https URL.
  String? get socialLinkUrlError =>
      socialLink.value.trim().isNotEmpty &&
              !SocialLinks.isValidProfileUrl(socialLink.value)
          ? SocialLinks.invalidUrlMessage
          : null;

  bool get canAddSocial =>
      Formz.validate([socialApp, socialLink]) &&
      socialApp.value.trim().isNotEmpty &&
      SocialLinks.isValidProfileUrl(socialLink.value);

  /// Whether the work images differ from what the profile already has.
  bool get worksChanged {
    if (pastWorksFilePaths.length != initialWorks.length) return true;
    for (var i = 0; i < initialWorks.length; i++) {
      if (pastWorksFilePaths[i] != initialWorks[i]) return true;
    }
    return false;
  }

  bool get canSubmitRequirements =>
      Formz.validate([businessName]) && pastWorksFilePaths.isNotEmpty && socials.isNotEmpty;

  SellerProfileVerificationState copyWith({
    StringInput? businessName,
    List<String>? pastWorksFilePaths,
    List<Social>? socials,
    List<Portfolio>? portfolios,
    StringInput? socialApp,
    StringInput? socialLink,
    ProcessState<bool>? submitState,
    int? Function()? editingSocialIndex,
  }) {
    return SellerProfileVerificationState._(
      businessName: businessName ?? this.businessName,
      pastWorksFilePaths: pastWorksFilePaths ?? this.pastWorksFilePaths,
      socials: socials ?? this.socials,
      portfolios: portfolios ?? this.portfolios,
      socialApp: socialApp ?? this.socialApp,
      socialLink: socialLink ?? this.socialLink,
      submitState: submitState ?? this.submitState,
      initialWorks: initialWorks,
      initialSocials: initialSocials,
      editingSocialIndex: editingSocialIndex != null
          ? editingSocialIndex()
          : this.editingSocialIndex,
    );
  }

  @override
  List<Object?> get props {
    return [
      businessName,
      pastWorksFilePaths,
      socials,
      socialApp,
      socialLink,
      submitState,
      portfolios,
      initialWorks,
      initialSocials,
      editingSocialIndex,
    ];
  }
}
