import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/appointments/stylist_appointments/cubit/seller_appoint_mgt_cubit.dart';
import 'package:snip_fair/features/appointments/stylist_appointments/details/cubit/seller_appointment_details_cubit.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';

@RoutePage()
class SellerAppointmentDetailsScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const SellerAppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  final String? appointmentId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SellerAppointmentDetailsCubit>();
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Appointment Details',
      ),
      body: BlocListener<SellerAppointmentDetailsCubit,
          SellerAppointmentDetailsState>(
        listenWhen: (previous, current) =>
            previous.updateAppointmentState != current.updateAppointmentState,
        listener: (context, state) {
          if (state.updateAppointmentState.hasError) {
            AppHelper.showAppDialog(
                context,
                OnFailDialogContent(
                    subtext:
                        (state.updateAppointmentState.error as RemoteException)
                                .errorResponse
                                ?.message ??
                            '',
                    onDoneCallback: (_) {}));
          }

          if (state.updateAppointmentState.hasSuccess) {
            context.read<SellerAppointMgtCubit>().getAppointments();
          }
        },
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await cubit.getAppointmentDetails(appointmentId!);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: BlocBuilder<SellerAppointmentDetailsCubit,
                  SellerAppointmentDetailsState>(
                builder: (context, state) {
                  if (state.fetchAppointmentDetailsState.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state.fetchAppointmentDetailsState.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${state.fetchAppointmentDetailsState.error}',
                      ),
                    );
                  } else if (state.fetchAppointmentDetailsState.data == null) {
                    return const Center(
                      child: Text('No appointment details available.'),
                    );
                  }

                  final appointment = state.fetchAppointmentDetailsState.data!;

                  return Column(
                    children: [
                      if (state.updateAppointmentState.isLoading) ...[
                        const LinearProgressIndicator(),
                        16.verticalSpace,
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              text: 'Appointment Details',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const Divider(),
                            12.verticalSpace,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  text: 'Order Time: ',
                                  fontWeight: FontWeight.w600,
                                ),
                                80.horizontalSpace,
                                Expanded(
                                  child: AppText(
                                    text: appointment.createdAt
                                            .toShortDateString() ??
                                        'N/A',
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                            8.verticalSpace,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  text: 'Booking ID: ',
                                  fontWeight: FontWeight.w600,
                                ),
                                80.horizontalSpace,
                                const Spacer(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SelectableText(
                                      appointment.bookingId?.toString() ??
                                          'N/A',
                                      textAlign: TextAlign.end,
                                    ),
                                    4.horizontalSpace,
                                    GestureDetector(
                                      onTap: () {
                                        AppHelper.copyToClipboard(
                                          context,
                                          appointment.bookingId?.toString() ??
                                              'N/A',
                                        );
                                      },
                                      child: const Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            16.verticalSpace,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    AppHelper.showImagePreview(
                                      context,
                                      imageUrl: appointment.customer?.avatar
                                          ?.toString()
                                          .completeImagePath(),
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        appointment.customer?.avatar != null
                                            ? CachedNetworkImageProvider(
                                                appointment.customer!.avatar!
                                                    .toString()
                                                    .completeImagePath(),
                                              )
                                            : null,
                                    child: appointment.customer?.avatar != null
                                        ? null
                                        : AppText(
                                            text: appointment.customer
                                                            ?.firstName !=
                                                        null &&
                                                    appointment.customer
                                                            ?.lastName !=
                                                        null
                                                ? AppHelper.initialsFromName(
                                                    appointment
                                                        .customer!.firstName!,
                                                    appointment
                                                        .customer!.lastName!,
                                                  )
                                                : 'N/A',
                                            color: AppColors.grey3,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                  ),
                                ),
                                8.horizontalSpace,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        text: appointment.customer?.name ?? '',
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      const AppText(
                                        text: 'Customer',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ),
                                12.horizontalSpace,
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(23),
                                    color: appointment.status
                                        ?.toStatusColor()
                                        .withOpacity(0.1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  child: AppText(
                                    text: appointment.status?.toStatusText() ??
                                        '',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: appointment.status.toStatusColor(),
                                  ),
                                ),
                              ],
                            ),
                            12.verticalSpace,
                          ],
                        ),
                      ),
                      16.verticalSpace,
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              text: 'Service & Pricing',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const Divider(),
                            12.verticalSpace,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: appointment.portfolio?.title != null
                                      ? appointment.portfolio!.title!
                                      : 'Service Title: ',
                                  fontWeight: FontWeight.w600,
                                ),
                                40.horizontalSpace,
                                Expanded(
                                  child: AppText(
                                    text: appointment.portfolio?.price
                                            ?.formatAmount() ??
                                        'N/A',
                                    textAlign: TextAlign.end,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            8.verticalSpace,
                          ],
                        ),
                      ),
                      16.verticalSpace,
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              text: 'Appointment Date & Time',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const Divider(),
                            12.verticalSpace,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  text: 'Date: ',
                                  fontWeight: FontWeight.w600,
                                ),
                                100.horizontalSpace,
                                Expanded(
                                  child: AppText(
                                    text: appointment.appointmentDate ?? 'N/A',
                                    textAlign: TextAlign.end,
                                    color: AppColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            8.verticalSpace,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  text: 'Time: ',
                                  fontWeight: FontWeight.w600,
                                ),
                                100.horizontalSpace,
                                Expanded(
                                  child: AppText(
                                    text: TimeOfDay(
                                                hour: int.parse(appointment
                                                    .appointmentTime!
                                                    .split(':')[0]),
                                                minute: int.parse(appointment
                                                    .appointmentTime!
                                                    .split(':')[1]
                                                    .removeAMPM()))
                                            .format(context) ??
                                        'N/A',
                                    textAlign: TextAlign.end,
                                    color: AppColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            8.verticalSpace,
                          ],
                        ),
                      ),
                      16.verticalSpace,
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              text: 'Appointment notes',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const Divider(),
                            12.verticalSpace,
                            AppText(
                              text: appointment.extra != null
                                  ? appointment.extra!.toString()
                                  : 'No notes available',
                            ),
                            8.verticalSpace,
                          ],
                        ),
                      ),
                      16.verticalSpace,
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: state.fetchAppointmentDetailsState.data!.status
                              .toStatusColor()
                              .withOpacity(0.1),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Center(
                          child: AppText(
                            text: state
                                    .fetchAppointmentDetailsState.data!.status
                                    ?.toStatusText() ??
                                '',
                            fontWeight: FontWeight.w600,
                            color: state
                                .fetchAppointmentDetailsState.data!.status
                                .toStatusColor(),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              text: 'Appointment Actions',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const Divider(),
                            12.verticalSpace,
                            if (state.fetchAppointmentDetailsState.data!.status
                                .isPendingStatus) ...[
                              CustomButton(
                                title: 'Accept Appointment',
                                onPressed: cubit.acceptAppointment,
                              ),
                              12.verticalSpace,
                              CustomButton(
                                title: 'Reject Appointment',
                                onPressed: cubit.rejectAppointment,
                                gradient: null,
                                background: Colors.red,
                              ),
                              12.verticalSpace,
                            ],
                            if (state.fetchAppointmentDetailsState.data!.status
                                .isApprovedStatus) ...[
                              CustomButton(
                                title: 'Verify Appointment',
                                onPressed: () {
                                  showCodeEntryBottomSheet(
                                    context,
                                    title: 'Enter Verification Code',
                                    hint: 'SF-XXXXXX',
                                    onSubmit: cubit.confirmAppointment,
                                  );
                                },
                              ),
                              12.verticalSpace,
                            ],
                            if (state.fetchAppointmentDetailsState.data!.status
                                .isConfirmedStatus) ...[
                              CustomButton(
                                title: 'Mark as Completed',
                                onPressed: () {
                                  showCodeEntryBottomSheet(
                                    context,
                                    title: 'Enter Completion Code',
                                    hint: 'CP-XXXXXX',
                                    onSubmit: cubit.completeAppointment,
                                  );
                                },
                              ),
                              12.verticalSpace,
                            ],
                            CustomButton(
                              title: 'Send a Message',
                              onPressed: () {
                                context
                                    .read<ConversationsCubit>()
                                    .startConversation(
                                      state.fetchAppointmentDetailsState.data!
                                          .customerId!
                                          .toString(),
                                    )
                                    .then(
                                  (conversation) {
                                    if (conversation == null) return;

                                    context.router.push(
                                      ConversationListRoute(
                                        chatConversation: conversation,
                                      ),
                                    );
                                  },
                                );
                              },
                              gradient: null,
                              background: const Color(0xff374757),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SellerAppointmentDetailsCubit>()
        ..getAppointmentDetails(appointmentId!),
      child: this,
    );
  }
}

