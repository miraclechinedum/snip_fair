// ignore_for_file: always_use_package_imports

import 'package:bloc/bloc.dart';
import 'package:logger/logger.dart';

import '../../network/handlers.dart';
import 'base_state.dart';

abstract class BaseCubit<S extends BaseState> extends Cubit<S> {
  BaseCubit(super.initialState);

  final logger = Logger();

  Future<void> launchUseCase<T>(
    Future<T> Function() futureUseCase, {
    bool showError = true,
    bool showLoading = false,
    void Function()? doOnLoading,
    void Function(T)? doOnSuccess,
    void Function(Object)? doOnError,
  }) async {
    if (!isClosed) doOnLoading?.call();
    if (showLoading && !isClosed) {
      emit(state.copyWith(isLoading: true) as S);
    }

    try {
      final data = await futureUseCase.call();
      if (!isClosed) doOnSuccess?.call(data);
    } catch (e, stack) {
      logger.e(e, stackTrace: stack);
      if (!isClosed) doOnError?.call(e);
      if (showError && !isClosed) {
        if (e is Exception) {
          emit(state.copyWith(exception: e) as S);
        }
      }
    } finally {
      if (showLoading && !isClosed) {
        emit(state.copyWith(isLoading: false) as S);
      }
    }
  }

  Future<void> launchApiCall<T>(
    Future<ApiResult<T>> Function() future, {
    bool showError = true,
    bool showLoading = false,
    void Function()? doOnLoading,
    void Function(T)? doOnSuccess,
    void Function(Object)? doOnError,
  }) async {
    if (!isClosed) doOnLoading?.call();
    if (showLoading && !isClosed) {
      emit(state.copyWith(isLoading: true) as S);
    }
    final data = await future.call();
    switch (data) {
      case Success<T>(data: final data):
        {
          if (!isClosed) doOnSuccess?.call(data);
          if (showLoading && !isClosed) {
            emit(state.copyWith(isLoading: false) as S);
          }
        }
      case Failure<T>(error: final error):
        {
          if (!isClosed) doOnError?.call(error);
          if (showError && !isClosed) {
            emit(state.copyWith(exception: error) as S);
          }
          if (showLoading && !isClosed) {
            emit(state.copyWith(isLoading: false) as S);
          }
        }
    }
  }
}
