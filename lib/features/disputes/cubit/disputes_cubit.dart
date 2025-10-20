import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/dispute_list/dispute.dart';
import 'package:snip_fair/core/network/api_result.dart';

part 'disputes_state.dart';

@Injectable()
class DisputesCubit extends Cubit<DisputesState> {
  DisputesCubit(this._profileRepository) : super(DisputesState.initial());

  final ProfileRepository _profileRepository;

  Future<void> fetchDisputes() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _profileRepository.getDisputes();
    result.when(
      success: (data) {
        emit(state.copyWith(
          disputes: data.data ?? [],
          isLoading: false,
        ));
      },
      failure: (error) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage:
              error.errorResponse?.message ?? 'An unknown error occurred',
        ));
      },
    );
  }
}
