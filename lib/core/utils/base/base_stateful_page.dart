// ignore_for_file: always_use_package_imports

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../errors/error_handler/error_handler_factory.dart';
import '../../errors/error_handler/error_listener_mixin.dart';
import '../../presentation/theme/theme.dart';
import '../../presentation/widgets/simple_loading_widget.dart';
import 'base_cubit.dart';
import 'base_state.dart';

abstract class BaseStatefulPage<B extends BaseCubit, P extends StatefulWidget>
    extends State<P> with ErrorListenerMixin {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<B, BaseState>(
          listenWhen: (previous, current) =>
              previous.exception != current.exception,
          listener: (context, state) {
            if (state.exception != null) {
              ErrorHandlerFactory.handleErrorByType(
                context,
                state.exception!,
                this,
              );
            }
          },
        ),
      ],
      child: BlocBuilder<B, BaseState>(
        buildWhen: (previous, current) =>
            previous.isLoading != current.isLoading,
        builder: (context, state) {
          return Stack(
            children: [
              buildPage(context),
              if (state.isLoading) ...[
                const ModalBarrier(
                  color: Colors.black26,
                ),
                showLoading(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget buildPage(BuildContext context);

  Widget showLoading() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SimpleLoadingWidget(),
          ),
        ),
      ),
    );
  }
}