class CodeEntryBottomSheet extends StatefulWidget {
  final String title;
  final String hint;
  final Future<void> Function(String code) onSubmit;

  const CodeEntryBottomSheet({
    Key? key,
    required this.title,
    required this.hint,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<CodeEntryBottomSheet> createState() => _CodeEntryBottomSheetState();
}

class _CodeEntryBottomSheetState extends State<CodeEntryBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModalPill(),
              12.verticalSpace,
              AppText(
                text: widget.title,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              5.verticalSpace,
              const AppText(
                text: 'Please enter the code provided by the customer',
                textAlign: TextAlign.center,
              ),
              12.verticalSpace,
              TextField(
                controller: _controller,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                decoration: AppColors.inputDecoration.copyWith(
                  hintText: widget.hint,
                  errorText: _error,
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
              16.verticalSpace,
              Column(
                children: [
                  CustomButton(
                    title: _isLoading ? 'Submitting...' : 'Submit',
                    onPressed: _isLoading ? null : _handleSubmit,
                  ),
                  12.verticalSpace,
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop(false);
                          },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.grey.shade200,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const AppText(
                      text: 'Cancel',
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show the bottom sheet. Returns true if submission succeeded, false or null otherwise.
Future<bool?> showCodeEntryBottomSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required Future<void> Function(String code) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => CodeEntryBottomSheet(
      title: title,
      hint: hint,
      onSubmit: onSubmit,
    ),
  );
}
