import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
// ignore: unused_import
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/features/appointments/customer_appointments/cubit/customer_appointments_cubit.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

@RoutePage()
class AppointementsMainScreen extends StatelessWidget {
  const AppointementsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<CustomerAppointmentsCubit>().getCalendarAppointment();
          context.router.push(const CustomerAppointmentsCalendarRoute());
        },
        icon: const Icon(Icons.calendar_month),
        label: const Text('Calendar'),
      ),
      body: BlocBuilder<CustomerAppointmentsCubit, CustomerAppointmentsState>(
        builder: (context, state) {
          final appointments =
              state.appointments.data ?? <CustomerAppointment>[];

          return Column(
            children: [
              if (state.appointments.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<CustomerAppointmentsCubit>().getAppointments();
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
                    onFetchData: () => context
                        .read<CustomerAppointmentsCubit>()
                        .getAppointments(loadMore: true),
                    hasReachedMax: state.paginationData.hasReachedMax,
                    isLoading: state.appointments.isLoading ||
                        state.paginationData.isLoadingMore,
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

  final CustomerAppointment appointment;

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
                  context.router.push(
                    StylistSellerDetailsRoute(id: appointment.stylistId),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: appointment.stylist?.avatar != null
                      ? CachedNetworkImageProvider(
                          appointment.stylist!.avatar!.completeImagePath(),
                        )
                      : null,
                  child: appointment.stylist?.avatar != null
                      ? null
                      : AppText(
                          text: appointment.stylist?.firstName != null &&
                                  appointment.stylist?.lastName != null
                              ? AppHelper.initialsFromName(
                                  appointment.stylist!.firstName!,
                                  appointment.stylist!.lastName!,
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
                child: GestureDetector(
                  onTap: () {
                    context.router.push(
                      StylistSellerDetailsRoute(id: appointment.stylistId),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text:
                            appointment.stylist?.stylistProfile?.businessName ??
                                '',
                        fontWeight: FontWeight.w600,
                      ),
                      AppText(
                        text: appointment.stylist?.name ?? '',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
              ),
              12.horizontalSpace,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: appointment.status.toStatusColor().withOpacity(0.1),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          AppText(
            text: appointment.portfolio?.title ?? '',
            fontWeight: FontWeight.w600,
          ),
          Row(
            children: [
              const Icon(
                Iconsax.location,
                size: 15,
                color: AppColors.grey3,
              ),
              4.horizontalSpace,
              Expanded(
                child: AppText(
                  text: appointment.stylist?.country ?? '',
                  fontSize: 12,
                  color: AppColors.grey3,
                ),
              ),
            ],
          ),
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
                context.pushRoute(
                  UpdateCreateAppointmentRoute(
                    appointmentId: appointment.id.toString(),
                    portfolioId: appointment.portfolioId.toString(),
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
