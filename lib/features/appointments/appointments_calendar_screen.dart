import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';

@RoutePage()
class AppointmentsCalendarScreen extends StatelessWidget {
  const AppointmentsCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Calendar',
      ),
    );
  }
}
