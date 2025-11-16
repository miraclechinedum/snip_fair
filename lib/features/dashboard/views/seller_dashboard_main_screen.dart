// ignore_for_file: unawaited_futures

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/last12_month.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/shared/profile_completeness_compact_view.dart';
import 'package:snip_fair/features/appointments/stylist_appointments/cubit/seller_appoint_mgt_cubit.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class SellerDashboardMainScreen extends StatelessWidget {
  const SellerDashboardMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<SellerProfileMgtCubit>()
            ..getProfileDetails()
            ..getStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
                  builder: (context, state) {
                    final profileCompleteness =
                        state.profileDetails.data?.profileCompleteness;

                    if (profileCompleteness == null) return const SizedBox();

                    final isProfileComplete =
                        AppHelper.isStylistProfileComplete(profileCompleteness);
                    if (isProfileComplete) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SellerProfileCompletedCompactView(
                        profileCompleteness: profileCompleteness,
                      ),
                    );
                  },
                ),
                BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
                  builder: (context, state) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(color: AppColors.grey1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: 'Total Earnings',
                            color: Colors.grey.shade600,
                          ),
                          8.verticalSpace,
                          AppText(
                            text: state.stylistStats.isLoading
                                ? '.........'
                                : state.stylistStats.hasSuccess
                                    ? 'R${state.stylistStats.data!.total?.earnings}'
                                    : 'R0',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: BlocBuilder<SellerProfileMgtCubit,
                          SellerProfileMgtState>(
                        builder: (context, state) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              border: Border.all(color: AppColors.grey1),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: 'Active \nAppointments',
                                  color: Colors.grey.shade600,
                                ),
                                8.verticalSpace,
                                AppText(
                                  text: state.stylistStats.isLoading
                                      ? '...'
                                      : state.stylistStats.hasSuccess
                                          ? '${state.stylistStats.data!.total?.activeAppointments}'
                                          : '0',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: BlocBuilder<SellerProfileMgtCubit,
                          SellerProfileMgtState>(
                        builder: (context, state) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              border: Border.all(color: AppColors.grey1),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: 'Average \nRating',
                                  color: Colors.grey.shade600,
                                ),
                                8.verticalSpace,
                                AppText(
                                  text: state.stylistStats.isLoading
                                      ? '...'
                                      : state.stylistStats.hasSuccess
                                          ? '${state.stylistStats.data!.averageRating}'
                                          : '0',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                12.verticalSpace,
                BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
                  builder: (context, state) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(color: AppColors.grey1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: 'All Bookings',
                            color: Colors.grey.shade600,
                          ),
                          8.verticalSpace,
                          AppText(
                            text: state.stylistStats.isLoading
                                ? '...'
                                : state.stylistStats.hasSuccess
                                    ? '${state.stylistStats.data!.total?.appointments}'
                                    : '0',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                12.verticalSpace,
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: 'Upcoming Appointments',
                        color: Colors.grey.shade600,
                      ),
                      8.verticalSpace,
                      BlocBuilder<SellerAppointMgtCubit, SellerAppointMgtState>(
                        builder: (context, state) {
                          final appointments = state.appointments.data ?? [];

                          final upcomingAppointments = appointments
                              .where(
                                (appointment) =>
                                    AppHelper.isAppointmentUpcoming(
                                  appointment.appointmentDate!,
                                ),
                              )
                              .toList();

                          if (state.appointments.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (upcomingAppointments.isEmpty) {
                            return const Center(
                              child: AppText(
                                text: 'No Upcoming Appointments',
                              ),
                            );
                          }

                          return Column(
                            children: upcomingAppointments
                                .take(3)
                                .map(
                                  (appointment) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () {
                                      context.router.push(
                                        SellerAppointmentDetailsRoute(
                                          appointmentId:
                                              appointment.id!.toString(),
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                        appointment.customer?.avatar
                                                ?.toString()
                                                .completeImagePath() ??
                                            '',
                                      ),
                                      child:
                                          appointment.customer?.avatar == null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  child: SvgPicture.asset(
                                                    Assets.images.logo,
                                                  ),
                                                )
                                              : null,
                                    ),
                                    title: AppText(
                                      text:
                                          'Appointment with ${appointment.customer?.name ?? 'Customer'}',
                                      fontWeight: FontWeight.w600,
                                    ),
                                    trailing: AppText(
                                      text:
                                          '${(appointment.appointmentDate)} \nat ${TimeOfDay(hour: int.parse(appointment.appointmentTime!.split(':')[0]), minute: int.parse(appointment.appointmentTime!.split(':')[1])).format(context)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                12.verticalSpace,
                BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
                  builder: (context, state) {
                    return BookingTrendsWidget(
                      data: state.stylistStats.data?.last12Months ?? [],
                    );
                  },
                ),
                12.verticalSpace,
                BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
                  builder: (context, state) {
                    return AppointmentTrendsWidget(
                      data: state.stylistStats.data?.last12Months ?? [],
                    );
                  },
                ),
                12.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookingTrendsWidget extends StatelessWidget {
  BookingTrendsWidget({
    super.key,
    required this.data,
  });

  final List<Last12Month> data;

  List<Color> gradientColors = [
    AppColors.primaryColor,
    AppColors.contentColorPurple,
  ];
  @override
  Widget build(BuildContext context) {
    final last12Months = data.map((e) => e.toJson()).toList();
    final chartData = _generateChartData(last12Months);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Booking Trends',
              style: AppTextStyle.body2.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.70,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 18,
                left: 12,
                top: 24,
                bottom: 12,
              ),
              child: LineChart(
                _mainData(chartData),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Converts the last 12 months data into chart spots + labels
  List<_ChartPoint> _generateChartData(List<Map<String, dynamic>> months) {
    final dateFormat = DateFormat('MMM');
    return months.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final item = entry.value;
      final endDate = DateTime.parse(item['end_date'] as String);
      final monthLabel = dateFormat.format(endDate);
      final count = (item['appointment_count'] as num).toDouble();
      return _ChartPoint(x: index, y: count, label: monthLabel);
    }).toList();
  }

  LineChartData _mainData(List<_ChartPoint> points) {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.white,
        ),
      ),
      gridData: FlGridData(
        getDrawingVerticalLine: (value) => const FlLine(
          color: Colors.grey,
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 30,
            getTitlesWidget: (value, meta) =>
                _bottomTitleWidgets(value, meta, points),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _calculateYInterval(points),
            reservedSize: 15,
            getTitlesWidget: _leftTitleWidgets,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: _calculateMaxY(points),
      lineBarsData: [
        LineChartBarData(
          spots: points.map((e) => FlSpot(e.x, e.y)).toList(),
          isCurved: true,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// --- Helpers for axis labels ---

  Widget _bottomTitleWidgets(
    double value,
    TitleMeta meta,
    List<_ChartPoint> points,
  ) {
    if (value.toInt() < 0 || value.toInt() >= points.length) {
      return const SizedBox.shrink();
    }
    final label = points[value.toInt()].label;
    return SideTitleWidget(
      meta: meta,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return Text(
      value.toInt().toString(),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  double _calculateMaxY(List<_ChartPoint> points) {
    final maxY =
        points.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b);
    if (maxY == 0) return 5;
    return (maxY * 1.2).ceilToDouble();
  }

  double _calculateYInterval(List<_ChartPoint> points) {
    final maxY = _calculateMaxY(points);
    if (maxY <= 5) return 1;
    if (maxY <= 20) return 5;
    return 10;
  }
}

class AppointmentTrendsWidget extends StatelessWidget {
  AppointmentTrendsWidget({
    super.key,
    required this.data,
  });

  final List<Last12Month> data;

  List<Color> gradientColors = [
    AppColors.contentColorRed,
    AppColors.contentColorPink,
  ];
  @override
  Widget build(BuildContext context) {
    final last12Months = data.map((e) => e.toJson()).toList();
    final chartData = _generateChartData(last12Months);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Appointment Trends',
              style: AppTextStyle.body2.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.7,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 18,
                left: 12,
                top: 24,
                bottom: 12,
              ),
              child: LineChart(_mainData(chartData)),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert JSON months into chart points with readable month labels
  List<_ChartPoint> _generateChartData(List<Map<String, dynamic>> months) {
    final dateFormat = DateFormat('MMM');
    return months.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final item = entry.value;
      final endDate = DateTime.parse(item['end_date'] as String);
      final monthLabel = dateFormat.format(endDate);
      final count =
          (item['confirmed_appointment_count'] as num?)?.toDouble() ?? 0;
      return _ChartPoint(x: index, y: count, label: monthLabel);
    }).toList();
  }

  /// Build chart data
  LineChartData _mainData(List<_ChartPoint> points) {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.white,
        ),
      ),
      gridData: FlGridData(
        show: true,
        horizontalInterval: _calculateYInterval(points),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 30,
            getTitlesWidget: (value, meta) =>
                _bottomTitleWidgets(value, meta, points),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _calculateYInterval(points),
            reservedSize: 15,
            getTitlesWidget: _leftTitleWidgets,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: _calculateMaxY(points),
      lineBarsData: [
        LineChartBarData(
          spots: points.map((e) => FlSpot(e.x, e.y)).toList(),
          isCurved: true,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// --- Helpers ---

  Widget _bottomTitleWidgets(
    double value,
    TitleMeta meta,
    List<_ChartPoint> points,
  ) {
    if (value < 0 || value >= points.length) return const SizedBox.shrink();
    final label = points[value.toInt()].label;
    return SideTitleWidget(
      meta: meta,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value % 1 != 0) return const SizedBox.shrink();
    return Text(
      value.toInt().toString(),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  double _calculateMaxY(List<_ChartPoint> points) {
    final maxY =
        points.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b);
    if (maxY == 0) return 5;
    return (maxY * 1.2).ceilToDouble();
  }

  double _calculateYInterval(List<_ChartPoint> points) {
    final maxY = _calculateMaxY(points);
    if (maxY <= 5) return 1;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    return 20;
  }
}

class _ChartPoint {
  final double x;
  final double y;
  final String label;

  _ChartPoint({
    required this.x,
    required this.y,
    required this.label,
  });
}
