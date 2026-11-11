import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/utils/distance_format.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/presentation/widgets/payment_summary_widget.dart';
import 'package:snip_fair/core/presentation/widgets/payment_method_selector.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/keyboard_dismisser.dart';
import 'package:snip_fair/core/domain/entities/seller_details/working_hour.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/appointments/customer_appointments/cubit/customer_appointments_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_verification/views/seller_profile_verification_screen.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/widgets/tip_payment.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/widgets/appointment_card_payment_notice.dart';
// ignore_for_file: unawaited_futures

@RoutePage()
class UpdateCreateAppointmentScreen extends StatefulWidget
    implements AutoRouteWrapper {
  const UpdateCreateAppointmentScreen({
    super.key,
    this.portfolioId,
    this.appointmentId,
  });

  final String? portfolioId;
  final String? appointmentId;

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UpdateCreateAppointmentCubit>()
        ..initialize(
          context,
          portfolioId: portfolioId,
          appointmentId: appointmentId,
        )
        ..onAddressChanged(
          context
                  .read<CustomerProfileMgtCubit>()
                  .state
                  .profileDetails
                  .data
                  ?.user
                  ?.country ??
              '',
        ),
      child: this,
    );
  }

  @override
  State<UpdateCreateAppointmentScreen> createState() =>
      _UpdateCreateAppointmentScreenState();
}

