part of 'app_cubit.dart';

enum AuthStatus {
  unknown,
  unAuthenticated,
  authenticated,
}

class AppState extends Equatable {
  const AppState._({
    this.status = AuthStatus.unknown,
    this.user = const User(),
    this.role = '',
  });

  const AppState.initial() : this._();

  const AppState.unAuthenticated()
      : this._(
          status: AuthStatus.unAuthenticated,
          user: const User(),
          role: '',
        );

  const AppState.authenticated({required String role, required User user})
      : this._(status: AuthStatus.authenticated, user: user, role: role);

  const AppState.updatedUser({required String role, required User user})
      : this._(user: user, status: AuthStatus.authenticated, role: role);

  final AuthStatus status;
  final User user;
  final String role;

  bool get isCustomer => role == 'customer';
  bool get isStylist => role == 'stylist';

  @override
  List<Object> get props => [status, user, role];
}
