part of 'disputes_cubit.dart';

class DisputesState extends Equatable {
  const DisputesState._({
    this.disputes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DisputesState.initial() : this._();

  final List<Dispute> disputes;
  final bool isLoading;
  final String? errorMessage;

  DisputesState copyWith({
    List<Dispute>? disputes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DisputesState._(
      disputes: disputes ?? this.disputes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [disputes, isLoading, errorMessage];
}