class _UpdateCreateAppointmentScreenState
    extends State<UpdateCreateAppointmentScreen> with WidgetsBindingObserver {
  /// Set once this screen has left for the Appointments tab, so repeated
  /// reconciliation emissions or an app resume can never navigate twice.
  bool _leftForAppointments = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState != AppLifecycleState.resumed || !mounted) return;
    final cubit = context.read<UpdateCreateAppointmentCubit>();
    if (cubit.state.cardPaymentPhase == CardPaymentPhase.checkoutOpen) {
      peachLog('App resumed while checkout was open');
      cubit.onCardCheckoutClosed();
    }
  }

  /// Opens the hosted checkout and *always* asks the cubit to reconcile when it
  /// returns — a close, a shopper-result redirect, a manual dismiss or a thrown
  /// error all land in the `finally`. The cubit reference is captured up front
  /// so this no longer depends on any BuildContext still being mounted; the
  /// checkout UI is never treated as proof of payment.
  Future<void> _openHostedCheckout(
    UpdateCreateAppointmentCubit cubit,
    CheckoutPaymentData paymentData,
  ) async {
    peachLog(
      'Opening hosted checkout: deposit=${paymentData.depositId ?? 'none'}',
    );
    bool? result;
    try {
      result = await AppHelper.showPaymentDialog(context, paymentData);
    } catch (e) {
      peachLog('Hosted checkout threw: ${e.runtimeType}');
    } finally {
      peachLog('Hosted checkout returned (result=${result ?? 'none'})');
      if (cubit.isClosed) {
        peachLog('Reconciliation skipped: booking screen already disposed');
      } else {
        peachLog('Invoking onCardCheckoutClosed');
        await cubit.onCardCheckoutClosed();
      }
    }
  }

  static const _tipOutcomePhases = {
    TipPaymentPhase.tipped,
    TipPaymentPhase.creditedToWallet,
    TipPaymentPhase.notPaid,
    TipPaymentPhase.pending,
    TipPaymentPhase.unknown,
  };

  /// Leaves the booking form once a card payment is verified or still being
  /// confirmed, so an already-paid booking is never left on screen to be
  /// submitted again. Pops back to [MainRoute] — removing this route from the
  /// stack — and selects the customer Appointments tab.
  void _leaveForAppointments() {
    if (_leftForAppointments || !mounted) return;
    final root = context.router.root;
    if (!root.stackData.any((route) => route.name == MainRoute.name)) {
      peachLog('Staying on booking screen: main route not in stack');
      return;
    }
    _leftForAppointments = true;
    peachLog('Leaving booking screen for Appointments tab');
    root.popUntilRouteWithName(MainRoute.name);
    root
        .innerRouterOf<TabsRouter>(MainRoute.name)
        ?.navigate(const AppointementsMainRoute());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerProfileMgtCubit, CustomerProfileMgtState>(
      builder: (context, state) {
        final view = KeyboardDismisser(
          child: Scaffold(
            appBar: CustomAppBar(
              title: widget.appointmentId != null
                  ? 'Update Appointment'
                  : 'Book Appointment',
            ),
            body: SafeArea(
              child: BlocListener<UpdateCreateAppointmentCubit,
                  UpdateCreateAppointmentState>(
                listenWhen: (previous, current) =>
                    previous.fetchAppointmentState !=
                    current.fetchAppointmentState,
                listener: (context, state) {
                  if (state.fetchAppointmentState.hasError) {
                    AppHelper.showAppDialog<void>(
                      context,
                      OnFailDialogContent(
                        subtext: (state.fetchAppointmentState.error!
                                    as RemoteException)
                                .errorResponse
                                ?.message ??
                            'Something went wrong, please try again later.',
                        onDoneCallback: (_) {
                          context.router.pop();
                        },
                      ),
                    );
                  }
                },
                child: MultiBlocListener(
                  listeners: [
                    // A hosted-checkout close is not success. Reconcile with
                    // Laravel after every return from Peach.
                    BlocListener<UpdateCreateAppointmentCubit,
                        UpdateCreateAppointmentState>(
                      listenWhen: (p, c) =>
                          p.cardCheckoutState != c.cardCheckoutState,
                      listener: (context, state) {
                        final s = state.cardCheckoutState;
                        if (s.hasError) {
                          AppHelper.showSnackBar(
                            context,
                            message:
                                'Unable to start payment. Please try again.',
                          );
                          return;
                        }
                        if (!s.hasSuccess) return;

                        _openHostedCheckout(
                          context.read<UpdateCreateAppointmentCubit>(),
                          s.data!,
                        );
                      },
                    ),

                    // Tip outcomes, once per change of outcome. Refusals while
                    // the tip sheet is open are shown in the sheet itself.
                    BlocListener<UpdateCreateAppointmentCubit,
                        UpdateCreateAppointmentState>(
                      listenWhen: (p, c) =>
                          p.tipPayment.phase != c.tipPayment.phase &&
                          !c.tipPayment.announced &&
                          (_tipOutcomePhases.contains(c.tipPayment.phase) ||
                              (c.tipPayment.phase == TipPaymentPhase.failed &&
                                  p.tipPayment.phase ==
                                      TipPaymentPhase.verifying)),
                      listener: (context, state) => TipOutcomePresenter.present(
                        context,
                        phase: state.tipPayment.phase,
                        message: state.tipPayment.message,
                      ),
                    ),

                    BlocListener<UpdateCreateAppointmentCubit,
                        UpdateCreateAppointmentState>(
                      listenWhen: (p, c) =>
                          p.cardVerificationState != c.cardVerificationState,
                      listener: (context, state) {
                        switch (state.cardPaymentPhase) {
                          case CardPaymentPhase.successful:
                            AppHelper.showSnackBar(
                              context,
                              message: UpdateCreateAppointmentCubit
                                  .cardPaymentMessage(state.cardPaymentPhase),
                            );
                            context
                                .read<CustomerAppointmentsCubit>()
                                .getAppointments();
                            context.read<CustomerProfileMgtCubit>()
                              ..getWallet()
                              ..getWalletTransactions();
                            _leaveForAppointments();
                            break;
                          case CardPaymentPhase.pending:
                            AppHelper.showSnackBar(
                              context,
                              message: UpdateCreateAppointmentCubit
                                  .cardPaymentMessage(state.cardPaymentPhase),
                            );
                            context
                                .read<CustomerAppointmentsCubit>()
                                .getAppointments();
                            _leaveForAppointments();
                            break;
                          case CardPaymentPhase.cancelled:
                          case CardPaymentPhase.failed:
                          case CardPaymentPhase.unknown:
                            AppHelper.showSnackBar(
                              context,
                              message: UpdateCreateAppointmentCubit
                                  .cardPaymentMessage(
                                state.cardPaymentPhase,
                                canRetry: state.retryAppointmentId != null,
                              ),
                            );
                            break;
                          default:
                            break;
                        }
                      },
                    ),
                  ],
                  child: BlocConsumer<UpdateCreateAppointmentCubit,
                      UpdateCreateAppointmentState>(
                    listenWhen: (previous, current) =>
                        previous.updateOrCreateAppointmentState !=
                        current.updateOrCreateAppointmentState,
                    listener: (context, state) {
                      if (state.updateOrCreateAppointmentState.hasSuccess) {
                        AppHelper.showSnackBar(
                          context,
                          message: widget.appointmentId != null
                              ? 'Appointment updated successfully'
                              : 'Appointment created successfully',
                        );
                        // context.router.pop();
                        context
                            .read<CustomerAppointmentsCubit>()
                            .getAppointments();
                        context.read<CustomerProfileMgtCubit>()
                          ..getWallet()
                          ..getWalletTransactions();
                      } else if (state
                          .updateOrCreateAppointmentState.hasError) {
                        AppHelper.showAppDialog<void>(
                          context,
                          OnFailDialogContent(
                            subtext: (state.updateOrCreateAppointmentState
                                        .error! as RemoteException)
                                    .errorResponse
                                    ?.message ??
                                'Something went wrong, please try again later.',
                            onDoneCallback: (_) {
                              context.router.pop();
                            },
                          ),
                        );
                      }
                    },
                    buildWhen: (previous, current) =>
                        previous.fetchPortfolioState !=
                            current.fetchPortfolioState ||
                        previous.fetchAppointmentState !=
                            current.fetchAppointmentState ||
                        previous.updateOrCreateAppointmentState !=
                            current.updateOrCreateAppointmentState,
                    builder: (context, state) {
                      if (state.fetchPortfolioState.isLoading ||
                          state.fetchAppointmentState.isLoading ||
                          state.updateOrCreateAppointmentState.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          if (widget.appointmentId != null) {
                            return context
                                .read<UpdateCreateAppointmentCubit>()
                                .fetchAppointmentById(widget.appointmentId!);
                          } else if (state.fetchAppointmentState.hasSuccess) {
                            return context
                                .read<UpdateCreateAppointmentCubit>()
                                .fetchAppointmentById(
                                  state.fetchAppointmentState.data!.id
                                      .toString(),
                                );
                          }
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const AppointmentHeader(),
                              16.verticalSpace,
                              if (state.fetchAppointmentState.data == null) ...[
                                const SelectDateWidget(),
                                16.verticalSpace,
                              ],
                              if (state.fetchAppointmentState.data == null) ...[
                                const SelectTimeWIdget(),
                                16.verticalSpace,
                              ],
                              buildYourInformationView(),
                              24.verticalSpace,
                              const BookingSummary(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final appointmentState =
            context.watch<UpdateCreateAppointmentCubit>().state;
        final isBusy = state.initializePaymentState.isLoading ||
            appointmentState.cardCheckoutState.isLoading ||
            appointmentState.cardVerificationState.isLoading;
        // The busy overlay is always wrapped in the same Stack, and `view` is
        // always its first child. Swapping between `view` and `Stack([view])`
        // changed the widget type at this position, which tore down and
        // rebuilt the whole subtree — including the BlocListener that awaits
        // the hosted checkout, leaving its context unmounted on return.
        return Stack(
          children: [
            view,
            if (isBusy)
              ColoredBox(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget buildYourInformationView() {
    return BlocBuilder<CustomerProfileMgtCubit, CustomerProfileMgtState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppColors.grey1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                text: 'Your Information',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              12.verticalSpace,
              CustomTextField(
                label: 'Full Name',
                isRequired: true,
                initialText: state.profileDetails.data?.user?.name ?? '',
                readOnly: true,
              ),
              12.verticalSpace,
              CustomTextField(
                label: 'Email',
                isRequired: true,
                initialText: state.profileDetails.data?.user?.email ?? '',
                readOnly: true,
              ),
              12.verticalSpace,
              BlocBuilder<UpdateCreateAppointmentCubit,
                  UpdateCreateAppointmentState>(
                builder: (context, appointState) {
                  if (appointState.fetchAppointmentState.hasSuccess) {
                    return CustomPlaceSearchField(
                      label: 'Location',
                      onSelected: context
                          .read<UpdateCreateAppointmentCubit>()
                          .onPlaceSelected,
                      readOnly: appointState.fetchAppointmentState
                          .hasSuccess, // make readOnly if update
                      initialPlace: appointState
                                  .fetchAppointmentState.data?.serviceNotes !=
                              null
                          ? GeoPlace(
                              address: appointState
                                  .fetchAppointmentState.data!.serviceNotes!,
                            )
                          : GeoPlace(
                              address:
                                  state.profileDetails.data!.user!.country!,
                            ),
                    );
                  }
                  return CustomPlaceSearchField(
                    label: 'Location',
                    onSelected: context
                        .read<UpdateCreateAppointmentCubit>()
                        .onPlaceSelected,
                    readOnly: appointState.fetchAppointmentState
                        .hasSuccess, // make readOnly if update
                    initialPlace: state.profileDetails.data?.user?.country !=
                            null
                        ? GeoPlace(
                            address: state.profileDetails.data!.user!.country!,
                          )
                        : null,
                  );
                },
              ),
              12.verticalSpace,
              BlocBuilder<UpdateCreateAppointmentCubit,
                  UpdateCreateAppointmentState>(
                builder: (context, state) {
                  return CustomTextField(
                    label: 'Special Requests or Notes (Optional)',
                    onChanged: (value) {
                      context
                          .read<UpdateCreateAppointmentCubit>()
                          .onNotesChanged(value);
                    },
                    readOnly: state.fetchAppointmentState.hasSuccess,
                    initialText:
                        state.fetchAppointmentState.data?.extra?.toString() ??
                            '',
                    maxLines: 4,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class AppointmentHeader extends StatelessWidget {
  const AppointmentHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCreateAppointmentCubit,
        UpdateCreateAppointmentState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            context.router.push(
              StylistSellerDetailsRoute(
                id: state.fetchPortfolioState.data!.user!.id.toString(),
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: AppColors.grey1),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.contentColorBlue),
                    image: state.fetchPortfolioState.data?.user?.avatar != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              state.fetchPortfolioState.data!.user!.avatar!
                                  .completeImagePath(),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: AppColors.appgradient,
                  ),
                  child: state.fetchPortfolioState.data?.user?.avatar == null
                      ? Center(
                          child: AppText(
                            text: state.fetchPortfolioState.data?.user
                                            ?.firstName !=
                                        null &&
                                    state.fetchPortfolioState.data?.user
                                            ?.lastName !=
                                        null
                                ? AppHelper.initialsFromName(
                                    state.fetchPortfolioState.data!.user!
                                        .firstName!,
                                    state.fetchPortfolioState.data!.user!
                                        .lastName!,
                                  )
                                : 'N/A',
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const SizedBox(),
                ),
                8.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: state.fetchPortfolioState.data?.title ?? '',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                      ),
                      AppText(
                        text: state.fetchPortfolioState.data?.user
                                ?.stylistProfile?.businessName ??
                            '',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
                8.horizontalSpace,
                AppText(
                  text: formatDistanceAway(
                        state.fetchSellerDetailsState.data?.distance,
                      ) ??
                      '',
                  fontSize: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BookingSummary extends StatelessWidget {
  const BookingSummary({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCreateAppointmentCubit,
        UpdateCreateAppointmentState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppColors.grey1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.fetchAppointmentState.hasSuccess)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: state.fetchAppointmentState.data!.status
                        .toStatusColor()
                        .withOpacity(0.1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Center(
                    child: AppText(
                      // An unpaid card booking says what happened to its
                      // payment instead of a bare "Processing".
                      text: state.fetchAppointmentState.data!.cardPayment
                              ?.statusLabel ??
                          state.fetchAppointmentState.data!.status
                              ?.toStatusText() ??
                          '',
                      fontWeight: FontWeight.w600,
                      color: state.fetchAppointmentState.data!.status
                          .toStatusColor(),
                    ),
                  ),
                ),
              if (state.fetchAppointmentState.data?.cardPayment
                  case final cardPayment?)
                AppointmentCardPaymentNotice(
                  payment: cardPayment,
                  isBusy: state.isCardPaymentBusy,
                  onRetry: () => context
                      .read<UpdateCreateAppointmentCubit>()
                      .retryAppointmentPayment(
                        state.fetchAppointmentState.data!.id.toString(),
                      ),
                  onCheckStatus: () => context
                      .read<UpdateCreateAppointmentCubit>()
                      .checkAppointmentPayment(
                        appointmentId:
                            state.fetchAppointmentState.data!.id.toString(),
                        depositId: cardPayment.depositId!,
                      ),
                ),
              const AppText(
                text: 'Booking Summary',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              if (state.fetchAppointmentState.hasSuccess)
                AppText(
                  text:
                      'Booking ID: ${state.fetchAppointmentState.data?.bookingId}',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              const Divider(),
              8.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    text: 'Service',
                  ),
                  AppText(
                    text: state.fetchPortfolioState.data?.title ?? '',
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              8.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    text: 'Category',
                  ),
                  AppText(
                    text: state.fetchPortfolioState.data?.category?.name ?? '',
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              8.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    text: 'Duration',
                  ),
                  AppText(
                    text: state.fetchPortfolioState.data?.duration ?? '',
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              8.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    text: 'Date',
                  ),
                  AppText(
                    text: state.selectedDate != null
                        ? '${state.selectedDate!.toShortDateString()} '
                        : 'Select a date',
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              8.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    text: 'Time',
                  ),
                  AppText(
                    text: state.selectedTime != null
                        ? '${state.selectedTime!.format(context)} '
                        : 'Select a time',
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    text: 'Total',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  AppText(
                    text: state.fetchPortfolioState.data != null
                        ? state.fetchPortfolioState.data!.price!.formatAmount()
                        : '',
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                    fontSize: 18,
                  ),
                ],
              ),
              8.verticalSpace,
              if (state.fetchAppointmentState.hasSuccess &&
                  state
                      .fetchAppointmentState.data!.status.isApprovedStatus) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xffE8FAF0),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const AppText(
                        text: 'Booking Confirmed',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      const AppText(
                        text:
                            'Your appointment is confirmed. Please Save your security code.',
                        textAlign: TextAlign.center,
                      ),
                      12.verticalSpace,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.white,
                        ),
                        child: Column(
                          children: [
                            const AppText(
                              text: 'Security Code',
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w600,
                            ),
                            15.verticalSpace,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                  text: state.fetchAppointmentState.data
                                          ?.appointmentCode
                                          ?.split('-')
                                          .last
                                          .toString() ??
                                      '',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff15B55A),
                                ),
                                10.horizontalSpace,
                                GestureDetector(
                                  onTap: () => AppHelper.copyToClipboard(
                                    context,
                                    state.fetchAppointmentState.data
                                            ?.appointmentCode
                                            .pickNumber()
                                            .toString() ??
                                        '',
                                  ),
                                  child: const Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            12.verticalSpace,
                            const AppText(
                              text:
                                  'show this code to your stylist to verify appoinment',
                              fontSize: 12,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (state.fetchAppointmentState.hasSuccess &&
                  state.fetchAppointmentState.data!.status
                      .isConfirmedStatus) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xffFBF6FF),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const AppText(
                        text: 'Job Completed',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.white,
                        ),
                        child: Column(
                          children: [
                            const AppText(
                              text: 'Security Code',
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w600,
                            ),
                            15.verticalSpace,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                  text: state.fetchAppointmentState.data
                                          ?.completionCode
                                          ?.split('-')
                                          .last
                                          .toString() ??
                                      '',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                                10.horizontalSpace,
                                GestureDetector(
                                  onTap: () => AppHelper.copyToClipboard(
                                    context,
                                    state.fetchAppointmentState.data
                                            ?.completionCode
                                            .pickNumber()
                                            .toString() ??
                                        '',
                                  ),
                                  child: const Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            12.verticalSpace,
                            const AppText(
                              text:
                                  'show this code to your stylist to verify job completion',
                              fontSize: 12,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      24.verticalSpace,
                    ],
                  ),
                ),
              ],
              // Payment method picker — visible when about to book (either
              // a first booking, or Book Again on a completed appointment).
              // The picker itself is stateless UI; the choice is stored on
              // the cubit's state.paymentMethod field and consumed by the
              // Book / Book Again onPressed handlers below.
              //
              if ((!state.fetchAppointmentState.hasSuccess ||
                  (state.fetchAppointmentState.data?.status.isCompletedStatus ??
                      false))) ...[
                const PaymentMethodPicker(),
                12.verticalSpace,
              ],
              if (state.cardPaymentPhase == CardPaymentPhase.pending ||
                  state.cardPaymentPhase == CardPaymentPhase.unknown) ...[
                CustomButton(
                  title: 'Check Payment Status',
                  onPressed: () => context
                      .read<UpdateCreateAppointmentCubit>()
                      .reconcileCardPayment(automatic: false),
                  gradient: null,
                  background: Colors.white,
                  textColor: AppColors.black,
                  borderColor: AppColors.grey1,
                  isOutline: true,
                ),
                12.verticalSpace,
              ],
              if (!state.fetchAppointmentState.hasSuccess)
                BlocConsumer<CustomerProfileMgtCubit, CustomerProfileMgtState>(
                  listenWhen: (previous, current) =>
                      previous.initializePaymentState !=
                      current.initializePaymentState,
                  listener: (context, profileState) async {
                    final cubit = context.read<UpdateCreateAppointmentCubit>();
                    if (profileState.initializePaymentState.hasSuccess) {
                      await AppHelper.showPaymentDialog(
                        context,
                        profileState.initializePaymentState.data!,
                      );
                      if (!context.mounted) return;
                      await context
                          .read<CustomerProfileMgtCubit>()
                          .reconcileWalletTopUp();
                      final verification = context
                          .read<CustomerProfileMgtCubit>()
                          .state
                          .topUpVerificationState;
                      if (verification.data?.isVerified ?? false) {
                        context.read<CustomerProfileMgtCubit>()
                          ..getWallet()
                          ..getWalletTransactions();
                        cubit.createAppointment();
                      } else {
                        AppHelper.showSnackBar(
                          context,
                          message: verification.data?.isPending ?? false
                              ? 'Your top-up is still being confirmed.'
                              : 'Your top-up could not be confirmed yet.',
                        );
                      }
                    }
                  },
                  builder: (context, profileState) {
                    final walletBalance =
                        profileState.walletState.data?.balance ?? 0.0;

                    return CustomButton(
                      // After Peach confirmed a cancelled or failed card
                      // payment, booking by card pays the SAME booking again.
                      title: state.paymentMethod == 'card' &&
                              state.retryAppointmentId != null
                          ? 'Retry Payment'
                          : 'Book Appointment',
                      isLoading:
                          state.updateOrCreateAppointmentState.isLoading ||
                              state.isCardPaymentBusy,
                      // An unverified card attempt must be resolved through
                      // "Check Payment Status", never by charging the card
                      // again.
                      onPressed: state.canBookAppointment &&
                              !state.isCardPaymentBusy &&
                              !(state.paymentMethod == 'card' &&
                                  state.hasUnresolvedCardPayment)
                          ? () async {
                              final profileCubit =
                                  context.read<CustomerProfileMgtCubit>();
                              final cubit =
                                  context.read<UpdateCreateAppointmentCubit>();
                              final servicePrice =
                                  state.fetchPortfolioState.data?.price ?? 0.0;

                              if (cubit.state.paymentMethod == 'card') {
                                cubit.createAppointment();
                                return;
                              }

                              // Wallet path — existing logic unchanged.
                              if (walletBalance < servicePrice) {
                                var canProceedToPay = await AppHelper
                                    .showCustomModalBottomSheet<bool>(
                                  context: context,
                                  modal: PaymentSummaryWidget(
                                    servicePrice: servicePrice,
                                    walletBalance: walletBalance.toDouble(),
                                  ),
                                  isDarkMode: false,
                                );

                                canProceedToPay ??= false;
                                if (canProceedToPay) {
                                  profileCubit.initializeWalletTopUp(
                                    amount: servicePrice - walletBalance,
                                  );
                                }
                                return;
                              }
                              cubit.createAppointment();
                            }
                          : null,
                    );
                  },
                ),
              if (state.fetchAppointmentState.hasSuccess &&
                  state.fetchAppointmentState.data!.status
                      .isCompletedStatus) ...[
                Builder(
                  builder: (context) {
                    return BlocConsumer<CustomerProfileMgtCubit,
                        CustomerProfileMgtState>(
                      listenWhen: (previous, current) =>
                          previous.initializePaymentState !=
                          current.initializePaymentState,
                      listener: (_, profileState) async {
                        final cubit =
                            context.read<UpdateCreateAppointmentCubit>();
                        if (profileState.initializePaymentState.hasSuccess) {
                          await AppHelper.showPaymentDialog(
                            context,
                            profileState.initializePaymentState.data!,
                          );
                          if (!context.mounted) return;
                          await context
                              .read<CustomerProfileMgtCubit>()
                              .reconcileWalletTopUp();
                          if (context
                                  .read<CustomerProfileMgtCubit>()
                                  .state
                                  .topUpVerificationState
                                  .data
                                  ?.isVerified ??
                              false) {
                            context.read<CustomerProfileMgtCubit>()
                              ..getWallet()
                              ..getWalletTransactions();
                            cubit.createAppointment();
                          }
                        }
                      },
                      builder: (context, profileState) {
                        final walletBalance =
                            profileState.walletState.data?.balance ?? 0.0;

                        return CustomButton(
                          title: 'Book Again',
                          isLoading:
                              state.updateOrCreateAppointmentState.isLoading ||
                                  state.isCardPaymentBusy,
                          // Same guard as Book: an unconfirmed card
                          // checkout must be resolved via "Check Payment
                          // Status", never by charging the card again.
                          onPressed: state.canBookAppointment &&
                                  !state.isCardPaymentBusy &&
                                  !(state.paymentMethod == 'card' &&
                                      state.hasUnresolvedCardPayment)
                              ? () async {
                                  final profileCubit =
                                      context.read<CustomerProfileMgtCubit>();
                                  final cubit = context
                                      .read<UpdateCreateAppointmentCubit>();
                                  final servicePrice =
                                      state.fetchPortfolioState.data?.price ??
                                          0.0;

                                  if (cubit.state.paymentMethod == 'card') {
                                    cubit.createAppointment();
                                    return;
                                  }

                                  if (walletBalance < servicePrice) {
                                    var canProceedToPay = await AppHelper
                                        .showCustomModalBottomSheet<bool>(
                                      context: context,
                                      modal: PaymentSummaryWidget(
                                        servicePrice: servicePrice,
                                        walletBalance: walletBalance.toDouble(),
                                      ),
                                      isDarkMode: false,
                                    );

                                    canProceedToPay ??= false;
                                    if (canProceedToPay) {
                                      profileCubit.initializeWalletTopUp(
                                        amount: servicePrice - walletBalance,
                                      );
                                    }
                                    return;
                                  }
                                  cubit.createAppointment();
                                }
                              : null,
                        );
                      },
                    );
                  },
                ),
                12.verticalSpace,
                CustomButton(
                  title: 'Rate this service',
                  onPressed: () {
                    final cubit = context.read<UpdateCreateAppointmentCubit>();
                    final appointment = state.fetchAppointmentState.data!;
                    AppHelper.showCustomModalBottomSheet<void>(
                      context: context,
                      modal: SubmitReviewBottomSheet(
                        onSubmit: (rating, comment) => cubit.reviewAppointment(
                            rating: rating, comment: comment),
                        onSuccess: () {
                          final freshAppointment =
                              cubit.state.fetchAppointmentState.data!;
                          AppHelper.showAppDialog<void>(
                            context,
                            _ReviewSuccessDialog(
                              onTipPressed: freshAppointment.hasBeenTipped
                                  ? null
                                  : () => TipFlow.startForBooking(context, cubit),
                            ),
                          );
                        },
                      ),
                      isDarkMode: false,
                    );
                  },
                ),
                12.verticalSpace,
                BlocBuilder<UpdateCreateAppointmentCubit,
                    UpdateCreateAppointmentState>(
                  buildWhen: (p, c) => p.tipPayment != c.tipPayment,
                  builder: (context, state) {
                    final cubit = context.read<UpdateCreateAppointmentCubit>();
                    return TipPaymentStatusBanner(
                      progress: state.tipPayment,
                      onCheckStatus: cubit.checkUnresolvedTip,
                      onTryAgain: () => TipFlow.startForBooking(context, cubit),
                    );
                  },
                ),
              ],
              12.verticalSpace,
              if (state.fetchAppointmentState.hasSuccess &&
                  (state.fetchAppointmentState.data!.status.isPendingStatus ||
                      state.fetchAppointmentState.data!.status
                          .isApprovedStatus ||
                      state.fetchAppointmentState.data!.status
                          .isConfirmedStatus)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BlocConsumer<UpdateCreateAppointmentCubit,
                      UpdateCreateAppointmentState>(
                    listenWhen: (previous, current) =>
                        previous.rescheduleBookingState !=
                        current.rescheduleBookingState,
                    listener: (context, state) {
                      if (state.rescheduleBookingState.hasSuccess) {
                        context.router.popAndPush(
                          UpdateCreateAppointmentRoute(
                            portfolioId:
                                state.fetchPortfolioState.data!.id.toString(),
                          ),
                        );

                        context
                            .read<CustomerAppointmentsCubit>()
                            .getAppointments();
                      }

                      if (state.rescheduleBookingState.hasError) {
                        AppHelper.showSnackBar(
                          context,
                          message: (state.rescheduleBookingState.error!
                                      as RemoteException)
                                  .errorResponse
                                  ?.message ??
                              'Failed to reschedule booking',
                        );
                      }
                    },
                    builder: (context, state) {
                      return CustomButton(
                        title: 'Reschedule Booking',
                        isLoading: state.rescheduleBookingState.isLoading,
                        onPressed: () {
                          AppHelper.showAppDialog<void>(
                            context,
                            OnConfirmDialog(
                              title: 'Reschedule Appointment',
                              icon: const Icon(
                                Iconsax.warning_2,
                                size: 60,
                                color: Colors.orange,
                              ),
                              content:
                                  "Are you sure you want to reschedule this appointment? This can't be undone.",
                              onConfirmed: (_) {
                                context
                                    .read<UpdateCreateAppointmentCubit>()
                                    .rescheduleAppointment();
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BlocConsumer<UpdateCreateAppointmentCubit,
                      UpdateCreateAppointmentState>(
                    listenWhen: (previous, current) =>
                        previous.cancelBookingState !=
                        current.cancelBookingState,
                    listener: (context, state) {
                      if (state.cancelBookingState.hasSuccess) {
                        context.router.pop();
                        context
                            .read<CustomerAppointmentsCubit>()
                            .getAppointments();
                      }

                      if (state.cancelBookingState.hasError) {
                        AppHelper.showSnackBar(
                          context,
                          message: (state.rescheduleBookingState.error!
                                      as RemoteException)
                                  .errorResponse
                                  ?.message ??
                              'Failed to cancel booking',
                        );
                      }
                    },
                    builder: (context, state) {
                      return CustomButton(
                        title: 'Cancel Booking',
                        isLoading: state.cancelBookingState.isLoading,
                        onPressed: () {
                          AppHelper.showAppDialog<void>(
                            context,
                            OnConfirmDialog(
                              title: 'Cancel Appointment',
                              icon: const Icon(
                                Iconsax.warning_2,
                                size: 60,
                                color: Colors.orange,
                              ),
                              content:
                                  "Are you sure you want to cancel this appointment? This can't be undone.",
                              onConfirmed: (_) {
                                context
                                    .read<UpdateCreateAppointmentCubit>()
                                    .cancelAppointment();
                              },
                            ),
                          );
                        },
                        gradient: null,
                        background: Colors.white,
                        textColor: AppColors.black,
                        borderColor: AppColors.grey1,
                        isOutline: true,
                      );
                    },
                  ),
                ),
              ],
              CustomButton(
                title: 'Send a Message',
                onPressed: () {
                  context
                      .read<ConversationsCubit>()
                      .startConversation(
                        state.fetchPortfolioState.data!.userId.toString(),
                      )
                      .then(
                    (conversation) {
                      if (conversation == null) return;

                      context.router.push(
                        ConversationListRoute(chatConversation: conversation),
                      );
                    },
                  );
                },
                gradient: null,
                background: const Color(0xff374757),
              ),
              12.verticalSpace,
              const Center(
                child: AppText(
                  text:
                      'By booking, you agree to our terms and cancellation policy.',
                  textAlign: TextAlign.center,
                  fontSize: 12,
                ),
              ),
              12.verticalSpace,
              if (state.fetchAppointmentState.hasSuccess &&
                  (state.fetchAppointmentState.data!.status.isApprovedStatus ||
                      state.fetchAppointmentState.data!.status
                          .isCompletedStatus ||
                      state.fetchAppointmentState.data!.status
                          .isCanceledStatus ||
                      state.fetchAppointmentState.data!.status
                          .isConfirmedStatus ||
                      state.fetchAppointmentState.data!.status.isPendingStatus))
                Center(
                  child: GestureDetector(
                    onTap: () {
                      AppHelper.showCustomModalBottomSheet<void>(
                        context: context,
                        modal: SubmitDisputeBottomSheet(
                          onSubmit: (comment, images) {
                            return context
                                .read<UpdateCreateAppointmentCubit>()
                                .submitDispute(
                                  images: images,
                                  comment: comment,
                                );
                          },
                        ),
                        isDarkMode: false,
                      );
                    },
                    child: const AppText(
                      text: 'Report dispute with this Appointment',
                      textAlign: TextAlign.center,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SelectTimeWIdget extends StatelessWidget {
  const SelectTimeWIdget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCreateAppointmentCubit,
        UpdateCreateAppointmentState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppColors.grey1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                text: 'Select Time',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              12.verticalSpace,
              Builder(
                builder: (context) {
                  if (state.selectedDate == null) {
                    return const Row(
                      children: [
                        AppText(
                          text: 'Please select a date',
                          color: AppColors.grey3,
                        ),
                      ],
                    );
                  }
                  final workingDays =
                      state.fetchSellerDetailsState.data?.workingHours ?? [];

                  final workDurationInHours =
                      state.fetchPortfolioState.data?.duration?.pickNumber() ??
                          0.5;

                  final workDuration = (workDurationInHours * 60).toInt();

                  final timeSlots = workingDays
                          .firstWhere(
                            (element) =>
                                element.day ==
                                AppHelper.dayOfWeekFromDate(
                                  state.selectedDate!,
                                ).toLowerCase(),
                            orElse: WorkingHour.new,
                          )
                          .slots ??
                      [];
                  final availableTimes = <TimeOfDay>[];

                  for (final slot in timeSlots) {
                    final startParts = slot.from!.split(':');
                    final endParts = slot.to!.split(':');
                    var start = TimeOfDay(
                      hour: int.parse(startParts[0]),
                      minute: int.parse(startParts[1].removeAMPM()),
                    );
                    final end = TimeOfDay(
                      hour: int.parse(endParts[0]),
                      minute: int.parse(endParts[1].removeAMPM()),
                    );

                    while (start.hour < end.hour ||
                        (start.hour == end.hour && start.minute < end.minute)) {
                      availableTimes.add(start);
                      var newMinute = start.minute + workDuration;
                      var newHour = start.hour;
                      if (newMinute >= 60) {
                        newHour += newMinute ~/ 60;
                        newMinute = newMinute % 60;
                      }
                      start = TimeOfDay(hour: newHour, minute: newMinute);
                    }
                  }

                  final localizations = MaterialLocalizations.of(context);

                  return SizedBox(
                    width: 600,
                    child: GridView.count(
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      childAspectRatio: 20 / 9,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(availableTimes.length, (index) {
                        final isSelected = state.selectedTime != null &&
                            state.selectedTime!
                                .isAtSameTimeAs(availableTimes[index]);
                        return GestureDetector(
                          onTap: () {
                            context
                                .read<UpdateCreateAppointmentCubit>()
                                .onSelectTime(
                                  availableTimes[index],
                                );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? null : Colors.white,
                              gradient:
                                  isSelected ? AppColors.appgradient : null,
                              border: Border.all(color: AppColors.grey1),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Center(
                              child: AppText(
                                text: localizations
                                    .formatTimeOfDay(availableTimes[index]),
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.black,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class SelectDateWidget extends StatefulWidget {
  const SelectDateWidget({
    super.key,
  });

  @override
  State<SelectDateWidget> createState() => _SelectDateWidgetState();
}

class _SelectDateWidgetState extends State<SelectDateWidget> {
  final GlobalKey<MonthViewState> _monthViewKey = GlobalKey<MonthViewState>();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCreateAppointmentCubit,
        UpdateCreateAppointmentState>(
      builder: (context, state) {
        final isLoading = state.fetchSellerDetailsState.isLoading ||
            state.fetchPortfolioState.isLoading;
        final workingDays =
            state.fetchSellerDetailsState.data?.workingHours ?? [];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppColors.grey1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                Row(
                  children: [
                    const AppText(text: 'Loading....'),
                    8.horizontalSpace,
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                )
              else
                const AppText(
                  text: 'Select Date',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              SizedBox(
                width: double.infinity,
                height: 400.h,
                child: MonthView(
                  key: _monthViewKey,
                  showBorder: false,
                  headerBuilder: (date) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              text:
                                  '${AppHelper.monthName(date.month)} ${date.year}',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              _monthViewKey.currentState?.previousPage();
                            },
                          ),
                          12.horizontalSpace,
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              _monthViewKey.currentState?.nextPage();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  cellAspectRatio: 1,
                  hideDaysNotInMonth: true,
                  cellBuilder: (
                    date,
                    event,
                    isToday,
                    isInMonth,
                    hideDaysNotInMonth,
                  ) {
                    final isSelected = state.selectedDate != null &&
                        AppHelper.isSameDate(state.selectedDate!, date);

                    final day = AppHelper.dayOfWeekFromDate(date).toLowerCase();

                    final workDay = workingDays.firstWhere(
                      (element) => element.day == day,
                      orElse: WorkingHour.new,
                    );

                    final isWorkingDay = workDay.slots != null &&
                        workDay.slots!.isNotEmpty &&
                        date.isAfter(
                          DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                        );

                    if (!isInMonth && hideDaysNotInMonth) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: isWorkingDay
                          ? () {
                              if (isLoading) return;
                              context
                                  .read<UpdateCreateAppointmentCubit>()
                                  .onSelectDate(date);
                            }
                          : null,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey1),
                          gradient: isSelected ? AppColors.appgradient : null,
                          color: isSelected
                              ? null
                              : isToday
                                  ? AppColors.primaryColor
                                      .withValues(alpha: 0.3)
                                  : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: AppText(
                          text: date.day.toString(),
                          color: isSelected || isToday
                              ? AppColors.white
                              : isWorkingDay
                                  ? AppColors.black
                                  : AppColors.grey1,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewSuccessDialog extends StatelessWidget {
  const _ReviewSuccessDialog({this.onTipPressed});

  final VoidCallback? onTipPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.tick_square, size: 64, color: Color(0xff008000)),
          16.verticalSpace,
          const AppText(
            text: 'Thank you for your feedback!',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            textAlign: TextAlign.center,
          ),
          8.verticalSpace,
          const AppText(
            text: 'Your review has been submitted.',
            color: AppColors.grey3,
            textAlign: TextAlign.center,
          ),
          24.verticalSpace,
          if (onTipPressed != null) ...[
            CustomButton(
              title: 'Tip Your Stylist',
              onPressed: () {
                Navigator.of(context).pop();
                onTipPressed!();
              },
            ),
            12.verticalSpace,
          ],
          CustomButton(
            title: 'Close',
            gradient: null,
            background: const Color(0xff374757),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class SubmitReviewBottomSheet extends StatefulWidget {
  const SubmitReviewBottomSheet({
    required this.onSubmit,
    this.onSuccess,
    super.key,
  });

  final Future<void> Function(int rating, String comment) onSubmit;
  final VoidCallback? onSuccess;

  @override
  State<SubmitReviewBottomSheet> createState() =>
      _SubmitReviewBottomSheetState();
}

class _SubmitReviewBottomSheetState extends State<SubmitReviewBottomSheet> {
  int _rating = 0;
  String _comment = '';
  bool _isSubmitting = false;

  Widget _buildStar(int index) {
    final selected = index <= _rating;
    return GestureDetector(
      onTap: () {
        setState(() {
          _rating = index;
        });
      },
      child: Icon(
        selected ? Icons.star : Icons.star_border,
        color: selected ? Colors.amber : AppColors.grey3,
        size: 32,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      AppHelper.showSnackBar(context, message: 'Please select a rating');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_rating, _comment.trim());
      final onSuccess = widget.onSuccess;
      if (mounted) {
        Navigator.of(context).pop(true);
        onSuccess?.call();
      }
    } catch (e) {
      AppHelper.showSnackBar(
        context,
        message: 'Failed to submit review. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                    const AppText(
                      text: 'Leave a Review',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    12.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => _buildStar(i + 1)),
                    ),
                    12.verticalSpace,
                    CustomTextField(
                      label: 'Write a comment (optional)',
                      onChanged: (v) => _comment = v,
                      maxLines: 4,
                    ),
                    16.verticalSpace,
                    CustomButton(
                      title: 'Submit Review',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleSubmit,
                    ),
                    12.verticalSpace,
                    CustomButton(
                      title: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(false),
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

class SubmitDisputeBottomSheet extends StatefulWidget {
  const SubmitDisputeBottomSheet({
    required this.onSubmit,
    super.key,
  });

  final Future<void> Function(String comment, List<String> imagePaths) onSubmit;

  @override
  State<SubmitDisputeBottomSheet> createState() =>
      _SubmitDisputeBottomSheetState();
}

class _SubmitDisputeBottomSheetState extends State<SubmitDisputeBottomSheet> {
  String _comment = '';
  List<String> _imagePaths = [];
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (_comment.trim().isEmpty && _imagePaths.isEmpty) {
      AppHelper.showSnackBar(
        context,
        message: 'Please provide a comment or attach at least one image',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_comment.trim(), _imagePaths);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      AppHelper.showSnackBar(context,
          message: 'Failed to submit dispute. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPickedList() {
    if (_imagePaths.isEmpty) {
      return const AppText(
        text: 'No images attached',
        color: AppColors.grey3,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _imagePaths.map((p) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.image, size: 18, color: AppColors.grey3),
              8.horizontalSpace,
              Expanded(
                child: AppText(
                  text: p.split(RegExp(r'[\\/]').toString()).isNotEmpty
                      ? p.split('/').last
                      : p,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _imagePaths.remove(p));
                },
                child: const Icon(Icons.close, size: 18, color: Colors.red),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                const AppText(
                  text: 'Report a Dispute',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                12.verticalSpace,
                CustomTextField(
                  label: 'Describe your issue',
                  onChanged: (v) => _comment = v,
                  maxLines: 5,
                ),
                12.verticalSpace,
                MultiDocumentPicker(
                  label: 'Attach images',
                  onSelected: (images) {
                    setState(() {
                      _imagePaths = images;
                    });
                  },
                ),
                12.verticalSpace,
                _buildPickedList(),
                16.verticalSpace,
                CustomButton(
                  title: 'Submit Dispute',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleSubmit,
                ),
                12.verticalSpace,
                CustomButton(
                  title: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(false),
                  gradient: null,
                  background: const Color(0xff374757),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment method picker — customer chooses wallet vs card for this booking.
// Selection is stored on UpdateCreateAppointmentCubit.state.paymentMethod
// and consumed by the Book / Book Again onPressed handlers.
// ---------------------------------------------------------------------------

class PaymentMethodPicker extends StatelessWidget {
  const PaymentMethodPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerProfileMgtCubit, CustomerProfileMgtState>(
      buildWhen: (p, c) => p.walletState != c.walletState,
      builder: (context, profileState) {
        final walletBalance = profileState.walletState.data?.balance ?? 0.0;
        return BlocBuilder<UpdateCreateAppointmentCubit,
            UpdateCreateAppointmentState>(
          buildWhen: (p, c) => p.paymentMethod != c.paymentMethod,
          builder: (context, state) {
            return PaymentMethodSelector(
              selected: state.paymentMethod,
              walletBalance: walletBalance,
              onSelected: context
                  .read<UpdateCreateAppointmentCubit>()
                  .setPaymentMethod,
            );
          },
        );
      },
    );
  }
}
