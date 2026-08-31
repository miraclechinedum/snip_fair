import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_escrow/escrow_breakdown.dart';

part 'escrow_breakdown_state.dart';

/// Not @Injectable — the DI container is build_runner-generated and we avoid
/// regenerating it. The screen constructs this directly via
/// `EscrowBreakdownCubit(getIt<ProfileRepository>())`.
class EscrowBreakdownCubit extends Cubit<EscrowBreakdownState> {
  EscrowBreakdownCubit(this._profileRepository)
      : super(EscrowBreakdownState.initial());

  final ProfileRepository _profileRepository;

  Future<void> fetch() async {
    emit(
      state.copyWith(
        escrowState: const ProcessState<EscrowBreakdown>.loading(),
      ),
    );
    final result = await _profileRepository.getStylistEscrowBreakdown();
    result.when(
      success: (data) =>
          emit(state.copyWith(escrowState: ProcessState.success(data))),
      failure: (error) => emit(
        state.copyWith(
          escrowState: ProcessState<EscrowBreakdown>.error(error),
        ),
      ),
    );
  }
}
