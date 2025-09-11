import 'package:flutter/material.dart';

import '../../exception/local_exception.dart';
import '../error_handler.dart';
import 'local_error_listener.dart';

class LocalErrorHandler
    extends ErrorHandler<LocalException, LocalErrorListener> {
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
        break;
      case LocalExceptionKind.mapper:
        listener.onMappingPreferenceError(
          context,
          'An unexpected error occurred',
        );
        break;
    }
  }
}
