part of 'customer_favorites_cubit.dart';

class CustomerFavoritesState extends Equatable {
  factory CustomerFavoritesState.initial() {
    return const CustomerFavoritesState._(
      fetchFavoritePortfoliosState: ProcessState.init(null),
      fetchFavoriteStylistsState: ProcessState.init(null),
    );
  }

  const CustomerFavoritesState._({
    required this.fetchFavoritePortfoliosState,
    required this.fetchFavoriteStylistsState,
  });

  final ProcessState<List<SellerPortfolio>> fetchFavoritePortfoliosState;
  final ProcessState<StylistList> fetchFavoriteStylistsState;

  @override
  List<Object?> get props => [
        fetchFavoritePortfoliosState,
        fetchFavoriteStylistsState,
      ];

  CustomerFavoritesState copyWith({
    ProcessState<List<SellerPortfolio>>? fetchFavoritePortfoliosState,
    ProcessState<StylistList>? fetchFavoriteStylistsState,
  }) {
    return CustomerFavoritesState._(
      fetchFavoritePortfoliosState:
          fetchFavoritePortfoliosState ?? this.fetchFavoritePortfoliosState,
      fetchFavoriteStylistsState:
          fetchFavoriteStylistsState ?? this.fetchFavoriteStylistsState,
    );
  }
}
