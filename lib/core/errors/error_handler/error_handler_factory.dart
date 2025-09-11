import 'package:flutter/material.dart';

import '../exception/local_exception.dart';
import '../exception/remote_exception.dart';
import 'error_listener.dart';
import 'local/local_error_handler.dart';
import 'local/local_error_listener.dart';
import 'remote/remote_error_handler.dart';
import 'remote/remote_error_listener.dart';

class ErrorHandlerFactory {
  ErrorHandlerFactory._();

  static void handleErrorByType(
    BuildContext context,
    Object error,
    ErrorListener listener,
  ) {
    if (error is RemoteException) {
      return RemoteErrorHandler().proceed(
        context,
        error,
        listener as RemoteErrorListener,
      );
    }

    // database error

    // local error
    if (error is LocalException) {
      return LocalErrorHandler().proceed(
        context,
        error,
        listener as LocalErrorListener,
      );
    }

    throw 'Uncaught Exception: ${error.runtimeType}';
  }
}
