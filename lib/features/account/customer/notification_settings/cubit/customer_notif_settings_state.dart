part of 'customer_notif_settings_cubit.dart';

class CustomerNotifSettingsState extends Equatable {
  const CustomerNotifSettingsState._({
    required this.notificationSettings,
    required this.updateSettingsState,
  });

  const CustomerNotifSettingsState.initial()
      : notificationSettings = null,
        updateSettingsState = const ProcessState.init(null);
  final Notifications? notificationSettings;
  final ProcessState<Object?> updateSettingsState;

  CustomerNotifSettingsState copyWith({
    Notifications? notificationSettings,
    ProcessState<Object?>? updateSettingsState,
  }) {
    return CustomerNotifSettingsState._(
      notificationSettings: notificationSettings ?? this.notificationSettings,
      updateSettingsState: updateSettingsState ?? this.updateSettingsState,
    );
  }

  @override
  List<Object?> get props => [
        notificationSettings,
        updateSettingsState,
      ];
}
