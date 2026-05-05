import 'package:flutter/material.dart';
import 'package:snip_fair/core/errors/exception/local_exception.dart';
import 'package:snip_fair/core/errors/error_handler/error_handler.dart';
import 'package:snip_fair/core/errors/error_handler/local/local_error_listener.dart';

class LocalErrorHandler extends ErrorHandler<LocalException, LocalErrorListener> {
  @override
  void proceed(
    BuildContext context,
    LocalException exception,
    LocalErrorListener listener,
  ) {
    switch (exception.kind) {
      case LocalExceptionKind.sharedPreference:
        listener.onSharedPreferenceError(
          context,
          'An unexpected error occurred',
        );
      case LocalExceptionKind.mapper:
        listener.onMappingPreferenceError(
          context,
          'An unexpected error occurred',
        );
    }
  }
}
