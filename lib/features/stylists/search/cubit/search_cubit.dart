import 'dart:ui';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_list/stylist_list.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio_list.dart';

part 'search_state.dart';

@Injectable()
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._appointmentRepository) : super(SearchState.initial());

  final AppointmentRepository _appointmentRepository;

  final Debounce _debounce = Debounce(milliseconds: 500);

  void search(String query) {
    _debounce.run(() {
      emit(state.copyWith(searchQuery: query));
      _getStylists(query, isInitial: true);
      _getServices(query, isInitial: true);
    });
  }

  void setSortOption(SortOption option) {
    emit(state.copyWith(sortOption: option));
    // _getStylists(state.searchQuery);
  }

  void setPriceRange(PortfolioPriceFilters? range) {
    emit(state.copyWith(priceRange: range));
    // _getStylists(state.searchQuery);
  }

  void toggleHighestRated(bool value) {
    emit(state.copyWith(highestRated: value));
    // _getStylists(state.searchQuery);
  }

  void toggleOnline(bool value) {
    emit(state.copyWith(online: value));
    // _getStylists(state.searchQuery);
  }

  void toggleLowestPriceFlag(bool value) {
    emit(state.copyWith(lowestPriceFlag: value));
    // _getStylists(state.searchQuery);
  }

  void onSelectCategory(WorkCategory? category) {
    emit(state.copyWith(selectedCategory: category));
    _getStylists(state.searchQuery, isInitial: true);
    _getServices(state.searchQuery, isInitial: true);
  }

  Future<void> fetchCategories() async {
    emit(state.copyWith(categories: const ProcessState.loading()));
    final response = await _appointmentRepository.fetchWorkCategories();
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            categories: ProcessState.success(
              data..insert(0, WorkCategory(name: 'All')),
            ),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(categories: ProcessState.error(error)));
      },
    );
  }

  Future<void> _getStylists(String query, {bool isInitial = false}) async {
    if (isInitial) {
      emit(
        state.copyWith(
          stylists: const ProcessState.loading(),
          stylistPagination: const PaginationData(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          stylistPagination: PaginationData(
            isLoadingMore: true,
            nextPageCursor: state.stylistPagination.nextPageCursor,
            hasReachedMax: state.stylistPagination.hasReachedMax,
          ),
        ),
      );
    }
    final response = await _appointmentRepository.customerFetchStylists(
      perPage: '5',
      query: query,
      page: isInitial ? null : state.stylistPagination.nextPageCursor,
      sort: _mapSort(state.sortOption),
      categoryId: state.selectedCategory?.id?.toString(),
      highestRated: state.highestRated ? true : null,
      online: state.online ? true : null,
      lowestPrice: state.lowestPriceFlag ? true : null,
      minPrice: state.priceRange?.min?.toString(),
      maxPrice: state.priceRange?.max?.toString(),
    );
    response.when(
      success: (data) {
        final mergedData = isInitial
            ? data
            : StylistList(
                data: [...?state.stylists.data?.data, ...?data.data],
                nextCursor: data.nextCursor,
                prevCursor: data.prevCursor,
                nextPageUrl: data.nextPageUrl,
                prevPageUrl: data.prevPageUrl,
                perPage: data.perPage,
                path: data.path,
              );
        emit(
          state.copyWith(
            stylists: ProcessState.success(mergedData),
            stylistPagination: PaginationData(
              nextPageCursor: data.nextCursor,
              hasReachedMax: data.nextCursor == null,
            ),
          ),
        );
      },
      failure: (error) {
        if (isInitial) {
          emit(
            state.copyWith(
              stylists: ProcessState.error(error),
              stylistPagination: const PaginationData(),
            ),
          );
        } else {
          emit(
            state.copyWith(
              stylistPagination: PaginationData(
                nextPageCursor: state.stylistPagination.nextPageCursor,
                hasReachedMax: state.stylistPagination.hasReachedMax,
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> loadMoreStylists() async {
    if (state.stylistPagination.isLoadingMore || state.stylistPagination.hasReachedMax) {
      return;
    }
    await _getStylists(state.searchQuery);
  }

  String? _mapSort(SortOption option) {
    switch (option) {
      case SortOption.distance:
        return 'distance';
      case SortOption.lowestPrice:
        return 'price'; // ascending
      case SortOption.highestPrice:
        return '-price'; // descending
      case SortOption.likesCount:
        return '-likes';
      case SortOption.bookingsCount:
        return '-bookings';
    }
  }

  Future<void> _getServices(String query, {bool isInitial = false}) async {
    if (isInitial) {
      emit(
        state.copyWith(
          services: const ProcessState.loading(),
          servicePagination: const PaginationData(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          servicePagination: PaginationData(
            isLoadingMore: true,
            nextPageCursor: state.servicePagination.nextPageCursor,
            hasReachedMax: state.servicePagination.hasReachedMax,
          ),
        ),
      );
    }
    final response = await _appointmentRepository.customerFetchPortfolioList(
      perPage: '5',
      query: query,
      page: isInitial ? null : state.servicePagination.nextPageCursor,
      categoryId: state.selectedCategory?.id?.toString(),
      sort: _mapSort(state.sortOption),
      highestRated: state.highestRated ? true : null,
      online: state.online ? true : null,
      lowestPrice: state.lowestPriceFlag ? true : null,
      minPrice: state.priceRange?.min?.toString(),
      maxPrice: state.priceRange?.max?.toString(),
    );
    response.when(
      success: (data) {
        final mergedData = isInitial
            ? data
            : SellerPortfolioList(
                data: [...?state.services.data?.data, ...?data.data],
                nextCursor: data.nextCursor,
                prevCursor: data.prevCursor,
                nextPageUrl: data.nextPageUrl,
                prevPageUrl: data.prevPageUrl,
                perPage: data.perPage,
                path: data.path,
              );
        emit(
          state.copyWith(
            services: ProcessState.success(mergedData),
            servicePagination: PaginationData(
              nextPageCursor: data.nextCursor,
              hasReachedMax: data.nextCursor == null,
            ),
          ),
        );
      },
      failure: (error) {
        if (isInitial) {
          emit(
            state.copyWith(
              services: ProcessState.error(error),
              servicePagination: const PaginationData(),
            ),
          );
        } else {
          emit(
            state.copyWith(
              servicePagination: PaginationData(
                nextPageCursor: state.servicePagination.nextPageCursor,
                hasReachedMax: state.servicePagination.hasReachedMax,
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> loadMoreServices() async {
    if (state.servicePagination.isLoadingMore || state.servicePagination.hasReachedMax) {
      return;
    }
    await _getServices(state.searchQuery);
  }

  Future<bool?> likePortfolio(String portfolioId) async {
    Fluttertoast.showToast(msg: 'Liking portfolio...');
    final response = await _appointmentRepository.toggleLike(
      type: 'portfolio',
      typeId: portfolioId,
    );
    return response.when(
      success: (data) {
        // Optionally handle success state if needed
        Fluttertoast.showToast(msg: data.message ?? 'Action successful');
        return data.isLiked!;
      },
      failure: (error) {
        // Optionally handle error state if needed
        Fluttertoast.showToast(
          msg: error.errorResponse?.message ?? 'Action failed',
        );
        return null;
      },
    );
  }

  Future<bool?> likeStylist(String stylistId) async {
    Fluttertoast.showToast(msg: 'Toggling stylist...');
    final response = await _appointmentRepository.toggleLike(
      type: 'profile',
      typeId: stylistId,
    );
    return response.when(
      success: (data) {
        // Optionally handle success state if needed
        Fluttertoast.showToast(msg: data.message ?? 'Action successful');
        return data.isLiked!;
      },
      failure: (error) {
        // Optionally handle error state if needed
        Fluttertoast.showToast(
          msg: error.errorResponse?.message ?? 'Action failed',
        );
        return null;
      },
    );
  }
}

class Debounce {
  Debounce({required this.milliseconds});
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  void run(VoidCallback action) {
    if (null != _timer) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
