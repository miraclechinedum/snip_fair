import 'package:flutter/material.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/errors/error_handler/error_listener.dart';

abstract class RemoteErrorListener extends ErrorListener {
  void onNoInterNetConnectionError(BuildContext context, String message);

  void onNetworkError(BuildContext context, String message);

  void onHttpError(BuildContext context, String message);

  void onServerInternalError(BuildContext context, String message);

  void onServerError(BuildContext context, RemoteException exception);

  void onTimeoutError(BuildContext context, String message);

  void onSessionExpiredError(BuildContext context, String message);

  void onUnexpectedError(BuildContext context, String message);
}
