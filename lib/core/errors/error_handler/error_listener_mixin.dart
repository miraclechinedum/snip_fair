// ignore_for_file: always_use_package_imports

import 'package:flutter/material.dart';

import '../../presentation/widgets/dialogs.dart';
import '../../utils/utils.dart';
import '../exception/remote_exception.dart';
import 'local/local_error_listener.dart';
import 'remote/remote_error_listener.dart';

mixin ErrorListenerMixin implements LocalErrorListener, RemoteErrorListener {
  @override
  void onHttpError(BuildContext context, String message) {
    _showErrorAlertDialog(context: context, message: message);
  }

  @override
  void onServerInternalError(BuildContext context, String message) {
    _showErrorAlertDialog(context: context, message: message);
  }

  @override
  void onNetworkError(BuildContext context, String message) {
    _showErrorAlertDialog(context: context, message: message);
  }

  @override
  void onNoInterNetConnectionError(BuildContext context, String message) {
    _showErrorAlertDialog(context: context, message: message);
  }

  @override
  void onSessionExpiredError(BuildContext context, String message) {
    _showErrorAlertDialog(
      context: context,
      message: message,
      onActionPressed: () {},
    );
  }

  @override
  void onServerError(
    BuildContext context,
    RemoteException exception,
  ) {
    _showErrorAlertDialog(
      context: context,
      message:
          exception.errorResponse?.message ?? 'An unexpected error occurred',
    );
  }

  @override
  void onTimeoutError(BuildContext context, String message) {
    _showErrorAlertDialog(context: context, message: message);
  }

  @override
  void onUnexpectedError(BuildContext context, String message) {
    _showErrorAlertDialog(context: context, message: message);
  }

  void _showErrorAlertDialog({
    required BuildContext context,
    required String message,
    VoidCallback? onActionPressed,
  }) {
    AppHelper.showAppDialog<void>(
      context,
      barrierDismissible: true,
      OnFailDialogContent(
        subtext: message,
        onDoneCallback: (ctx) {
          onActionPressed?.call();
        },
      ),
    );
  }

  @override
  void onSharedPreferenceError(BuildContext context, String message) {
    _showErrorAlertDialog(context: context, message: message);
  }

  @override
  void onMappingPreferenceError(BuildContext context, String message) {
    _showErrorAlertDialog(context: context, message: message);
  }
}
