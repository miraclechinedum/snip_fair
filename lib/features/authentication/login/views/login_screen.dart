import 'package:auth_buttons/auth_buttons.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/keyboard_dismisser.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/base/base_stateless_page.dart';
import 'package:snip_fair/core/utils/input/input.dart';
import 'package:snip_fair/features/authentication/login/cubit/login_cubit.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class LoginScreen extends BaseStatelessPage<LoginCubit>
    implements AutoRouteWrapper {
  const LoginScreen({super.key, this.isStylist = false});

  final bool isStylist;

  @override
  Widget buildPage(BuildContext context) {
    final cubit = context.read<LoginCubit>();
    final appState = context.watch<AppCubit>().state;
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) =>
              previous.loginResult != current.loginResult,
          listener: (context, state) {
            if (state.loginResult.hasSuccess) {
              context.read<AppCubit>().onLogin();
            }
          },
        ),
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) =>
              previous.googleLoginResult != current.googleLoginResult,
          listener: (context, state) {
            if (state.googleLoginResult.hasError) {
              final error = state.googleLoginResult.error;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Google Sign-In failed: ${error.toString()}'),
                ),
              );
            }
          },
        ),
      ],
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
                    SvgPicture.asset(Assets.images.logo),
                    12.verticalSpace,
                    const AppText(
                      text: 'Welcome to Snipfair',
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    5.verticalSpace,
                    const AppText(
                      text: 'Log into your Snipfair account',
                    ),
                    50.verticalSpace,
                    BlocSelector<LoginCubit, LoginState, EmailInput>(
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
                    BlocSelector<LoginCubit, LoginState, bool>(
                      selector: (state) {
                        return state.showPassword;
                      },
                      builder: (context, showPassword) {
                        return BlocSelector<LoginCubit, LoginState,
                            PasswordInput>(
                          selector: (state) {
                            return state.password;
                          },
                          builder: (context, password) {
                            return CustomTextField(
                              label: 'Password',
                              hint: 'Your password',
                              obscure: !showPassword,
                              isRequired: true,
                              onChanged: cubit.onPasswordChanged,
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
                    Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            context.router.push(const ForgotPasswordRoute());
                          },
                          child: const AppText(
                            text: 'Forgot your password?',
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    14.verticalSpace,
                    BlocBuilder<LoginCubit, LoginState>(
                      builder: (context, state) {
                        return CustomButton(
                          title: 'Log in',
                          isLoading: state.loginResult.isLoading,
                          onPressed: state.canLogin ? cubit.login : null,
                        );
                      },
                    ),
                    12.verticalSpace,
                    BlocBuilder<LoginCubit, LoginState>(
                      builder: (context, state) {
                        return Center(
                          child: GoogleAuthButton(
                            isLoading: state.loginResult.isLoading,
                            onPressed: () {
                              cubit.loginWithGoogle(isStylist: isStylist);
                            },
                            themeMode: ThemeMode.light,
                            style: AuthButtonStyle(
                              iconType: AuthIconType.secondary,
                              buttonType: AuthButtonType.secondary,
                              buttonColor: AppColors.white,
                              iconBackground: AppColors.white,
                              elevation: 2,
                              borderRadius: 8.r,
                              height: 50.h,
                              width: double.infinity,
                              textStyle: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    12.verticalSpace,
                    Divider(),
                    12.verticalSpace,
                    if (appState.platformSettings?.allowRegistrationCustomers ??
                        false)
                      Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Don't have an account? ",
                                style: AppTextStyle.caption.copyWith(),
                              ),
                              TextSpan(
                                text: 'Sign Up',
                                style: AppTextStyle.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    context.router.replace(SignupRoute());
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (appState.platformSettings?.allowRegistrationStylists ==
                            true &&
                        isStylist)
                      Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                          ),
                          onPressed: () {
                            context.router
                                .replace(SignupRoute(asStylist: true));
                          },
                          child: const Text(
                            'Sign Up as a Stylist',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
      create: (context) => getIt<LoginCubit>(),
      child: this,
    );
  }
}
