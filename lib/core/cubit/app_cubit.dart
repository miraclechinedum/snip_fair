import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart' hide Environment;
import 'package:snip_fair/core/data/datasources/authentication_remote_source.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/user.dart';
import 'package:snip_fair/core/network/api_result.dart';

part 'app_state.dart';

@Injectable()
class AppCubit extends Cubit<AppState> {
  AppCubit(this._remoteSource) : super(const AppState.initial());

  final AuthenticationRemoteSource _remoteSource;

  Future<void> onAppStarted() async {
    await Future.delayed(Duration(seconds: 2));

    emit(const AppState.unAuthenticated());
  }

  Future<void> onLogin() async {}

  void onLogout() {}

  void onUpdateUser() {}
}
