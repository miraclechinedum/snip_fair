import 'package:flutter/material.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';

/// Account closure. Snipfair never deletes an account outright: the app
/// asks Snipfair to close the account and erase personal data
/// (POST /api/user/privacy-requests). Snipfair verifies and decides it;
/// nothing changes and the user stays signed in until then. Payment,
/// wallet and payout records are kept by law. The app never claims that
/// an account was deleted.
abstract final class AccountClosure {
  static const heading = 'Close account and erase personal data';

  static const description = 'You can ask Snipfair to close your account '
      'and erase your personal data (profile, photos, identity documents, '
      'contact details and saved bank details). Payment, wallet and payout '
      'records must be kept by law, restricted, for up to 7 years. Any '
      'wallet balance, pending payout or open booking is settled first. '
      'Snipfair verifies that the request is yours and tells you the '
      'outcome in writing within 30 days. Your account stays active until '
      'then.';

  static const confirmTitle = 'Request account closure';

  static const confirmContent = 'Send a request to close your account and '
      'erase your personal data? Nothing changes until Snipfair has '
      'verified and approved it.';

  static const buttonLabel = 'REQUEST ACCOUNT CLOSURE';

  static const submitted = 'Your request to close your account and erase '
      'your personal data has been received. Snipfair will verify it and '
      'tell you the outcome in writing within 30 days. Payment, wallet and '
      'payout records are kept by law. Your account stays active until '
      'then.';

  static const _fallback = 'Your request could not be sent. Please try '
      'again, or contact support@snipfair.com.';

  /// The server's explanation when it has one, otherwise a safe fallback.
  static String errorMessage(Object? error) {
    if (error is RemoteException) {
      final message = error.errorResponse?.message;
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }
    return _fallback;
  }

  /// Shows the outcome of a closure request. Never logs out and never
  /// says "deleted".
  static void showResult(BuildContext context, ProcessState<bool> state) {
    if (state.hasSuccess) {
      AppHelper.showAppDialog<void>(
        context,
        barrierDismissible: true,
        const OnSuccessDialogContent(
          mainText: 'Request received',
          subtext: submitted,
        ),
      );
    } else if (state.hasError) {
      AppHelper.showAppDialog<void>(
        context,
        barrierDismissible: true,
        OnFailDialogContent(
          subtext: errorMessage(state.error),
          onDoneCallback: (_) {},
        ),
      );
    }
  }
}
