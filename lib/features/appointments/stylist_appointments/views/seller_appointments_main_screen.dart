import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/features/appointments/stylist_appointments/cubit/seller_appoint_mgt_cubit.dart';

@RoutePage()
class SellerAppointmentsMainScreen extends StatelessWidget {
  const SellerAppointmentsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<SellerAppointMgtCubit>().getCalendarAppointment();
          context.router.push(const SellerAppointmentsCalendarRoute());
        },
        icon: const Icon(Icons.calendar_month),
        label: const Text('Calendar'),
      ),
      body: BlocBuilder<SellerAppointMgtCubit, SellerAppointMgtState>(
        builder: (context, state) {
          final appointments = state.appointments.data ?? <StylistAppointment>[];

          return Column(
            children: [
              if (state.appointments.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<SellerAppointMgtCubit>().getAppointments();
                  },
                  child: InfiniteList(
                    physics: const AlwaysScrollableScrollPhysics(),
                    emptyBuilder: (context) => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: AppText(
                          text: 'No Appointments found',
                          fontSize: 16,
                          color: AppColors.grey3,
                        ),
                      ),
                    ),
                    shrinkWrap: true,
                    centerEmpty: true,
                    centerLoading: true,
                    onFetchData: () =>
                        context.read<SellerAppointMgtCubit>().getAppointments(loadMore: true),
                    hasReachedMax: state.paginationData.hasReachedMax,
                    isLoading: state.appointments.isLoading || state.paginationData.isLoadingMore,
                    itemBuilder: (context, index) {
                      return AppointmentCard(
                        appointment: appointments[index],
                      );
                    },
                    separatorBuilder: (context, index) => 12.verticalSpace,
                    itemCount: appointments.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    required this.appointment,
    super.key,
  });

  final StylistAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  AppHelper.showImagePreview(
                    context,
                    imageUrl: appointment.customer?.avatar != null
                        ? appointment.customer!.avatar!.toString().completeImagePath()
                        : null,
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: appointment.customer?.avatar != null
                      ? CachedNetworkImageProvider(
                          appointment.customer!.avatar!.toString().completeImagePath(),
                        )
                      : null,
                  child: appointment.customer?.avatar != null
                      ? null
                      : AppText(
                          text: appointment.customer?.firstName != null &&
                                  appointment.customer?.lastName != null
                              ? AppHelper.initialsFromName(
                                  appointment.customer!.firstName!,
                                  appointment.customer!.lastName!,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: appointment.portfolio?.title ?? '',
                      fontWeight: FontWeight.w600,
                    ),
                    AppText(
                      text: appointment.customer?.name ?? '',
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
              12.horizontalSpace,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: appointment.status.toStatusColor().withOpacity(0.1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: AppText(
                  text: appointment.status?.toStatusText() ?? '',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: appointment.status.toStatusColor(),
                ),
              ),
            ],
          ),
          12.verticalSpace,

          Row(
            children: [
              const Icon(
                Iconsax.calendar,
                size: 15,
                color: AppColors.grey3,
              ),
              4.horizontalSpace,
              AppText(
                text: appointment.appointmentDate ?? '',
                fontSize: 12,
                color: AppColors.grey3,
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Iconsax.clock,
                size: 15,
                color: AppColors.grey3,
              ),
              4.horizontalSpace,
              AppText(
                text: appointment.appointmentTime ?? '',
                fontSize: 12,
                color: AppColors.grey3,
              ),
            ],
          ),
          12.verticalSpace,
          AppText(
            text: appointment.portfolio?.price != null
                ? appointment.portfolio!.price!.formatAmount()
                : 'Price not available',
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
          12.verticalSpace,
          SizedBox(
            height: 40,
            child: CustomButton(
              title: 'View Details',
              icon: const Icon(Iconsax.document),
              onPressed: () {
                context.router.push(
                  SellerAppointmentDetailsRoute(
                    appointmentId: appointment.id?.toString(),
                  ),
                );
              },
              background: AppColors.grey1,
              textColor: AppColors.black,
              gradient: null,
              isOutline: true,
            ),
          ),
          // 8.verticalSpace,
          // if (appointment.status?.isPendingStatus ?? false)
          //   SizedBox(
          //     height: 40,
          //     child: CustomButton(
          //       title: 'Cancel',
          //       onPressed: () {},
          //       textColor: AppColors.primaryColor,
          //       gradient: null,
          //       isOutline: true,
          //     ),
          //   ),
        ],
      ),
    );
  }
}
