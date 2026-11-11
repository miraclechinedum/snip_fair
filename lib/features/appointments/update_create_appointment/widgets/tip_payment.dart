import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/presentation/widgets/payment_method_selector.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/appointments/customer_appointments/cubit/customer_appointments_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/data/card_tip_recovery.dart';

/// The whole tip journey from the booking screen: the tip sheet, then for a
/// card tip the booking's hosted checkout, then Laravel's verdict. Closing
/// checkout is never proof of payment.
class TipFlow {
  const TipFlow._();

  /// Opens the hosted checkout. Replaceable in tests (no WebView there).
  @visibleForTesting
  static Future<bool> Function(BuildContext, CheckoutPaymentData) openCheckout =
      AppHelper.showPaymentDialog;

  /// [start] for the booking loaded in [cubit]: its stylist, and the wallet
  /// balance the app last loaded (Laravel still decides).
  static Future<void> startForBooking(
    BuildContext context,
    UpdateCreateAppointmentCubit cubit,
  ) async {
    // An earlier card tip for this booking is still undecided (possibly from
    // before an app restart): check it instead of offering a new tip.
    if (cubit.hasUnresolvedCardTip) {
      AppHelper.showSnackBar(
        context,
        message: UpdateCreateAppointmentCubit.tipUnresolvedMessage,
      );
      await cubit.checkUnresolvedTip();
      return;
    }
    final stylist = cubit.state.fetchAppointmentState.data?.stylist;
    final fullName =
        [stylist?.firstName, stylist?.lastName].whereType<String>().join(' ');
    return start(
      context,
      cubit: cubit,
      walletBalance: context
          .read<CustomerProfileMgtCubit>()
          .state
          .walletState
          .data
          ?.balance,
      stylistName: stylist?.name ?? fullName,
    );
  }

  static Future<void> start(
    BuildContext context, {
    required UpdateCreateAppointmentCubit cubit,
    required num? walletBalance,
    required String? stylistName,
  }) async {
    final result = await AppHelper.showCustomModalBottomSheet<TipStartResult>(
      context: context,
      modal: TipBottomSheet(
        walletBalance: walletBalance,
        stylistName: stylistName,
        onSubmit: (amount, method) async {
          final result = await cubit.startTip(amount, paymentMethod: method);
          return (result, cubit.state.tipPayment.message);
        },
      ),
      isDarkMode: false,
    );
    if (result != TipStartResult.checkoutStarted || !context.mounted) return;
    final checkout = cubit.state.tipPayment.checkout;
    if (checkout == null) return;
    try {
      peachLog('Tip checkout opened deposit=${checkout.depositId}');
      final closed = await openCheckout(context, checkout);
      peachLog('Tip checkout closed (result=$closed)');
    } catch (e) {
      peachLog('Tip checkout threw ${e.runtimeType}');
    } finally {
      await cubit.onTipCheckoutClosed();
    }
  }
}

/// Tip amount, payment method and confirmation. Pops the [TipStartResult]
/// once a wallet tip is sent or a card checkout is ready; refusals stay in
/// the sheet so the customer can change the amount or method.
class TipBottomSheet extends StatefulWidget {
  const TipBottomSheet({
    required this.walletBalance,
    required this.onSubmit,
    this.stylistName,
    super.key,
  });

  /// Null when the balance could not be loaded (Laravel still decides).
  final num? walletBalance;
  final String? stylistName;

  /// Starts the tip; returns what happened and, if refused, why.
  final Future<(TipStartResult, String?)> Function(
    double amount,
    String method,
  ) onSubmit;

  static const quickAmounts = [20.0, 50.0, 100.0];

  @override
  State<TipBottomSheet> createState() => _TipBottomSheetState();
}

class _TipBottomSheetState extends State<TipBottomSheet> {
  final _controller = TextEditingController();
  late String _method;
  bool _isSubmitting = false;
  String? _error;

