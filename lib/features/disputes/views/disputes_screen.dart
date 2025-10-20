import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/features/disputes/cubit/disputes_cubit.dart';

@RoutePage()
class DisputesScreen extends StatelessWidget implements AutoRouteWrapper {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Disputes',
      ),
      body: BlocBuilder<DisputesCubit, DisputesState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.disputes.isEmpty) {
            return const Center(
              child: Text('No disputes found.'),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: state.disputes.length,
            itemBuilder: (context, index) {
              final dispute = state.disputes[index];
              return ListTile(
                tileColor: Colors.white,
                title: Text(
                  dispute.comment ?? 'No Title',
                  style: AppTextStyle.subTitle2,
                ),
                subtitle: Text(
                  'Service: ${dispute.appointment?.portfolio?.title}',
                  style: AppTextStyle.subTitle2,
                ),
                trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(dispute.status ?? 'Unknown')),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DisputesCubit>()..fetchDisputes(),
      child: this,
    );
  }
}
