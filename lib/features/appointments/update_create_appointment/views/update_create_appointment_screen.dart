// ignore_for_file: unawaited_futures

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/domain/entities/seller_details/working_hour.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_verification/views/seller_profile_verification_screen.dart';
import 'package:snip_fair/features/appointments/customer_appointments/cubit/customer_appointments_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';

@RoutePage()
class UpdateCreateAppointmentScreen extends StatefulWidget
    implements AutoRouteWrapper {
  const UpdateCreateAppointmentScreen({
    super.key,
    this.portfolioId,
    this.appointmentId,
    this.portfolio,
    this.appointment,
  });

  final String? portfolioId;
  final String? appointmentId;
  final SellerPortfolio? portfolio;
  final CustomerAppointment? appointment;

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UpdateCreateAppointmentCubit>()
        ..initialize(
          context,
          portfolioId: portfolioId,
          appointmentId: appointmentId,
          portfolio: portfolio,
          appointment: appointment,
        ),
      child: this,
    );
  }

  @override
  State<UpdateCreateAppointmentScreen> createState() =>
      _UpdateCreateAppointmentScreenState();
}

class _UpdateCreateAppointmentScreenState
    extends State<UpdateCreateAppointmentScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerProfileMgtCubit, CustomerProfileMgtState>(
      builder: (context, state) {
        final view = Scaffold(
          appBar: CustomAppBar(
            title: widget.appointmentId != null
                ? 'Update Appointment'
                : 'Book Appointment',
          ),
          body: SafeArea(
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
                  context.read<CustomerAppointmentsCubit>().getAppointments();
                  context.read<CustomerProfileMgtCubit>()
                    ..getWallet()
                    ..getWalletTransactions();
                } else if (state.updateOrCreateAppointmentState.hasError) {
                  AppHelper.showAppDialog<void>(
                    context,
                    OnFailDialogContent(
                      subtext: (state.updateOrCreateAppointmentState.error!
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
              buildWhen: (previous, current) =>
                  previous.fetchPortfolioState != current.fetchPortfolioState ||
                  previous.fetchAppointmentState !=
                      current.fetchAppointmentState,
              builder: (context, state) {
                if (state.fetchPortfolioState.isLoading ||
                    state.fetchAppointmentState.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return SingleChildScrollView(
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
                );
              },
            ),
          ),
        );

        if (state.initializePaymentState.isLoading) {
          return Stack(
            children: [
              view,
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
        }
        return view;
      },
    );
  }

  BlocBuilder<UpdateCreateAppointmentCubit, UpdateCreateAppointmentState>
      buildYourInformationView() {
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
                initialText: state.fetchPortfolioState.data?.user?.name ?? '',
                readOnly: true,
              ),
              12.verticalSpace,
              CustomTextField(
                label: 'Email',
                isRequired: true,
                initialText: state.fetchPortfolioState.data?.user?.email ?? '',
                readOnly: true,
              ),
              12.verticalSpace,
              CustomPlaceSearchField(
                label: 'Location',
                onSelected: (place) {
                  if (place == null) return;
                  context
                      .read<UpdateCreateAppointmentCubit>()
                      .onAddressChanged(place.address);
                },
                readOnly: state.fetchAppointmentState.hasSuccess,
                initialPlace: state.fetchPortfolioState.data?.user?.country !=
                        null
                    ? GeoPlace(
                        address: state.fetchPortfolioState.data!.user!.country!,
                        lat: 0,
                        lng: 0,
                      )
                    : null,
              ),
              12.verticalSpace,
              CustomTextField(
                label: 'Special Requests or Notes (Optional)',
                onChanged: (value) {
                  context
                      .read<UpdateCreateAppointmentCubit>()
                      .onNotesChanged(value);
                },
                readOnly: state.fetchAppointmentState.hasSuccess,
                initialText:
                    state.fetchAppointmentState.data?.extra?.toString() ?? '',
                maxLines: 4,
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
            context.router.push(StylistSellerDetailsRoute(
              id: state.fetchPortfolioState.data!.user!.id.toString(),
            ));
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
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                      ),
                      AppText(
                        text: state.fetchPortfolioState.data?.user
                                ?.stylistProfile?.businessName ??
                            '',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
                8.horizontalSpace,
                AppText(
                  text: state.fetchSellerDetailsState.hasSuccess
                      ? state.fetchSellerDetailsState.data!.distance != null
                          ? '${state.fetchSellerDetailsState.data!.distance?.round()} km away'
                          : ''
                      : '',
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
                      text: state.fetchAppointmentState.data!.status
                              ?.toStatusText() ??
                          '',
                      fontWeight: FontWeight.w600,
                      color: state.fetchAppointmentState.data!.status
                          .toStatusColor(),
                    ),
                  ),
                ),
              AppText(
                text: 'Booking Summary',
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
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
                              children: [
                                AppText(
                                  text: state.fetchAppointmentState.data
                                          ?.appointmentCode ??
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
                                            ?.appointmentCode ??
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
                )
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
                      const AppText(
                        text: 'Thank you for using Snipfair',
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
                                          ?.completionCode ??
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
                                            ?.completionCode ??
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
                      CustomButton(
                        title: 'Rate this service',
                        onPressed: () {
                          AppHelper.showCustomModalBottomSheet<void>(
                            context: context,
                            modal: SubmitReviewBottomSheet(
                              onSubmit: (rating, comment) {
                                return context
                                    .read<UpdateCreateAppointmentCubit>()
                                    .reviewAppointment(
                                      rating: rating,
                                      comment: comment,
                                    );
                              },
                            ),
                            isDarkMode: false,
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
              if (!state.fetchAppointmentState.hasSuccess)
                BlocConsumer<CustomerProfileMgtCubit, CustomerProfileMgtState>(
                  listenWhen: (previous, current) =>
                      previous.initializePaymentState !=
                      current.initializePaymentState,
                  listener: (context, profileState) async {
                    final cubit = context.read<UpdateCreateAppointmentCubit>();
                    if (profileState.initializePaymentState.hasSuccess) {
                      final paymentComplete = await AppHelper.showPaymentDialog(
                        context,
                        profileState.initializePaymentState.data!,
                      );
                      if (paymentComplete) {
                        cubit.createAppointment();
                      }
                    }
                  },
                  builder: (context, profileState) {
                    final walletBalance =
                        profileState.walletState.data?.balance ?? 0.0;

                    return CustomButton(
                      title: 'Book Appointment',
                      isLoading: state.updateOrCreateAppointmentState.isLoading,
                      onPressed: state.canBookAppointment
                          ? () async {
                              final profileCubit =
                                  context.read<CustomerProfileMgtCubit>();
                              final cubit =
                                  context.read<UpdateCreateAppointmentCubit>();
                              final servicePrice =
                                  state.fetchPortfolioState.data?.price ?? 0.0;

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
                                  profileCubit.initialisePayfastDeposit(
                                    type: 'deposit',
                                    amount: (servicePrice - walletBalance)
                                        .toStringAsFixed(2),
                                    portfolioId: state
                                        .fetchPortfolioState.data!.id
                                        .toString(),
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
                  state.fetchAppointmentState.data!.status.isCompletedStatus)
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
                          final paymentComplete =
                              await AppHelper.showPaymentDialog(
                            context,
                            profileState.initializePaymentState.data!,
                          );
                          if (paymentComplete) {
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
                              state.updateOrCreateAppointmentState.isLoading,
                          onPressed: state.canBookAppointment
                              ? () async {
                                  final profileCubit =
                                      context.read<CustomerProfileMgtCubit>();
                                  final cubit = context
                                      .read<UpdateCreateAppointmentCubit>();
                                  final servicePrice =
                                      state.fetchPortfolioState.data?.price ??
                                          0.0;

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
                                      profileCubit.initialisePayfastDeposit(
                                        type: 'deposit',
                                        amount: (servicePrice - walletBalance)
                                            .toStringAsFixed(2),
                                        portfolioId: state
                                            .fetchPortfolioState.data!.id
                                            .toString(),
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
                            portfolio: state.fetchPortfolioState.data,
                          ),
                        );

                        context
                            .read<CustomerAppointmentsCubit>()
                            .getAppointments();
                      }

                      if (state.rescheduleBookingState.hasError) {
                        AppHelper.showSnackBar(context,
                            message: (state.rescheduleBookingState.error!
                                        as RemoteException)
                                    .errorResponse
                                    ?.message ??
                                'Failed to reschedule booking');
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
                        AppHelper.showSnackBar(context,
                            message: (state.rescheduleBookingState.error!
                                        as RemoteException)
                                    .errorResponse
                                    ?.message ??
                                'Failed to cancel booking');
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
                      minute: int.parse(startParts[1]),
                    );
                    final end = TimeOfDay(
                      hour: int.parse(endParts[0]),
                      minute: int.parse(endParts[1]),
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
                                text: availableTimes[index].format(context),
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
                              fontSize: 14.sp,
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

class PaymentSummaryWidget extends StatelessWidget {
  const PaymentSummaryWidget({
    required this.servicePrice,
    required this.walletBalance,
    super.key,
  });

  final double servicePrice;
  final double walletBalance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          12.verticalSpace,
          const ModalPill(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: 'Payment Summary',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
                16.verticalSpace,
                Container(
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: 'Service Price',
                          ),
                          AppText(
                            text: '${servicePrice.formatAmount()}',
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      8.verticalSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: 'Wallet Balance',
                          ),
                          AppText(
                            text: '-${walletBalance.formatAmount()}',
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: 'Amount to Pay',
                            fontWeight: FontWeight.w600,
                          ),
                          AppText(
                            text:
                                '\$${(servicePrice - walletBalance).clamp(0, servicePrice).toStringAsFixed(2)}',
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
                CustomButton(
                  title: 'Proceed to Pay',
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                12.verticalSpace,
                CustomButton(
                  title: 'Cancel',
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
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

class SubmitReviewBottomSheet extends StatefulWidget {
  const SubmitReviewBottomSheet({
    required this.onSubmit,
    super.key,
  });

  final Future<void> Function(int rating, String comment) onSubmit;

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
      if (mounted) Navigator.of(context).pop(true);
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
      AppHelper.showSnackBar(context,
          message: 'Please provide a comment or attach at least one image');
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
