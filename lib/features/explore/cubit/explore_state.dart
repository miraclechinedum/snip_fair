part of 'explore_cubit.dart';

class ExploreState extends Equatable {
  const ExploreState._({
    required this.topRated,
    required this.mostPopular,
    required this.cheapStylists,
    required this.nearByStylists,
    required this.experiencedStylists,
    required this.trendingServices,
  });

  const ExploreState.initial()
      : topRated = const ProcessState.init(null),
        mostPopular = const ProcessState.init(null),
        cheapStylists = const ProcessState.init(null),
        experiencedStylists = const ProcessState.init(null),
        trendingServices = const ProcessState.init(null),
        nearByStylists = const ProcessState.init(null);

  final ProcessState<StylistList> topRated;
  final ProcessState<StylistList> mostPopular;
  final ProcessState<StylistList> cheapStylists;
  final ProcessState<StylistList> nearByStylists;
  final ProcessState<StylistList> experiencedStylists;
  final ProcessState<List<SellerPortfolio>> trendingServices;

  ExploreState copyWith({
    ProcessState<StylistList>? topRated,
    ProcessState<StylistList>? mostPopular,
    ProcessState<StylistList>? cheapStylists,
    ProcessState<StylistList>? nearByStylists,
    ProcessState<StylistList>? experiencedStylists,
    ProcessState<List<SellerPortfolio>>? trendingServices,
  }) {
    return ExploreState._(
      topRated: topRated ?? this.topRated,
      mostPopular: mostPopular ?? this.mostPopular,
      cheapStylists: cheapStylists ?? this.cheapStylists,
      nearByStylists: nearByStylists ?? this.nearByStylists,
      experiencedStylists: experiencedStylists ?? this.experiencedStylists,
      trendingServices: trendingServices ?? this.trendingServices,
    );
  }

  @override
  List<Object> get props => [
        topRated,
        mostPopular,
        cheapStylists,
        nearByStylists,
        experiencedStylists,
        trendingServices,
      ];
}
