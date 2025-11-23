import 'package:auto_route/auto_route.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/appointments/stylist_appointments/cubit/seller_appoint_mgt_cubit.dart';

enum CalendarViewType { month, week, day }

@RoutePage()
class SellerAppointmentsCalendarScreen extends StatefulWidget {
  const SellerAppointmentsCalendarScreen({super.key});

  @override
  State<SellerAppointmentsCalendarScreen> createState() =>
      _SellerAppointmentsCalendarScreenState();
}

class _SellerAppointmentsCalendarScreenState
    extends State<SellerAppointmentsCalendarScreen> {
  final GlobalKey<MonthViewState> _monthViewKey = GlobalKey<MonthViewState>();
  final GlobalKey<WeekViewState> _weekViewKey = GlobalKey<WeekViewState>();
  final GlobalKey<DayViewState> _dayViewKey = GlobalKey<DayViewState>();
  CalendarViewType _currentView = CalendarViewType.month;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Calendar',
      ),
      body: BlocBuilder<SellerAppointMgtCubit, SellerAppointMgtState>(
        builder: (context, state) {
          final appointments = state.calendarAppointments.data ?? [];

          // Build events
          final events = _toCalendarEvents(appointments);
          final controller = EventController<StylistAppointment>()
            ..addAll(events);

          final monthView = MonthView<StylistAppointment>(
            key: _monthViewKey,
            borderSize: 0.3,
            cellAspectRatio: 9 / 16,
            hideDaysNotInMonth: true,
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
                        text: '${AppHelper.monthName(date.month)} ${date.year}',
                        fontSize: 14,
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
            onCellTap: (events, date) {
              if (events.isEmpty) return;
              _showDayEventsBottomSheet(
                context,
                events,
                date,
              );
            },
            onEventTap: (event, date) {
              _showDayEventsBottomSheet(context, [event], date);
            },
            minMonth: DateTime(DateTime.now().year - 1),
            maxMonth: DateTime(DateTime.now().year + 1, 12, 31),
          );

          final weekView = WeekView<StylistAppointment>(
            key: _weekViewKey,
            weekPageHeaderBuilder: (date, date2) {
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
                            '${date.day} ${AppHelper.monthName(date.month)} ${date.year} - ${date2.day} ${AppHelper.monthName(date2.month)} ${date2.year}',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        _weekViewKey.currentState?.previousPage();
                      },
                    ),
                    12.horizontalSpace,
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        _weekViewKey.currentState?.nextPage();
                      },
                    ),
                  ],
                ),
              );
            },
            onEventTap: (event, date) {
              _showDayEventsBottomSheet(context, event, date);
            },
          );

          final dayView = DayView<StylistAppointment>(
            key: _dayViewKey,
            dayTitleBuilder: (date) {
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
                            '${date.day} ${AppHelper.monthName(date.month)} ${date.year}',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        _dayViewKey.currentState?.previousPage();
                      },
                    ),
                    12.horizontalSpace,
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        _dayViewKey.currentState?.nextPage();
                      },
                    ),
                  ],
                ),
              );
            },
            onEventTap: (event, date) {
              _showDayEventsBottomSheet(context, event, date);
            },
          );

          _switcher<T>(
            CalendarViewType key,
            Map<CalendarViewType, T> map,
          ) {
            return map[key]!;
          }

          return Column(
            children: [
              if (state.calendarAppointments.isLoading)
                const LinearProgressIndicator(),
              8.verticalSpace,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ToggleButtons(
                        isSelected: [
                          _currentView == CalendarViewType.month,
                          _currentView == CalendarViewType.week,
                          _currentView == CalendarViewType.day,
                        ],
                        onPressed: (index) {
                          setState(() {
                            _currentView = CalendarViewType.values[index];
                          });
                        },
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            child: const Text('Month'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            child: const Text('Week'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            child: const Text('Day'),
                          ),
                        ]),
                  ],
                ),
              ),
              Expanded(
                child: CalendarControllerProvider(
                  controller: controller,
                  child: _switcher<Widget>(
                    _currentView,
                    {
                      CalendarViewType.month: monthView,
                      CalendarViewType.week: weekView,
                      CalendarViewType.day: dayView,
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.read<SellerAppointMgtCubit>().getCalendarAppointment(),
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  List<CalendarEventData<StylistAppointment>> _toCalendarEvents(
    List<StylistAppointment> list,
  ) {
    return list.map((a) {
      final start = _fallbackDateTime(a);
      final end = start.add(_parseDuration(a.duration));
      final title = a.portfolio?.title ?? 'Appointment';
      final desc = a.stylist?.name != null ? 'with ${a.stylist!.name}' : '';
      final color = a.status.toStatusColor();
      return CalendarEventData<StylistAppointment>(
        date: DateTime(start.year, start.month, start.day),
        startTime: start,
        endTime: end,
        title: title,
        description: desc,
        color: color,
        event: a,
        titleStyle: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();
  }

  DateTime _fallbackDateTime(StylistAppointment a) {
    // Build from separate date/time strings if combined not available
    if (a.appointmentDate != null && a.appointmentTime != null) {
      try {
        final date = DateTime.parse(a.appointmentDate!);
        final t = a.appointmentTime!; // HH:mm or HH:mm:ss
        final parts = t.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final s = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
        return DateTime(date.year, date.month, date.day, h, m, s);
      } catch (_) {}
    }
    return DateTime.now();
  }

  Duration _parseDuration(String? duration) {
    if (duration == null || duration.isEmpty) return const Duration(hours: 1);
    // expected like '1 Hour', '2 Hours', '90 Minutes'
    try {
      final durationParts = duration.split(' ');
      if (durationParts.length == 2) {
        final value = int.tryParse(durationParts[0]) ?? 1;
        final unit = durationParts[1].toLowerCase();
        switch (unit) {
          case 'hour':
          case 'hours':
            return Duration(hours: value);
          case 'minute':
          case 'minutes':
            return Duration(minutes: value);
        }
      }
    } catch (_) {}
    return const Duration(hours: 1);
  }

  void _showDayEventsBottomSheet(
    BuildContext context,
    List<CalendarEventData<StylistAppointment>> events,
    DateTime date,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (_, scrollController) {
            return DailyAppointmentDetails(
              date: date,
              scrollController: scrollController,
              events: events,
            );
          },
        );
      },
    );
  }
}

class DailyAppointmentDetails extends StatelessWidget {
  const DailyAppointmentDetails({
    super.key,
    required this.date,
    required this.scrollController,
    required this.events,
  });

  final DateTime date;
  final ScrollController scrollController;
  final List<CalendarEventData<StylistAppointment>> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(DateFormat.yMMMMd().format(date),
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final e = events[i];
              final a = e.event!;
              return ListTile(
                leading: CircleAvatar(backgroundColor: e.color, radius: 8),
                title: AppText(text: e.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                        text:
                            '${DateFormat.Hm().format(e.startTime!)} - ${DateFormat.Hm().format(e.endTime!)}'),
                    AppText(
                      text: e.event?.customer?.name != null
                          ? 'Customer: ${e.event!.customer!.name}'
                          : '',
                      fontSize: 12,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
                trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: a.status.toStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      text: a.status.toStatusText(),
                      fontSize: 10,
                      color: a.status.toStatusColor(),
                    )),
                onTap: () {
                  Navigator.of(context).pop();
                  context.router.push(
                    SellerAppointmentDetailsRoute(
                      appointmentId: a.id.toString(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
