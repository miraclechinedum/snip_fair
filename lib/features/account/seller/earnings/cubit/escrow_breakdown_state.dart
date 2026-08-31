part of 'escrow_breakdown_cubit.dart';

class EscrowBreakdownState extends Equatable {
  factory EscrowBreakdownState.initial() {
    return const EscrowBreakdownState._(
      escrowState: ProcessState.init(null),
    );
  }

  const EscrowBreakdownState._({required this.escrowState});

  final ProcessState<EscrowBreakdown> escrowState;

  @override
  List<Object?> get props => [escrowState];

  EscrowBreakdownState copyWith({
    ProcessState<EscrowBreakdown>? escrowState,
  }) {
    return EscrowBreakdownState._(
      escrowState: escrowState ?? this.escrowState,
    );
  }
}
