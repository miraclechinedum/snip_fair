import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/stylist_list/stylist_list.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'explore_state.dart';

@Injectable()
class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit(this._appointmentRepository)
      : super(const ExploreState.initial());

  final AppointmentRepository _appointmentRepository;

  Future<void> getTopRatedSellers() async {
    emit(state.copyWith(topRated: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchStylists(
      perPage: '10',
      sort: '-average_rating',
    );
    response.when(
      success: (data) {
        emit(state.copyWith(topRated: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(topRated: ProcessState.error(error)));
      },
    );
  }

  Future<void> getMostPopularSellers() async {
    emit(state.copyWith(mostPopular: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchStylists(
      perPage: '10',
      sort: '-favourite',
    );
    response.when(
      success: (data) {
        emit(state.copyWith(mostPopular: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(mostPopular: ProcessState.error(error)));
      },
    );
  }

  Future<void> getNearbySellers() async {
    emit(state.copyWith(nearByStylists: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchStylists(
      perPage: '10',
      sort: '+distance',
    );
    response.when(
      success: (data) {
        emit(state.copyWith(nearByStylists: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(nearByStylists: ProcessState.error(error)));
      },
    );
  }

  Future<void> getCheapSellers() async {
    emit(state.copyWith(cheapStylists: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchStylists(
      perPage: '10',
      sort: '-max_price',
    );
    response.when(
      success: (data) {
        emit(state.copyWith(cheapStylists: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(cheapStylists: ProcessState.error(error)));
      },
    );
  }

  Future<void> getExperiencedSellers() async {
    emit(state.copyWith(experiencedStylists: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchStylists(
      perPage: '10',
      sort: '-available',
    );
    response.when(
      success: (data) {
        emit(state.copyWith(experiencedStylists: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(experiencedStylists: ProcessState.error(error)));
      },
    );
  }

  Future<void> getTrendingServices() async {
    emit(state.copyWith(trendingServices: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchPortfolioList(
      sort: '-trending',
      perPage: '10',
    );
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            trendingServices: ProcessState.success(data.data ?? []),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(trendingServices: ProcessState.error(error)));
      },
    );
  }

  Future<bool?> likePortfolio(String portfolioId) async {
    Fluttertoast.showToast(msg: 'Toggling like...');
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
