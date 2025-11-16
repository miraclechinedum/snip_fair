import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/stylist_list/stylist_list.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'search_state.dart';

@Injectable()
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._appointmentRepository) : super(SearchState.initial());

  final AppointmentRepository _appointmentRepository;

  final Debounce _debounce = Debounce(milliseconds: 500);

  void search(String query) {
    _debounce.run(() {
      emit(state.copyWith(searchQuery: query));
      _getStylists(query);
      // _getServices(query);
    });
  }

  void setSortOption(SortOption option) {
    emit(state.copyWith(sortOption: option));
    // _getStylists(state.searchQuery);
  }

  void setPriceRange(PriceRangeFilter? range) {
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
    _getStylists(state.searchQuery);
    // _getServices(state.searchQuery);
  }

  Future<void> fetchCategories() async {
    emit(state.copyWith(categories: const ProcessState.loading()));
    final response = await _appointmentRepository.fetchWorkCategories();
    response.when(
      success: (data) {
        emit(state.copyWith(
            categories: ProcessState.success(
                data..insert(0, WorkCategory(name: 'All')))));
      },
      failure: (error) {
        emit(state.copyWith(categories: ProcessState.error(error)));
      },
    );
  }

  Future<void> _getStylists(String query) async {
    emit(state.copyWith(stylists: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchStylists(
      perPage: '20',
      query: query,
      sort: _mapSort(state.sortOption),
      categoryId: state.selectedCategory?.id?.toString(),
      highestRated: state.highestRated ? true : null,
      online: state.online ? true : null,
      lowestPrice: state.lowestPriceFlag ? true : null,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
    );
    response.when(
      success: (data) {
        emit(state.copyWith(stylists: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(stylists: ProcessState.error(error)));
      },
    );
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

  Future<void> _getServices(String query) async {
    emit(state.copyWith(services: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchPortfolioList(
      perPage: '20',
      query: query,
      categoryId: state.selectedCategory?.id?.toString(),
    );
    response.when(
      success: (data) {
        emit(state.copyWith(services: ProcessState.success(data.data ?? [])));
      },
      failure: (error) {
        emit(state.copyWith(services: ProcessState.error(error)));
      },
    );
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
