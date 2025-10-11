part of 'seller_profile_mgt_cubit.dart';

class SellerProfileMgtState extends Equatable {
  SellerProfileMgtState._({
    required this.profileDetails,
    required this.updateProfileState,
    required this.stylistEarnings,
    required this.stylistStats,
    required this.updateAvatarState,
    required this.updateBannerState,
  });

  SellerProfileMgtState.initial()
      : profileDetails = const ProcessState.init(null),
        updateProfileState = const ProcessState.init(null),
        updateAvatarState = const ProcessState.init(null),
        updateBannerState = const ProcessState.init(null),
        stylistStats = const ProcessState.init(null),
        stylistEarnings = const ProcessState.init(null);

  final ProcessState<StylistProfileDetails> profileDetails;
  final ProcessState<bool> updateProfileState;
  final ProcessState<StylistEarnings> stylistEarnings;
  final ProcessState<StylistStats> stylistStats;
  final ProcessState<bool> updateAvatarState;
  final ProcessState<bool> updateBannerState;

  SellerProfileMgtState copyWith({
    ProcessState<StylistProfileDetails>? profileDetails,
    ProcessState<bool>? updateProfileState,
    ProcessState<bool>? updateAvatarState,
    ProcessState<bool>? updateBannerState,
    ProcessState<StylistStats>? stylistStats,
    ProcessState<StylistEarnings>? stylistEarnings,
  }) {
    return SellerProfileMgtState._(
      profileDetails: profileDetails ?? this.profileDetails,
      updateProfileState: updateProfileState ?? this.updateProfileState,
      updateAvatarState: updateAvatarState ?? this.updateAvatarState,
      updateBannerState: updateBannerState ?? this.updateBannerState,
      stylistStats: stylistStats ?? this.stylistStats,
      stylistEarnings: stylistEarnings ?? this.stylistEarnings,
    );
  }

  @override
  List<Object> get props => [
        profileDetails,
        updateProfileState,
        stylistEarnings,
        updateAvatarState,
        stylistStats,
        updateBannerState,
      ];
}