  /// Rands with at most two decimals, as Laravel requires.
  static final _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  @override
  void initState() {
    super.initState();
    _method = 'wallet';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _stylist {
    final name = widget.stylistName?.trim() ?? '';
    return name.isEmpty ? 'your stylist' : name;
  }

  double? get _amount {
    final text = _controller.text.trim();
    return _amountPattern.hasMatch(text) ? double.tryParse(text) : null;
  }

  Future<void> _handleSubmit() async {
    // A second tap can land before the rebuild that disables the button.
    if (_isSubmitting) return;
    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _error =
          'Enter a tip amount in rands, with at most two decimal places.');
      return;
    }
    final balance = widget.walletBalance;
    if (_method == 'wallet' && balance != null && amount > balance) {
      setState(() => _error = 'Your wallet balance '
          '(${balance.toDouble().formatAmount()}) is too low for this tip. '
          'Choose Card or a smaller amount.');
      return;
    }

    final methodLabel = _method == 'card' ? 'card' : 'wallet';
    final confirmed = await AppHelper.showAppDialog<bool>(
      context,
      OnConfirmDialog(
        key: const Key('tip_confirm_dialog'),
        title: 'Send ${amount.formatAmount()} tip?',
        content: 'Your tip goes to $_stylist, paid from your $methodLabel.',
        confirmText: _method == 'card' ? 'Continue to Card' : 'Send Tip',
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final (result, message) = await widget.onSubmit(amount, _method);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    switch (result) {
      case TipStartResult.tipped:
      case TipStartResult.checkoutStarted:
        Navigator.of(context).pop(result);
      case TipStartResult.cardUnavailable:
      case TipStartResult.insufficientBalance:
      case TipStartResult.failed:
      case TipStartResult.unresolved:
      case TipStartResult.busy:
        // Refused: nothing was paid. The customer may change the amount or
        // method; no other method is tried on their behalf.
        setState(() => _error = message ?? _fallbackFor(result));
    }
  }

  static String _fallbackFor(TipStartResult result) => switch (result) {
        TipStartResult.cardUnavailable =>
          UpdateCreateAppointmentCubit.tipCardUnavailableMessage,
        TipStartResult.unresolved =>
          UpdateCreateAppointmentCubit.tipUnresolvedMessage,
        TipStartResult.busy => 'Your tip is already being processed.',
        _ => UpdateCreateAppointmentCubit.tipFailedMessage,
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const ModalPill(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: 'Tip $_stylist',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    8.verticalSpace,
                    const AppText(
                      text: 'Send a tip to show your appreciation for the '
                          'great service! Your stylist receives the full '
                          'amount.',
                      color: AppColors.grey3,
                    ),
                    16.verticalSpace,
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final quick in TipBottomSheet.quickAmounts)
                          ChoiceChip(
                            key: Key('tip_quick_${quick.toInt()}'),
                            label: Text(quick.formatAmount()),
                            selected: _amount == quick,
                            onSelected: _isSubmitting
                                ? null
                                : (_) => setState(() {
                                      _controller.text =
                                          quick.toStringAsFixed(2);
                                      _error = null;
                                    }),
                          ),
                      ],
                    ),
                    12.verticalSpace,
                    CustomTextField(
                      key: const Key('tip_amount_field'),
                      label: 'Tip amount (R)',
                      textController: _controller,
                      hint: 'e.g. 50',
                      readOnly: _isSubmitting,
                      onChanged: (_) => setState(() => _error = null),
                      inputType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                    ),
                    16.verticalSpace,
                    PaymentMethodSelector(
                      selected: _method,
                      walletBalance: widget.walletBalance,
                      onSelected: (method) {
                        if (_isSubmitting) return;
                        setState(() {
                          _method = method;
                          _error = null;
                        });
                      },
                    ),
                    if (_error != null) ...[
                      12.verticalSpace,
                      AppText(
                        key: const Key('tip_error'),
                        text: _error!,
                        fontSize: 12,
                        color: AppColors.contentColorRed,
                      ),
                    ],
                    16.verticalSpace,
                    CustomButton(
                      key: const Key('tip_submit'),
                      title: _method == 'card' ? 'Pay by Card' : 'Send Tip',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleSubmit,
                    ),
                    12.verticalSpace,
                    CustomButton(
                      title: 'Cancel',
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      gradient: null,
                      background: const Color(0xff374757),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown on the booking while a card tip is being confirmed, could not be
/// confirmed, or was not paid. Never claims the stylist was tipped.
class TipPaymentStatusBanner extends StatelessWidget {
  const TipPaymentStatusBanner({
    required this.progress,
    required this.onCheckStatus,
    required this.onTryAgain,
    super.key,
  });

  final TipPaymentProgress progress;
  final VoidCallback onCheckStatus;
  final VoidCallback onTryAgain;

  static bool showsFor(TipPaymentPhase phase) =>
      phase == TipPaymentPhase.verifying ||
      phase.isUnresolved ||
      phase == TipPaymentPhase.notPaid;

  @override
  Widget build(BuildContext context) {
    final phase = progress.phase;
    if (!showsFor(phase)) return const SizedBox.shrink();
    final verifying = phase == TipPaymentPhase.verifying;
    final text = verifying
        ? 'Checking your tip payment…'
        : progress.message ??
            (phase == TipPaymentPhase.notPaid
                ? UpdateCreateAppointmentCubit.tipNotPaidMessage
                : UpdateCreateAppointmentCubit.tipPendingMessage);
    return Container(
      key: const Key('tip_payment_banner'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffa8740).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(text: text, fontSize: 12, color: AppColors.warningText),
          8.verticalSpace,
          if (phase == TipPaymentPhase.notPaid)
            CustomButton(
              key: const Key('tip_try_again'),
              title: 'Try Again',
              onPressed: onTryAgain,
            )
          else
            CustomButton(
              key: const Key('tip_check_status'),
              title: 'Check Payment Status',
              isLoading: verifying,
              onPressed: verifying ? null : onCheckStatus,
            ),
        ],
      ),
    );
  }
}

