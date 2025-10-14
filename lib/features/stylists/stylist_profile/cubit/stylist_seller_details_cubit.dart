import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio_list.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

part 'stylist_seller_details_state.dart';

@Injectable()
class StylistSellerDetailsCubit extends Cubit<StylistSellerDetailsState> {
  StylistSellerDetailsCubit(this._appointmentRepository)
      : super(StylistSellerDetailsState.initial());

  final AppointmentRepository _appointmentRepository;

  void init({String? id, SellerDetails? seller}) {
    if (id != null) {
      _getSellerProfileById(id);
    } else if (seller != null) {
      _getSellerProfileById(seller.id!.toString());
    }
  }

  Future<void> _getSellerProfileById(String id) async {
    emit(state.copyWith(sellerDetails: const ProcessState.loading()));
    final response = await _appointmentRepository.customerFetchStylistById(id);
    response.when(
      success: (data) {
        emit(state.copyWith(sellerDetails: ProcessState.success(data)));
        _getPortfolios();
      },
      failure: (error) {
        emit(state.copyWith(sellerDetails: ProcessState.error(error)));
      },
    );
  }

  Future<void> _getPortfolios() async {
    emit(state.copyWith(sellePortfolio: const ProcessState.loading()));
    final stylistId = state.sellerDetails.data?.id;
    final response = await _appointmentRepository.customerFetchPortfolioList(
      stylistId: stylistId?.toString(),
    );
    response.when(
      success: (data) {
        emit(state.copyWith(sellePortfolio: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(sellePortfolio: ProcessState.error(error)));
      },
    );
  }

  Future<bool> likeStylist(String stylistId) async {
    Fluttertoast.showToast(msg: 'Liking stylist...');
    final response = await _appointmentRepository.toggleLike(
      type: 'profile',
      typeId: stylistId,
    );
    return response.when(
      success: (data) {
        // Optionally handle success state if needed
        Fluttertoast.showToast(msg: data.message ?? 'Action successful');
        return true;
      },
      failure: (error) {
        // Optionally handle error state if needed
        Fluttertoast.showToast(
          msg: error.errorResponse?.message ?? 'Action failed',
        );
        return false;
      },
    );
  }
}
