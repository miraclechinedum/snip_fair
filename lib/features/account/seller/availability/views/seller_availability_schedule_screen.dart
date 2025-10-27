import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/timeslot.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/seller/availability/cubit/seller_availability_schedule_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

@RoutePage()
class SellerAvailabilityScheduleScreen extends StatefulWidget
    implements AutoRouteWrapper {
  const SellerAvailabilityScheduleScreen({
    super.key,
    this.goToLocationSettings = false,
  });

  final bool goToLocationSettings;

  @override
  State<SellerAvailabilityScheduleScreen> createState() =>
      _SellerAvailabilityScheduleScreenState();

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<SellerAvailabilityScheduleCubit>()..getAvailabilitySchedule(),
      child: this,
    );
  }
}

class _SellerAvailabilityScheduleScreenState
    extends State<SellerAvailabilityScheduleScreen> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    if (widget.goToLocationSettings) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SellerAvailabilityScheduleCubit>();
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Availability',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => context
              .read<SellerAvailabilityScheduleCubit>()
              .getAvailabilitySchedule(),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (cubit.state.schedules.isLoading)
                  const LinearProgressIndicator(),
                ...List.generate(scheduleDays.length, (index) {
                  final day = scheduleDays[index];
                  return DayAvailabilityWidget(
                    day: day,
                    isAvailable: cubit.state.scheduleAvailability[day] ?? false,
                    timeSlots: cubit.state.scheduleTimeSlots[day] ?? [],
                  );
                }),
                BlocListener<SellerAvailabilityScheduleCubit,
                    SellerAvailabilityScheduleState>(
                  listenWhen: (previous, current) =>
                      previous.updateScheduleState !=
                      current.updateScheduleState,
                  listener: (context, state) {
                    if (state.updateScheduleState.hasSuccess) {
                      AppHelper.showSnackBar(
                        context,
                        message: 'Availability updated..',
                      );
                    }
                  },
                  child: CustomButton(
                    title: 'Save Changes',
                    isLoading: cubit.state.updateScheduleState.isLoading,
                    onPressed: () {
                      final timeSlots = cubit.state.scheduleTimeSlots.values
                          .expand((list) => list)
                          .toList();
                      final emptySlots = timeSlots
                          .where((e) => e.from == null || e.to == null);

                      if (emptySlots.isNotEmpty) {
                        AppHelper.showSnackBar(
                          context,
                          message: 'Fill empty time slots',
                        );
                        return;
                      }

                      cubit.submitAvailability();
                    },
                  ),
                ),
                12.verticalSpace,
                const Divider(),
                12.verticalSpace,
                BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
                  builder: (context, state) {
                    return LocationSettings(
                      address: state.profileDetails.data?.user?.country,
                      useLocation: state.profileDetails.data?.user?.useLocation,
                    );
                  },
                ),
                100.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LocationSettings extends StatefulWidget {
  const LocationSettings({
    super.key,
    this.address,
    this.useLocation,
  });

  final String? address;
  final bool? useLocation;

  @override
  State<LocationSettings> createState() => _LocationSettingsState();
}

class _LocationSettingsState extends State<LocationSettings> {
  String? _address;
  bool _useLocation = false;

