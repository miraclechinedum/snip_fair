part of 'app_cubit.dart';

enum AuthStatus {
  initial,
  unAuthenticated,
  authenticated,
}

class AppState extends Equatable {
  const AppState._({
    this.status = AuthStatus.initial,
    this.user = const User(),
  });

  const AppState.initial() : this._();

  const AppState.unAuthenticated() : this._(status: AuthStatus.unAuthenticated);

  const AppState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AppState.updatedUser(User user)
      : this._(user: user, status: AuthStatus.authenticated);

  final AuthStatus status;
  final User user;

  @override
  List<Object> get props => [status, user];
}
