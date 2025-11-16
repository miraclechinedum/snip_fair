part of 'customer_prefs_settings_cubit.dart';

enum ServiceTime {
  morning('Morning (8 - 12PM)'),
  afternoon('Afternoon (12 - 4PM)'),
  evening('Evening (4 - 8PM)'),
  special('Special Booking'),
  none('No Preference');

  final String displayName;

  const ServiceTime(this.displayName);
}

enum StylistGender {
  male('Male'),
  female('Female'),
  noPreference('No Preference');

  final String displayName;
  const StylistGender(this.displayName);
}

enum PreferredLanguage { english, spanish, french }

enum PreferredCurrency {
  usd('\$'),
  eur('€'),
  gbp('£'),
  zar('R');

  final String symbol;
  const PreferredCurrency(this.symbol);
}

class CustomerPrefsSettingsState extends Equatable {
  const CustomerPrefsSettingsState._({
    required this.preferences,
    required this.updatePrefsState,
  });

  factory CustomerPrefsSettingsState.initial() {
    return const CustomerPrefsSettingsState._(
      preferences: null,
      updatePrefsState: ProcessState.init(null),
    );
  }
  final Preferences? preferences;
  final ProcessState<Object?> updatePrefsState;

  CustomerPrefsSettingsState copyWith({
    Preferences? preferences,
    ProcessState<Object?>? updatePrefsState,
  }) {
    return CustomerPrefsSettingsState._(
      preferences: preferences ?? this.preferences,
      updatePrefsState: updatePrefsState ?? this.updatePrefsState,
    );
  }

  @override
  List<Object?> get props => [
        preferences,
        updatePrefsState,
      ];
}
