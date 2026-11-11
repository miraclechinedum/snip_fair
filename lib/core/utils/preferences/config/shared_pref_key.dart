class SharedPrefKey {
  static const accessToken = 'access-token';
  static const email = 'email';
  static const currentUser = 'current-user';
  static const platformSettings = 'platform-settings';
  static const appConfig = 'app-config';
  static const themeMode = 'theme-mode';

  /// `withdrawal_attempt.v1.<userId>`: a withdrawal attempt whose outcome is
  /// not yet resolved. Kept across logout (see `LocalKeyStorage.clearData`).
  static const pendingWithdrawalPrefix = 'withdrawal_attempt.v1.';

  /// `card_tip_attempts.v1.<customerId>`: card tips whose outcome is not yet
  /// known. Kept across logout, like [pendingWithdrawalPrefix].
  static const cardTipAttemptsPrefix = 'card_tip_attempts.v1.';
}
