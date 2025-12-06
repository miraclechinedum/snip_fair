part of 'search_cubit.dart';

enum SortOption {
  distance,
  lowestPrice,
  highestPrice,
  likesCount,
  bookingsCount,
}

enum PriceRangeFilter {
  all,
  below50,
  from50To100,
  from101To150,
  from150To200,
  above200,
}

class SearchState extends Equatable {
  factory SearchState.initial() {
    return const SearchState._(
      stylists: ProcessState.init(null),
      services: ProcessState.init(null),
      searchQuery: '',
      selectedCategory: null,
      categories: ProcessState.init(null),
      sortOption: SortOption.distance,
      highestRated: false,
      online: false,
      lowestPriceFlag: false,
      priceRange: null,
      stylistPagination: PaginationData(),
      servicePagination: PaginationData(),
    );
  }

  const SearchState._({
    required this.stylists,
    required this.services,
    required this.searchQuery,
    required this.categories,
    required this.selectedCategory,
    required this.sortOption,
    required this.highestRated,
    required this.online,
    required this.lowestPriceFlag,
    required this.priceRange,
    required this.stylistPagination,
    required this.servicePagination,
  });
  final ProcessState<StylistList> stylists;
  final PaginationData stylistPagination;
  final ProcessState<SellerPortfolioList> services;
  final PaginationData servicePagination;
  final ProcessState<List<WorkCategory>> categories;
  final WorkCategory? selectedCategory;
  final String searchQuery;
  final SortOption sortOption;
  final bool highestRated;
  final bool online;
  final bool lowestPriceFlag;
  final PortfolioPriceFilters? priceRange;

  // String? get minPrice => switch (priceRange) {
  //       PriceRangeFilter.below50 => '0',
  //       PriceRangeFilter.from50To100 => '50',
  //       PriceRangeFilter.from101To150 => '101',
  //       PriceRangeFilter.from150To200 => '150',
  //       PriceRangeFilter.above200 => '200',
  //       PriceRangeFilter.all => null,
  //       null => null,
  //     };

  // String? get maxPrice => switch (priceRange) {
  //       PriceRangeFilter.below50 => '49',
  //       PriceRangeFilter.from50To100 => '100',
  //       PriceRangeFilter.from101To150 => '150',
  //       PriceRangeFilter.from150To200 => '200',
  //       PriceRangeFilter.above200 => null,
  //       PriceRangeFilter.all => null,
  //       null => null,
  //     };

  SearchState copyWith({
    ProcessState<StylistList>? stylists,
    ProcessState<SellerPortfolioList>? services,
    String? searchQuery,
    ProcessState<List<WorkCategory>>? categories,
    WorkCategory? selectedCategory,
    SortOption? sortOption,
    bool? highestRated,
    bool? online,
    bool? lowestPriceFlag,
    PortfolioPriceFilters? priceRange,
    PaginationData? stylistPagination,
    PaginationData? servicePagination,
  }) {
    return SearchState._(
      stylists: stylists ?? this.stylists,
      services: services ?? this.services,
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortOption: sortOption ?? this.sortOption,
      highestRated: highestRated ?? this.highestRated,
      online: online ?? this.online,
      lowestPriceFlag: lowestPriceFlag ?? this.lowestPriceFlag,
      priceRange: priceRange ?? this.priceRange,
      stylistPagination: stylistPagination ?? this.stylistPagination,
      servicePagination: servicePagination ?? this.servicePagination,
    );
  }

  @override
  List<Object?> get props => [
        stylists,
        services,
        searchQuery,
        categories,
        selectedCategory,
        sortOption,
        highestRated,
        online,
        lowestPriceFlag,
        priceRange,
        stylistPagination,
        servicePagination,
      ];
}
