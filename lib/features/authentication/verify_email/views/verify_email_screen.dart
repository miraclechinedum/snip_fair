import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinput/pinput.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/keyboard_dismisser.dart';
import 'package:snip_fair/core/utils/base/base_stateless_page.dart';
import 'package:snip_fair/core/utils/input/otp_input.dart';
import 'package:snip_fair/features/authentication/verify_email/cubit/verify_email_cubit.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class VerifyEmailScreen extends BaseStatelessPage<VerifyEmailCubit>
    implements AutoRouteWrapper {
  const VerifyEmailScreen({
    required this.email,
    super.key,
  });

  final String email;

  @override
  Widget buildPage(BuildContext context) {
    final cubit = context.read<VerifyEmailCubit>();
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
                    text: 'Verify your Email',
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  5.verticalSpace,
                  AppText(
                    text: 'An email has been sent to $email',
                    textAlign: TextAlign.center,
                  ),
                  50.verticalSpace,
                  BlocSelector<VerifyEmailCubit, VerifyEmailState, OtpInput>(
                    selector: (state) {
                      return state.otp;
                    },
                    builder: (context, otp) {
                      return Pinput(
                        defaultPinTheme: PinTheme(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.grey2),
                            borderRadius: BorderRadius.circular(16).r,
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.primaryColor, width: 2.w),
                            borderRadius: BorderRadius.circular(16).r,
                          ),
                        ),
                        onCompleted: cubit.onOtpChanged,
                        length: 6,
                        separatorBuilder: (index) => 16.horizontalSpace,
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocBuilder<VerifyEmailCubit, VerifyEmailState>(
                    builder: (context, state) {
                      return CustomButton(
                        title: 'Verify',
                        isLoading: state.result.isLoading,
                        onPressed:
                            state.canSubmit ? cubit.forgotPassword : null,
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
      create: (context) => getIt<VerifyEmailCubit>(),
      child: this,
    );
  }
}
