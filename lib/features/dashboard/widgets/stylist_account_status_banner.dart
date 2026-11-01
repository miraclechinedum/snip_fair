import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/domain/entities/stylist_account/stylist_account_status.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

const _supportEmail = 'support@snipfair.com';

/// The screen that completes one backend requirement key, or null when the
/// app has no dedicated screen for it.
PageRouteInfo<dynamic>? stylistRequirementRoute(String key, {String? email}) {
  return switch (key) {
    'email_verified' when email != null && email.isNotEmpty =>
      VerifyEmailRoute(email: email, asStylist: true),
    'basic_details' => SellerBusinessCreateRoute(),
    'identity_document' => StylistBusinessIdVerifyRoute(),
    'user_bio' || 'address' => const SellerPersonalDetailsRoute(),
    'location_service' =>
      SellerAvailabilityScheduleRoute(goToLocationSettings: true),
    'user_avatar' || 'user_banner' => const SellerProfileManagementRoute(),
    'portfolio' => const SellerPortfolioRoute(),
    'social_links' || 'works' => const SellerProfileVerificationRoute(),
    'payment_method' => const SellerPaymentMethodsRoute(),
    _ => null,
  };
}

/// Prominent, stylist-only notice shown while the backend says the stylist
/// account is not active. Everything it shows — state, message and
/// requirements — comes from the backend's `stylist_account`; nothing is
/// inferred from local profile data. Hidden for customers, for active
/// accounts and while no status is known.
class StylistAccountStatusBanner extends StatelessWidget {
  const StylistAccountStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    if (!appState.isStylist) return const SizedBox.shrink();
    final account = context.select(
      (SellerProfileMgtCubit cubit) => cubit.state.stylistAccount,
    );
    if (account == null || account.isActive) return const SizedBox.shrink();
    return _StatusCard(account: account, email: appState.user.email);
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.account, required this.email});

  final StylistAccountStatus account;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final copy = _StateCopy.of(account.state);
    final outstanding = account.outstandingRequirements;
    final message = account.message ?? copy.fallbackMessage;

    return Container(
      key: const Key('stylist_account_banner'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: copy.background,
        borderRadius: BorderRadius.circular(12).r,
        border: Border.all(color: copy.foreground.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(copy.icon, color: copy.foreground, size: 22),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  copy.title,
                  key: const Key('stylist_account_banner_title'),
                  style: AppTextStyle.subTitle1.copyWith(
                    color: copy.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          Text(
            message,
            key: const Key('stylist_account_banner_message'),
            style: AppTextStyle.body2.copyWith(color: AppColors.blackShade1),
          ),
          if (account.state == StylistAccountState.incomplete &&
              outstanding.isNotEmpty) ...[
            12.verticalSpace,
            Text(
              '${outstanding.length} step${outstanding.length == 1 ? '' : 's'} '
              'left to complete:',
              style: AppTextStyle.caption.copyWith(
                color: AppColors.grey3,
                fontWeight: FontWeight.w600,
              ),
            ),
            6.verticalSpace,
            for (final requirement in outstanding)
              _RequirementRow(requirement: requirement, email: email),
          ],
          ..._action(context, outstanding),
        ],
      ),
    );
  }

  List<Widget> _action(
    BuildContext context,
    List<StylistAccountRequirement> outstanding,
  ) {
    final (String? title, Future<void> Function()? onPressed) =
        switch (account.state) {
      StylistAccountState.incomplete => () {
          final next = outstanding.isEmpty ? null : outstanding.first;
          final route = next == null
              ? null
              : stylistRequirementRoute(next.key, email: email);
          return route == null
              ? (null, null)
              : ('Continue', () => _open(context, route));
        }(),
      // A real submission (PATCH /stylist/profile), not navigation.
      StylistAccountState.notSubmitted => (
          'Submit for approval',
          () => context.read<SellerProfileMgtCubit>().submitForApproval(),
        ),
      // Rejected profiles need changes first; saving them resubmits.
      StylistAccountState.rejected => (
          'Update your details',
          () => _open(context, const SellerProfileVerificationRoute()),
        ),
      StylistAccountState.unavailable => (
          'Turn on availability',
          () => context
              .read<SellerProfileMgtCubit>()
              .updateAvailability(isAvailable: true),
        ),
      StylistAccountState.flagged || StylistAccountState.banned => (
          'Contact support',
          () async {
            try {
              await AppHelper.sendMail(_supportEmail);
            } catch (_) {
              if (context.mounted) {
                AppHelper.showSnackBar(
                  context,
                  message: 'Email us at $_supportEmail',
                );
              }
            }
          },
        ),
      StylistAccountState.pendingApproval ||
      StylistAccountState.active ||
      StylistAccountState.unknown =>
        (null, null),
    };
    if (title == null || onPressed == null) return const [];
    final next = account.state == StylistAccountState.incomplete &&
            outstanding.isNotEmpty
        ? outstanding.first.label
        : null;
    return [
      14.verticalSpace,
      if (next != null) ...[
        Text(
          'Next step: $next',
          key: const Key('stylist_account_banner_next'),
          style: AppTextStyle.caption.copyWith(
            color: AppColors.blackShade1,
            fontWeight: FontWeight.w600,
          ),
        ),
        8.verticalSpace,
      ],
      BlocConsumer<SellerProfileMgtCubit, SellerProfileMgtState>(
        listenWhen: (p, c) =>
            p.submitForApprovalState != c.submitForApprovalState,
        listener: (context, state) {
          final submit = state.submitForApprovalState;
          if (submit.hasError) {
            final error = submit.error;
            AppHelper.showSnackBar(
              context,
              message: error is RemoteException &&
                      (error.errorResponse?.message.isNotEmpty ?? false)
                  ? error.errorResponse!.message
                  : 'Your profile could not be submitted. Please try again.',
            );
          } else if (submit.hasSuccess && submit.data == false) {
            // Submitted, but the backend did not move it to pending.
            AppHelper.showSnackBar(
              context,
              message: state.stylistAccount?.message ??
                  'Your profile could not be submitted yet.',
            );
          }
        },
        buildWhen: (p, c) =>
            p.submitForApprovalState != c.submitForApprovalState,
        builder: (context, state) => CustomButton(
          key: const Key('stylist_account_banner_action'),
          title: title,
          isLoading: account.state == StylistAccountState.notSubmitted &&
              state.submitForApprovalState.isLoading,
          onPressed: onPressed,
        ),
      ),
    ];
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.requirement, required this.email});

  final StylistAccountRequirement requirement;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final route = stylistRequirementRoute(requirement.key, email: email);
    return Semantics(
      button: route != null,
      label: requirement.label,
      child: InkWell(
        key: Key('stylist_requirement_${requirement.key}'),
        onTap: route == null ? null : () => _open(context, route),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            children: [
              const Icon(
                Iconsax.record,
                size: 16,
                color: AppColors.warningText,
              ),
              8.horizontalSpace,
              Expanded(
                child: Text(
                  requirement.label,
                  style: AppTextStyle.body2.copyWith(
                    color: AppColors.blackShade1,
                  ),
                ),
              ),
              if (route != null)
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: AppColors.grey3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens [route] and refreshes the backend status when the stylist returns.
Future<void> _open(BuildContext context, PageRouteInfo<dynamic> route) async {
  final cubit = context.read<SellerProfileMgtCubit>();
  await context.router.push(route);
  await cubit.getProfileDetails(true);
}

class _StateCopy {
  const _StateCopy({
    required this.title,
    required this.fallbackMessage,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  factory _StateCopy.of(StylistAccountState state) => switch (state) {
        StylistAccountState.incomplete => const _StateCopy(
            title: 'Your account is inactive',
            fallbackMessage:
                'Your account is currently inactive. Complete all required '
                'verification steps and obtain approval to activate your '
                'stylist account.',
            icon: Iconsax.warning_2,
            foreground: AppColors.warningText,
            background: AppColors.warningBg,
          ),
        StylistAccountState.notSubmitted => const _StateCopy(
            title: 'Submit your profile for approval',
            fallbackMessage:
                'Your profile still needs to be completed and submitted '
                'before it can be approved.',
            icon: Iconsax.document_upload,
            foreground: AppColors.warningText,
            background: AppColors.warningBg,
          ),
        StylistAccountState.pendingApproval => const _StateCopy(
            title: 'Awaiting approval',
            fallbackMessage:
                'All verification steps are complete. Your account will '
                'become active once it has been approved.',
            icon: Iconsax.clock,
            foreground: AppColors.warningText,
            background: AppColors.warningBg,
          ),
        StylistAccountState.rejected => const _StateCopy(
            title: 'Verification not approved',
            fallbackMessage:
                'Your verification was not approved. Review your details and '
                'update your profile to resubmit.',
            icon: Iconsax.close_circle,
            foreground: AppColors.dangerText,
            background: AppColors.dangerBg,
          ),
        StylistAccountState.unavailable => const _StateCopy(
            title: 'You are currently unavailable',
            fallbackMessage:
                'Your account is approved but unavailable. Turn your '
                'availability on to start receiving bookings.',
            icon: Iconsax.pause_circle,
            foreground: AppColors.warningText,
            background: AppColors.warningBg,
          ),
        StylistAccountState.flagged => const _StateCopy(
            title: 'Account restricted',
            fallbackMessage:
                'Your stylist account has been flagged and is inactive. '
                'Please contact support.',
            icon: Iconsax.flag,
            foreground: AppColors.dangerText,
            background: AppColors.dangerBg,
          ),
        StylistAccountState.banned => const _StateCopy(
            title: 'Account suspended',
            fallbackMessage:
                'Your account has been suspended. Please contact support.',
            icon: Iconsax.slash,
            foreground: AppColors.dangerText,
            background: AppColors.dangerBg,
          ),
        StylistAccountState.active ||
        StylistAccountState.unknown =>
          const _StateCopy(
            title: 'Your account is inactive',
            fallbackMessage:
                'Your account is currently inactive. Complete all required '
                'verification steps and obtain approval to activate your '
                'stylist account.',
            icon: Iconsax.info_circle,
            foreground: AppColors.warningText,
            background: AppColors.warningBg,
          ),
      };

  final String title;
  final String fallbackMessage;
  final IconData icon;
  final Color foreground;
  final Color background;
}
