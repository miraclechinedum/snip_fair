import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:snip_fair/gen/assets.gen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/utils/input/email_input.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/utils/base/base_stateless_page.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/keyboard_dismisser.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/features/authentication/forgot_password/cubit/forgot_password_cubit.dart';

@RoutePage()
class ForgotPasswordScreen extends BaseStatelessPage<ForgotPasswordCubit>
    implements AutoRouteWrapper {
  const ForgotPasswordScreen({super.key});

  @override
  Widget buildPage(BuildContext context) {
    final cubit = context.read<ForgotPasswordCubit>();
    return KeyboardDismisser(
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
                  SvgPicture.asset(Assets.images.logo),
                  12.verticalSpace,
                  const AppText(
                    text: 'Forgot Password?',
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  5.verticalSpace,
                  const AppText(
                    text:
                        'Enter your email address and we will send you instructions to reset your password.',
                  ),
                  50.verticalSpace,
                  BlocSelector<ForgotPasswordCubit, ForgotPasswordState, EmailInput>(
                    selector: (state) {
                      return state.email;
                    },
                    builder: (context, email) {
                      return CustomTextField(
                        label: 'Email',
                        hint: 'example@gmail.com',
                        isRequired: true,
                        onChanged: cubit.onEmailChanged,
                        isError: email.isNotValid,
                        descriptionText: email.displayError?.message,
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
                    listenWhen: (previous, current) => previous.result != current.result,
                    listener: (context, state) {
                      if (state.result.hasSuccess) {
                        AppHelper.showSnackBar(
                          context,
                          message: 'An email has been sent to you with further instructions',
                        );
                      }
                    },
                    builder: (context, state) {
                      return CustomButton(
                        title: 'Continue',
                        isLoading: state.result.isLoading,
                        onPressed: state.canSubmit ? cubit.forgotPassword : null,
                      );
                    },
                  ),
                  12.verticalSpace,
                  12.verticalSpace,
                ],
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
      create: (context) => getIt<ForgotPasswordCubit>(),
      child: this,
    );
  }
}
