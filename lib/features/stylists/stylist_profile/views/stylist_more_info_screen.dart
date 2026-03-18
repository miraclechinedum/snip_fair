import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';

@RoutePage()
class StylistMoreInfoScreen extends StatelessWidget {
  const StylistMoreInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'RuxyStylez',
      ),
    );
  }
}
