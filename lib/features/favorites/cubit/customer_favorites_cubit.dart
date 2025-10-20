import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/stylist_list/stylist_list.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'customer_favorites_state.dart';

@Injectable()
class CustomerFavoritesCubit extends Cubit<CustomerFavoritesState> {
  CustomerFavoritesCubit(this._appointmentRepository)
      : super(CustomerFavoritesState.initial());

  final AppointmentRepository _appointmentRepository;

  Future<void> getFavouriteSellers() async {
    emit(
      state.copyWith(
        fetchFavoriteStylistsState: const ProcessState.loading(),
      ),
    );
    final response = await _appointmentRepository.customerFetchStylists(
      perPage: '10',
      favourite: true,
    );
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            fetchFavoriteStylistsState: ProcessState.success(data),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            fetchFavoriteStylistsState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> getFavoriteServices() async {
    emit(
      state.copyWith(
        fetchFavoritePortfoliosState: const ProcessState.loading(),
      ),
    );
    final response = await _appointmentRepository.customerFetchPortfolioList(
      perPage: '10',
      favourite: true,
    );
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            fetchFavoritePortfoliosState: ProcessState.success(data.data ?? []),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            fetchFavoritePortfoliosState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<bool?> likeService(String serviceId) async {
    Fluttertoast.showToast(msg: 'Toggling like...');
    final response = await _appointmentRepository.toggleLike(
      type: 'portfolio',
      typeId: serviceId,
    );
    return response.when(
      success: (data) {
        // Optionally handle success state if needed
        Fluttertoast.showToast(msg: data.message ?? 'Action successful');
        getFavoriteServices();
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
    Fluttertoast.showToast(msg: 'Toggling like...');
    final response = await _appointmentRepository.toggleLike(
      type: 'profile',
      typeId: stylistId,
    );
    return response.when(
      success: (data) {
        // Optionally handle success state if needed
        Fluttertoast.showToast(msg: data.message ?? 'Action successful');
        getFavouriteSellers();
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
