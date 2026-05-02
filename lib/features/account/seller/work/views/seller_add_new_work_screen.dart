import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';

@RoutePage()
class SellerAddNewWorkScreen extends StatelessWidget {
  const SellerAddNewWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Add New Work',
      ),
    );
  }
}
