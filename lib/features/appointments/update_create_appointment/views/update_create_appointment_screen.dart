import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/presentation/app.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';

@RoutePage()
class UpdateCreateAppointmentScreen extends StatelessWidget
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:
            appointmentId != null ? 'Update Appointment' : 'Book Appointment',
      ),
      body: BlocBuilder<UpdateCreateAppointmentCubit,
          UpdateCreateAppointmentState>(
        builder: (context, state) {
          if (state.fetchPortfolioState.isLoading ||
              state.fetchAppointmentState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
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
                          image: state.fetchPortfolioState.data?.user?.avatar !=
                                  null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    state
                                        .fetchPortfolioState.data!.user!.avatar!
                                        .completeImagePath(),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: AppColors.appgradient,
                        ),
                        child:
                            state.fetchPortfolioState.data?.user?.avatar == null
                                ? AppText(
                                    text: state.fetchPortfolioState.data?.user
                                                    ?.firstName !=
                                                null &&
                                            state.fetchPortfolioState.data?.user
                                                    ?.lastName !=
                                                null
                                        ? AppHelper.initialsFromName(
                                            state.fetchPortfolioState.data!
                                                .user!.firstName!,
                                            state.fetchPortfolioState.data!
                                                .user!.lastName!,
                                          )
                                        : 'N/A',
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
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
                            ),
                            AppText(
                              text: state.fetchPortfolioState.data?.user
                                      ?.stylistProfile?.businessName ??
                                  '',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                      8.horizontalSpace,
                      AppText(
                        text: state.fetchSellerDetailsState.hasSuccess
                            ? state.fetchSellerDetailsState.data!.distance !=
                                    null
                                ? '${state.fetchSellerDetailsState.data!.distance?.round()} km away'
                                : ''
                            : '',
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
                const SelectDateWidget(),
                16.verticalSpace,
                Container(
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
                                  fontSize: 14,
                                  color: AppColors.grey3,
                                ),
                              ],
                            );
                          }
                          final workingDays = state
                                  .fetchSellerDetailsState.data?.workingHours ??
                              [];

                          final timeSlots = workingDays
                                  .firstWhere(
                                    (element) =>
                                        element.day ==
                                        AppHelper.dayOfWeekFromDate(
                                          state.selectedDate!,
                                        ).toLowerCase(),
                                    orElse: () => workingDays.first,
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
                                (start.hour == end.hour &&
                                    start.minute < end.minute)) {
                              availableTimes.add(start);
                              var newMinute = start.minute + 30;
                              var newHour = start.hour;
                              if (newMinute >= 60) {
                                newHour += newMinute ~/ 60;
                                newMinute = newMinute % 60;
                              }
                              start =
                                  TimeOfDay(hour: newHour, minute: newMinute);
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
                              children:
                                  List.generate(availableTimes.length, (index) {
                                final isSelected = state.selectedTime != null &&
                                    state.selectedTime!
                                        .isAtSameTimeAs(availableTimes[index]);
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected ? null : Colors.white,
                                    gradient: isSelected
                                        ? AppColors.appgradient
                                        : null,
                                    border: Border.all(color: AppColors.grey1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      context
                                          .read<UpdateCreateAppointmentCubit>()
                                          .onSelectTime(
                                            availableTimes[index],
                                          );
                                    },
                                    child: Center(
                                      child: AppText(
                                        text: availableTimes[index]
                                            .format(context),
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
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UpdateCreateAppointmentCubit>()
        ..initialize(
          portfolioId: portfolioId,
          appointmentId: appointmentId,
          portfolio: portfolio,
          appointment: appointment,
        ),
      child: this,
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
        if (state.fetchSellerDetailsState.isLoading ||
            state.fetchPortfolioState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final workingDays =
            state.fetchSellerDetailsState.data?.workingHours ?? [];
        if (workingDays.isEmpty) {
          return const SizedBox.shrink();
        }
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
                      orElse: () => workingDays.first,
                    );

                    final isWorkingDay = workDay.slots!.isNotEmpty;

                    if (!isInMonth && hideDaysNotInMonth) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: isWorkingDay
                          ? () {
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
