import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/features/account/availability/cubit/seller_availability_schedule_cubit.dart';

@RoutePage()
class SellerAvailabilityScheduleScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const SellerAvailabilityScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Availability',
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<SellerAvailabilityScheduleCubit>()..getAvailabilitySchedule(),
      child: this,
    );
  }
}
