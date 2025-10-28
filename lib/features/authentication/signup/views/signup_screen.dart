import 'package:auth_buttons/auth_buttons.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/keyboard_dismisser.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/base/base_stateless_page.dart';
import 'package:snip_fair/core/utils/input/input.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/authentication/signup/cubit/signup_cubit.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class SignupScreen extends BaseStatelessPage<SignupCubit>
    implements AutoRouteWrapper {
  const SignupScreen({this.asStylist = false, super.key});

  final bool asStylist;

  @override
  Widget buildPage(BuildContext context) {
    final cubit = context.read<SignupCubit>();
    return BlocListener<SignupCubit, SignupState>(
      listenWhen: (previous, current) =>
          previous.signUpResult != current.signUpResult,
      listener: (context, state) {
        if (state.signUpResult.hasSuccess) {
          // context.pushRoute(
          //   VerifyEmailRoute(email: state.email.value, asStylist: asStylist),
          // );
          context.read<AppCubit>().onLogin();
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
                      text: 'Create an account to get started',
                    ),
                    20.verticalSpace,
                    BlocSelector<SignupCubit, SignupState, StringInput>(
                      selector: (state) {
                        return state.firstName;
                      },
                      builder: (context, firstName) {
                        return CustomTextField(
                          label: 'First Name',
                          hint: 'Enter your first name',
                          isRequired: true,
                          onChanged: cubit.onFirstNameChanged,
                          isError: firstName.isNotValid,
                          descriptionText: firstName.displayError?.message,
                        );
                      },
                    ),
                    16.verticalSpace,
                    BlocSelector<SignupCubit, SignupState, StringInput>(
                      selector: (state) {
                        return state.lastName;
                      },
                      builder: (context, lastName) {
                        return CustomTextField(
                          label: 'Last Name',
                          hint: 'Enter your last name',
                          isRequired: true,
                          onChanged: cubit.onLastNameChanged,
                          isError: lastName.isNotValid,
                          descriptionText: lastName.displayError?.message,
                        );
                      },
                    ),
                    16.verticalSpace,
                    BlocSelector<SignupCubit, SignupState, EmailInput>(
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
                    CustomPhoneTextField(
                      label: 'Phone',
                      isRequired: true,
                      dialCode: '+27',
                      onInputChanged: (phone) =>
                          cubit.onPhoneChanged(phone.international),
                    ),
                    16.verticalSpace,
                    BlocSelector<SignupCubit, SignupState, bool>(
                      selector: (state) {
                        return state.showPassword;
                      },
                      builder: (context, showPassword) {
                        return BlocSelector<SignupCubit, SignupState,
                            PasswordInput>(
                          selector: (state) {
                            return state.password;
                          },
                          builder: (context, password) {
                            return CustomTextField(
                              label: 'Password',
                              hint: 'Create password',
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
                    16.verticalSpace,
                    BlocSelector<SignupCubit, SignupState, bool>(
                      selector: (state) {
                        return state.showPassword;
                      },
                      builder: (context, showPassword) {
                        return BlocSelector<SignupCubit, SignupState,
                            ConfirmPasswordInput>(
                          selector: (state) {
                            return state.confirmPassword;
                          },
                          builder: (context, password) {
                            return CustomTextField(
                              label: 'Confirm Password',
                              hint: 'Confirm password',
                              obscure: !showPassword,
                              isRequired: true,
                              onChanged: cubit.onConfirmPasswordChanged,
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
                    BlocSelector<SignupCubit, SignupState, bool>(
                      selector: (state) {
                        return state.acceptTerms;
                      },
                      builder: (context, acceptTerms) {
                        return Row(
                          children: [
                            Checkbox(
                              value: acceptTerms,
                              onChanged: (value) {
                                cubit.onAcceptTermsChanged(value ??= false);
                              },
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: AppTextStyle.body2.copyWith(),
                                  ),
                                  TextSpan(
                                    text: 'Terms',
                                    style: AppTextStyle.body2.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        AppHelper.launchHttp(
                                          'https://snipfair.com/terms',
                                        );
                                      },
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: AppTextStyle.body2.copyWith(),
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: AppTextStyle.body2.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        AppHelper.launchHttp(
                                          'https://snipfair.com/privacy-policy',
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    14.verticalSpace,
                    BlocBuilder<SignupCubit, SignupState>(
                      builder: (context, state) {
                        return CustomButton(
                          title: 'Sign Up',
                          isLoading: state.signUpResult.isLoading,
                          onPressed: state.canSignup
                              ? asStylist
                                  ? cubit.signUpAsStylist
                                  : cubit.signUpAsCustomer
                              : null,
                        );
                      },
                    ),
                    12.verticalSpace,
                    Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: AppTextStyle.caption.copyWith(),
                            ),
                            TextSpan(
                              text: 'Log in',
                              style: AppTextStyle.body2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  context.router.replace(LoginRoute());
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    12.verticalSpace,
                    const Divider(),
                    12.verticalSpace,
                    BlocBuilder<SignupCubit, SignupState>(
                      builder: (context, state) {
                        return Center(
                          child: GoogleAuthButton(
                            isLoading: state.signUpResult.isLoading,
                            onPressed: () {
                              cubit.loginWithGoogle(isStylist: asStylist);
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
      create: (context) => getIt<SignupCubit>(),
      child: this,
    );
  }
}
