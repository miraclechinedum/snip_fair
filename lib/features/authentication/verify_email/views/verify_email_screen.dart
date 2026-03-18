import 'package:pinput/pinput.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:auto_route/annotations.dart';
import 'package:snip_fair/gen/assets.gen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/core/utils/input/otp_input.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/utils/base/base_stateless_page.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/keyboard_dismisser.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart' show AppCubit;
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/features/authentication/verify_email/cubit/verify_email_cubit.dart';

@RoutePage()
class VerifyEmailScreen extends BaseStatelessPage<VerifyEmailCubit> implements AutoRouteWrapper {
  const VerifyEmailScreen({
    required this.email,
    this.asStylist = false,
    super.key,
  });

  final String email;
  final bool asStylist;

  @override
  Widget buildPage(BuildContext context) {
    final cubit = context.read<VerifyEmailCubit>();
    return BlocListener<VerifyEmailCubit, VerifyEmailState>(
      listenWhen: (previous, current) => previous.result != current.result,
      listener: (context, state) {
        if (state.result.hasSuccess) {
          if (asStylist) {
            AppHelper.showAppDialog<void>(
              context,
              barrierDismissible: true,
              OnSuccessDialogContent(
                mainText: 'Email Verified',
                subtext:
                    'You have successfully verified your email address. Proceed to complete your application',
                buttonText: 'Complete Registration',
                onDoneCallback: (ctx) {
                  context.pop();
                  context.read<AppCubit>().onLogin();
                },
              ),
            );
          } else {
            context.read<AppCubit>().onLogin();
          }
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
                      text: 'Verify your Email',
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    5.verticalSpace,
                    AppText(
                      text: 'An email has been sent to $email',
                    ),
                    20.verticalSpace,
                    Text(
                      'Please input the code that was sent to your email',
                      style: AppTextStyle.body1.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.black,
                      ),
                    ),
                    8.verticalSpace,
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
                              borderRadius: BorderRadius.circular(10).r,
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: 60.w,
                            height: 60.h,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primaryColor,
                                width: 2.w,
                              ),
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
                          onPressed: state.canSubmit ? cubit.verifyEmail : null,
                        );
                      },
                    ),
                    12.verticalSpace,
                    ResendVerificationButton(
                      email: email,
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
      create: (context) => getIt<VerifyEmailCubit>(),
      child: this,
    );
  }
}

class ResendVerificationButton extends StatefulWidget {
  const ResendVerificationButton({
    this.cooldownSeconds = 30,
    this.label = 'Resend code',
    required this.email,
    Key? key,
  }) : super(key: key);
  final int cooldownSeconds;
  final String label;
  final String email;

  @override
  State<ResendVerificationButton> createState() => _ResendVerificationButtonState();
}

class _ResendVerificationButtonState extends State<ResendVerificationButton> {
  int _remaining = 0;
  bool _loading = false;

  void _startCooldown() {
    if (!mounted) return;
    setState(() => _remaining = widget.cooldownSeconds);
    _tick();
  }

  void _tick() {
    if (!mounted || _remaining <= 0) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _remaining -= 1);
      if (_remaining > 0) _tick();
    });
  }

  Future<void> _onPressed() async {
    if (_loading || _remaining > 0) return;

    setState(() => _loading = true);

    try {
      final maybeFuture = context.read<VerifyEmailCubit>().resendVerificationEmail(widget.email);
      await maybeFuture;
      // start cooldown after attempting resend
      if (mounted) _startCooldown();
    } catch (_) {
      // still start a cooldown to prevent spamming; adjust if you prefer otherwise
      if (mounted) _startCooldown();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _loading ? null : (_remaining > 0 ? 'Resend in $_remaining s' : widget.label);

    return TextButton(
      onPressed: (_loading || _remaining > 0) ? null : _onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor,
              ),
            )
          : Text(
              text ?? '',
              style: AppTextStyle.body1.copyWith(color: AppColors.primaryColor),
            ),
    );
  }
}