  @override
  void initState() {
    super.initState();
    _address = widget.address;
    _useLocation = widget.useLocation ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: AppColors.grey1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'Location Settings',
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          12.verticalSpace,
          BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
            builder: (context, state) {
              return ListTile(
                title: const AppText(
                  text: 'Enable Travel Mode',
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: EdgeInsets.zero,
                subtitle: const AppText(
                  text:
                      'Use your device location to provide availability in real-time.',
                  fontSize: 12,
                  color: AppColors.grey3,
                ),
                trailing: Switch(
                  value: _useLocation,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      _useLocation = value;
                    });
                  },
                ),
              );
            },
          ),
          12.verticalSpace,
          BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
            builder: (context, state) {
              return CustomPlaceSearchField(
                onSelected: (p0) {
                  setState(() {
                    _address = p0?.address;
                  });
                },
                label: 'Location',
                hintText: 'Search for address',
                isError: _address == null,
                initialPlace: state.profileDetails.hasSuccess
                    ? GeoPlace(
                        address: state.profileDetails.data!.user!.country!,
                        lat: 0,
                        lng: 0,
                      )
                    : null,
                descriptionText:
                    _address == null ? 'This field is required' : null,
              );
            },
          ),
          12.verticalSpace,
          BlocConsumer<SellerProfileMgtCubit, SellerProfileMgtState>(
            listenWhen: (previous, current) =>
                previous.updateLocationSettingsState !=
                current.updateLocationSettingsState,
            listener: (context, state) {
              if (state.updateLocationSettingsState.hasSuccess) {
                AppHelper.showSnackBar(
                  context,
                  message: 'Location settings updated..',
                );
              }
            },
            builder: (context, state) {
              return CustomButton(
                title: 'Save Changes',
                isLoading: state.updateLocationSettingsState.isLoading,
                onPressed: () {
                  if (_address == null) return;
                  context.read<SellerProfileMgtCubit>().updateLocationSettings(
                        address: _address!,
                        useLocation: _useLocation,
                      );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class DayAvailabilityWidget extends StatelessWidget {
  const DayAvailabilityWidget({
    required this.day,
    required this.isAvailable,
    required this.timeSlots,
    super.key,
  });

  final String day;
  final bool isAvailable;
  final List<TimeSlot> timeSlots;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: AppColors.grey1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: day.capitalizeFirstLetter(),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    5.verticalSpace,
                    if (isAvailable)
                      const AppText(
                        text: 'Available',
                        fontSize: 12,
                        color: Colors.green,
                      )
                    else
                      const AppText(
                        text: 'Unavailable',
                        fontSize: 12,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch(
                    value: isAvailable,
                    onChanged: (value) {
                      context
                          .read<SellerAvailabilityScheduleCubit>()
                          .updateAvailabilitu(day: day, newValue: value);
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ],
          ),
          12.verticalSpace,
          ...List.generate(
            timeSlots.length,
            (index) => _buildTimeSlotWidget(
              context,
              index: index,
              slot: timeSlots[index],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              context.read<SellerAvailabilityScheduleCubit>().addTimeSlot(day);
            },
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(45),
            ),
            label: const AppText(
              text: 'Add Time Slot',
              color: Color(0xff2947B1),
            ),
            icon: const Icon(
              Icons.add,
              color: Color(0xff2947B1),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotWidget(
    BuildContext context, {
    required int index,
    required TimeSlot slot,
  }) {
    final cubit = context.read<SellerAvailabilityScheduleCubit>();
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const AppText(
                text: 'From',
                color: AppColors.grey3,
              ),
              12.horizontalSpace,
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (BuildContext context, Widget? child) {
                      return MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    TimeOfDay? parseTime(String? s) {
                      if (s == null) return null;
                      // Expect 24-hour format HH:mm or H:mm
                      final match =
                          RegExp(r'^\s*(\d{1,2}):(\d{2})\s*$').firstMatch(s);
                      if (match == null) return null;

                      final hour = int.parse(match.group(1)!);
                      final minute = int.parse(match.group(2)!);

                      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
                        return null;
                      }
                      return TimeOfDay(hour: hour, minute: minute);
                    }

                    final toTime = parseTime(slot.to);
                    if (toTime != null) {
                      final selectedMinutes = time.hour * 60 + time.minute;
                      final toMinutes = toTime.hour * 60 + toTime.minute;
                      if (selectedMinutes >= toMinutes) {
                        AppHelper.showSnackBar(
                          // ignore: use_build_context_synchronously
                          context,
                          message: "'From' must be before 'To'",
                        );
                        return;
                      }
                    }

                    cubit.updateTimeSlot(
                      day: day,
                      index: index,
                      // ignore: use_build_context_synchronously
                      slot: slot.copyWith(
                        from:
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Row(
                    children: [
                      AppText(text: slot.from ?? '00:00'),
                      6.horizontalSpace,
                      const Icon(
                        Iconsax.clock,
                        size: 16,
                        color: AppColors.grey3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Row(
            children: [
              const AppText(
                text: 'To',
                color: AppColors.grey3,
              ),
              12.horizontalSpace,
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (BuildContext context, Widget? child) {
                      return MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    TimeOfDay? parseTime(String? s) {
                      if (s == null) return null;
                      // Expect 24-hour format HH:mm or H:mm
                      final match =
                          RegExp(r'^\s*(\d{1,2}):(\d{2})\s*$').firstMatch(s);
                      if (match == null) return null;

                      final hour = int.parse(match.group(1)!);
                      final minute = int.parse(match.group(2)!);

                      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
                        return null;
                      }
                      return TimeOfDay(hour: hour, minute: minute);
                    }

                    final fromTime = parseTime(slot.from);
                    if (fromTime != null) {
                      final selectedMinutes = time.hour * 60 + time.minute;
                      final fromMinutes = fromTime.hour * 60 + fromTime.minute;
                      if (selectedMinutes <= fromMinutes) {
                        AppHelper.showSnackBar(
                          context,
                          message: "'To' must be after 'From'",
                        );
                        return;
                      }
                    }

                    cubit.updateTimeSlot(
                      day: day,
                      index: index,
                      // ignore: use_build_context_synchronously
                      slot: slot.copyWith(
                        to: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    children: [
                      AppText(text: slot.to ?? '00:00'),
                      6.horizontalSpace,
                      const Icon(
                        Iconsax.clock,
                        size: 16,
                        color: AppColors.grey3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        12.horizontalSpace,
        GestureDetector(
          onTap: () {
            context
                .read<SellerAvailabilityScheduleCubit>()
                .deleteTimeSlot(day: day, index: index);
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Iconsax.trash,
              size: 18,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}
