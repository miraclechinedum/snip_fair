part of 'earnings_cubit.dart';

class EarningsState extends Equatable {
  const EarningsState._({
    required this.earnings,
    required this.settings,
    required this.updatePayoutSettingState,
  });

  const EarningsState.initial()
      : earnings = const ProcessState.init(null),
        updatePayoutSettingState = const ProcessState.init(null),
        settings = null;

  final ProcessState<StylistEarnings> earnings;
  final Settings? settings;
  final ProcessState<bool> updatePayoutSettingState;

  EarningsState copyWith({
    ProcessState<StylistEarnings>? earnings,
    Settings? settings,
    ProcessState<bool>? updatePayoutSettingState,
  }) {
    return EarningsState._(
      earnings: earnings ?? this.earnings,
      settings: settings ?? this.settings,
      updatePayoutSettingState:
          updatePayoutSettingState ?? this.updatePayoutSettingState,
    );
  }

  @override
  List<Object?> get props => [
        earnings,
        settings,
        updatePayoutSettingState,
      ];
}
