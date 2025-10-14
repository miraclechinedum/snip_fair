part of 'search_cubit.dart';

class SearchState extends Equatable {
  factory SearchState.initial() {
    return const SearchState._(
      stylists: ProcessState.init(null),
      services: ProcessState.init(null),
      searchQuery: '',
      selectedCategory: null,
      categories: ProcessState.init(null),
    );
  }

  const SearchState._({
    required this.stylists,
    required this.services,
    required this.searchQuery,
    required this.categories,
    required this.selectedCategory,
  });
  final ProcessState<StylistList> stylists;
  final ProcessState<List<SellerPortfolio>> services;
  final ProcessState<List<WorkCategory>> categories;
  final WorkCategory? selectedCategory;
  final String searchQuery;

  SearchState copyWith({
    ProcessState<StylistList>? stylists,
    ProcessState<List<SellerPortfolio>>? services,
    String? searchQuery,
    ProcessState<List<WorkCategory>>? categories,
    WorkCategory? selectedCategory,
  }) {
    return SearchState._(
      stylists: stylists ?? this.stylists,
      services: services ?? this.services,
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [
        stylists,
        services,
        searchQuery,
        categories,
        selectedCategory,
      ];
}
