import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/keyboard_dismisser.dart';
import 'package:snip_fair/core/utils/base/base_stateless_page.dart';
import 'package:snip_fair/core/utils/input/confirm_passowrd_input.dart';
import 'package:snip_fair/core/utils/input/password_input.dart';
import 'package:snip_fair/features/account/change_password/cubit/change_password_cubit.dart';

@RoutePage()
class ChangePasswordScreen extends BaseStatelessPage<ChangePasswordCubit>
    implements AutoRouteWrapper {
  const ChangePasswordScreen({super.key});

  @override
  Widget buildPage(BuildContext context) {
    final cubit = context.read<ChangePasswordCubit>();
    return BlocListener<ChangePasswordCubit, ChangePasswordState>(
      listenWhen: (previous, current) =>
          previous.chagePasswordState != current.chagePasswordState,
      listener: (context, state) {
        if (state.chagePasswordState.hasSuccess) {
          context.pop();
        }
      },
      child: KeyboardDismisser(
        child: Scaffold(
          appBar: const CustomAppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    40.verticalSpace,
                    const AppText(
                      text: 'Change Password',
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    20.verticalSpace,
                    BlocSelector<ChangePasswordCubit, ChangePasswordState,
                        bool>(
                      selector: (state) {
                        return state.showPassword;
                      },
                      builder: (context, showPassword) {
                        return BlocSelector<ChangePasswordCubit,
                            ChangePasswordState, PasswordInput>(
                          selector: (state) {
                            return state.currentPassword;
                          },
                          builder: (context, password) {
                            return CustomTextField(
                              label: 'Current Password',
                              hint: 'Confirm your password',
                              isRequired: true,
                              onChanged: cubit.onCurrentPassChanged,
                              isError: password.isNotValid,
                              descriptionText: password.displayError?.message,
                              suffixIcon: IconButton(
                                onPressed: cubit.onTogglePassword,
                                icon: showPassword
                                    ? const Icon(Iconsax.unlock)
                                    : const Icon(Iconsax.lock),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    16.verticalSpace,
                    BlocSelector<ChangePasswordCubit, ChangePasswordState,
                        bool>(
                      selector: (state) {
                        return state.showPassword;
                      },
                      builder: (context, showPassword) {
                        return BlocSelector<ChangePasswordCubit,
                            ChangePasswordState, PasswordInput>(
                          selector: (state) {
                            return state.newPassword;
                          },
                          builder: (context, password) {
                            return CustomTextField(
                              label: 'New Password',
                              hint: 'Create password',
                              isRequired: true,
                              onChanged: cubit.onNewPassChanged,
                              isError: password.isNotValid,
                              descriptionText: password.displayError?.message,
                              suffixIcon: IconButton(
                                onPressed: cubit.onTogglePassword,
                                icon: showPassword
                                    ? const Icon(Iconsax.unlock)
                                    : const Icon(Iconsax.lock),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    BlocSelector<ChangePasswordCubit, ChangePasswordState,
                        bool>(
                      selector: (state) {
                        return state.showPassword;
                      },
                      builder: (context, showPassword) {
                        return BlocSelector<ChangePasswordCubit,
                            ChangePasswordState, ConfirmPasswordInput>(
                          selector: (state) {
                            return state.confirmNewPassword;
                          },
                          builder: (context, password) {
                            return CustomTextField(
                              label: 'Confirm Password',
                              hint: 'Confirm password',
                              obscure: !showPassword,
                              isRequired: true,
                              onChanged: cubit.onConfirmNewPassChanged,
                              isError: password.isNotValid,
                              descriptionText: password.displayError?.message,
                              suffixIcon: IconButton(
                                onPressed: cubit.onTogglePassword,
                                icon: showPassword
                                    ? const Icon(Iconsax.unlock)
                                    : const Icon(Iconsax.lock),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    14.verticalSpace,
                    14.verticalSpace,
                    BlocBuilder<ChangePasswordCubit, ChangePasswordState>(
                      builder: (context, state) {
                        return CustomButton(
                          title: 'Update password',
                          isLoading: state.chagePasswordState.isLoading,
                          onPressed:
                              state.canSubmit ? cubit.changePassword : null,
                        );
                      },
                    ),
                    12.verticalSpace,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ChangePasswordCubit>(),
      child: this,
    );
  }
}