/// Tells the customer what became of a tip, and refreshes what it changed
/// through the app's own cubits. Used by the booking screen and by app-level
/// recovery, so an outcome is presented the same way wherever it is learnt.
/// Only [TipPaymentPhase.tipped] says the stylist received the tip.
class TipOutcomePresenter {
  const TipOutcomePresenter._();

  /// The booking-screen phase for a recovered [verdict]; null when there is
  /// nothing to announce yet (pending / unknown).
  static TipPaymentPhase? phaseFor(CardTipVerdict verdict) => switch (verdict) {
        CardTipVerdict.tipped => TipPaymentPhase.tipped,
        CardTipVerdict.creditedToWallet => TipPaymentPhase.creditedToWallet,
        CardTipVerdict.notPaid => TipPaymentPhase.notPaid,
        CardTipVerdict.unverifiable => TipPaymentPhase.failed,
        CardTipVerdict.pending || CardTipVerdict.unknown => null,
      };

  static void present(
    BuildContext context, {
    required TipPaymentPhase phase,
    String? message,
  }) {
    switch (phase) {
      case TipPaymentPhase.tipped:
        _refreshMoney(context);
        AppHelper.showAppDialog<void>(
          context,
          OnSuccessDialogContent(
            key: const Key('tip_sent_dialog'),
            compactIcon: true,
            mainText: 'Tip Sent',
            subtext: message ?? UpdateCreateAppointmentCubit.tipSentMessage,
            onDoneCallback: (_) {},
          ),
        );
      case TipPaymentPhase.creditedToWallet:
        _refreshMoney(context);
        AppHelper.showAppDialog<void>(
          context,
          const OnConfirmDialog(
            key: Key('tip_credited_dialog'),
            title: 'Added to Your Wallet',
            content: UpdateCreateAppointmentCubit.tipCreditedToWalletMessage,
            confirmText: 'OK',
            showCancel: false,
          ),
        );
      case TipPaymentPhase.notPaid:
        AppHelper.showAppDialog<void>(
          context,
          OnFailDialogContent(
            key: const Key('tip_not_paid_dialog'),
            subtext: message ?? UpdateCreateAppointmentCubit.tipNotPaidMessage,
            buttonText: 'OK',
            onDoneCallback: (_) {},
          ),
        );
      default:
        if (message != null) {
          AppHelper.showSnackBar(context, message: message);
        }
    }
  }

  /// Wallet, transactions and the bookings list — re-fetched from Laravel
  /// through the instances the app's screens show.
  static void _refreshMoney(BuildContext context) {
    try {
      context.read<CustomerProfileMgtCubit>()
        ..getWallet(true)
        ..getWalletTransactions();
    } catch (e) {
      peachLog('Wallet refresh after tip skipped: ${e.runtimeType}');
    }
    try {
      context.read<CustomerAppointmentsCubit>().getAppointments();
    } catch (e) {
      peachLog('Bookings refresh after tip skipped: ${e.runtimeType}');
    }
  }
}
