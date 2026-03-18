import 'dart:io';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:snip_fair/gen/assets.gen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/features/account/seller/shared/profile_completeness_compact_view.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/profile_completeness.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/views/seller_profile_management_screen.dart';
import 'package:snip_fair/features/account/seller/profile_verification/cubit/seller_profile_verification_cubit.dart';

@RoutePage()
class SellerProfileVerificationScreen extends StatelessWidget implements AutoRouteWrapper {
  const SellerProfileVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SellerProfileMgtCubit>().state.profileDetails.data;
    final cubit = context.watch<SellerProfileVerificationCubit>();
    final isProfileVerified = profile?.profileCompleteness?.statusApproved ?? false;
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile Verification',
      ),
      bottomNavigationBar: isProfileVerified
          ? null
          : SafeArea(
              child: SizedBox(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      BlocListener<SellerProfileVerificationCubit, SellerProfileVerificationState>(
                    listenWhen: (previous, current) => previous.submitState != current.submitState,
                    listener: (context, state) async {
                      if (state.submitState.hasSuccess) {
                        await context.read<SellerProfileMgtCubit>().getProfileDetails(true);

                        // Optionally do something after refreshing profile details
                        final profileCompleteness = context
                            .read<SellerProfileMgtCubit>()
                            .state
                            .profileDetails
                            .data
                            ?.profileCompleteness;

                        if (profileCompleteness == null) {
                          context.pop();
                          return;
                        }

                        final isComplete =
                            AppHelper.getAllIncompleteSteps(profileCompleteness).isEmpty;

                        if (!isComplete) {
                          AppHelper.checkAndNavigateProfileCompletion(
                            context,
                            profileCompleteness,
                          );
                        } else {
                          context.pop();
                        }
                      }

                      if (state.submitState.hasError) {
                        AppHelper.showAppDialog<void>(
                          context,
                          OnFailDialogContent(
                            subtext: (state.submitState.error! as RemoteException)
                                    .errorResponse
                                    ?.message ??
                                '',
                            onDoneCallback: (_) {},
                          ),
                        );
                      }
                    },
                    child: CustomButton(
                      title: 'Submit Requirements',
                      isLoading: cubit.state.submitState.isLoading,
                      onPressed: cubit.state.canSubmitRequirements &&
                              (profile?.portfolios?.isNotEmpty ?? true)
                          ? cubit.submitRequirements
                          : null,
                    ),
                  ),
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: 'Verify your stylist profile to start earning',
                ),
                12.verticalSpace,
                SellerProfileCompletedCompactView(
                  profileCompleteness: profile?.profileCompleteness ?? ProfileCompleteness(),
                ),
                24.verticalSpace,
                SellerProfileAvatar(
                  profileDetails: profile,
                  radius: 50,
                ),
                24.verticalSpace,
                CustomTextField(
                  label: 'Bussiness name',
                  isRequired: true,
                  readOnly: isProfileVerified,
                  initialText: profile?.user?.stylistProfile?.businessName ?? '',
                  onChanged: cubit.onBusinessNameChanged,
                  isError: cubit.state.businessName.isNotValid,
                  descriptionText: cubit.state.businessName.displayError?.message,
                ),
                16.verticalSpace,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(text: 'Portfolio'),
                    5.verticalSpace,
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          if (profile?.portfolios?.isEmpty ?? true)
                            const AppText(text: 'Portfolio not set up')
                          else
                            const AppText(text: 'Portfolio set up'),
                          const Spacer(),
                          if (profile?.portfolios?.isEmpty ?? true)
                            SizedBox(
                              width: 160.w,
                              child: CustomButton(
                                title: 'Set Up Portfolio',
                                onPressed: () {
                                  context.router.push(const SellerPortfolioRoute());
                                },
                              ),
                            )
                          else
                            const CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.green,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,
                if (!isProfileVerified)
                  MultiDocumentPicker(
                    label: 'Upload Past Works',
                    onSelected: cubit.onSelectImages,
                  ),
                12.verticalSpace,
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: List.generate(
                    cubit.state.pastWorksFilePaths.length,
                    (index) => SizedBox.square(
                      dimension: isProfileVerified ? 100 : 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: cubit.state.pastWorksFilePaths[index].isLocalFilePath
                                ? Image.file(
                                    File(cubit.state.pastWorksFilePaths[index]),
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl:
                                        cubit.state.pastWorksFilePaths[index].completeImagePath(),
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) {
                                      return ColoredBox(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: SvgPicture.asset(
                                            Assets.images.logo,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          if (!isProfileVerified)
                            GestureDetector(
                              onTap: () {
                                cubit.onRemoveImage(
                                  cubit.state.pastWorksFilePaths[index],
                                );
                              },
                              child: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                16.verticalSpace,
                const SocialMediaAccountsView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerProfileVerificationCubit(
        getIt<ProfileRepository>(),
        context.read<SellerProfileMgtCubit>().state.profileDetails.data!,
      ),
      child: this,
    );
  }
}

class SocialMediaAccountsView extends StatefulWidget {
  const SocialMediaAccountsView({
    super.key,
  });

  @override
  State<SocialMediaAccountsView> createState() => _SocialMediaAccountsViewState();
}

class _SocialMediaAccountsViewState extends State<SocialMediaAccountsView> {
  final socailAppController = TextEditingController();
  final socailLinkController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SellerProfileVerificationCubit>();
    final profile = context.watch<SellerProfileMgtCubit>().state.profileDetails.data;
    final isProfileVerified = profile?.profileCompleteness?.statusApproved ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Media Accounts',
              style: AppTextStyle.body1.copyWith(
                fontSize: 14.sp,
                color: AppColors.black,
              ),
            ),
            5.horizontalSpace,
            Text(
              '*',
              style: AppTextStyle.body1.copyWith(
                fontSize: 12.sp,
                color: AppColors.contentColorRed,
              ),
            ),
          ],
        ),
        10.verticalSpace,
        ...List.generate(cubit.state.socials.length, (index) {
          final social = cubit.state.socials[index];
          return ListTile(
            title: AppText(text: social.socialApp ?? ''),
            subtitle: AppText(text: social.url ?? ''),
            tileColor: Colors.white,
            trailing: isProfileVerified
                ? null
                : IconButton(
                    onPressed: () {
                      cubit.onRemoveSocialAccount(social);
                    },
                    icon: const Icon(Icons.close),
                  ),
          );
        }),
        10.verticalSpace,
        if (!isProfileVerified)
          Column(
            children: [
              CustomTextField(
                textController: socailAppController,
                label: 'Social App',
                hint: 'e.g Instagram, Facebook',
                isRequired: true,
                onChanged: cubit.onSocialAppChanged,
                isError: cubit.state.socialApp.isNotValid,
                descriptionText: cubit.state.socialApp.displayError?.message,
              ),
              10.verticalSpace,
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      textController: socailLinkController,
                      label: 'Social Handle',
                      hint: '',
                      isRequired: true,
                      onChanged: cubit.onSocialUrlChanged,
                      isError: cubit.state.socialLink.isNotValid,
                      descriptionText: cubit.state.socialLink.displayError?.message,
                    ),
                  ),
                  10.horizontalSpace,
                  GestureDetector(
                    onTap: () {
                      if (cubit.state.canAddSocial) {
                        cubit.onAddSocialAccount();
                        socailAppController.clear();
                        socailLinkController.clear();
                        AppHelper.unfocus(context);
                      }
                    },
                    child: Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class MultiDocumentPicker extends StatefulWidget {
  const MultiDocumentPicker({
    required this.label,
    required this.onSelected,
    super.key,
    this.isError = false,
    this.descriptionText,
    this.initialFilePaths = const [],
  });

  final void Function(List<String>) onSelected;
  final bool isError;
  final String? descriptionText;
  final String label;
  final List<String> initialFilePaths;

  @override
  State<MultiDocumentPicker> createState() => _MultiDocumentPickerState();
}

class _MultiDocumentPickerState extends State<MultiDocumentPicker> {
  List<File>? _files;
  Future<void> _pickFile() async {
    final picker = ImagePicker();

    final files = await picker.pickMultiImage(imageQuality: 80, limit: 10);

    if (files.isNotEmpty) {
      _files = files.map((file) => File(file.path)).toList();
      setState(() {});
      widget.onSelected.call(_files!.map((e) => e.path).toList());
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: AppTextStyle.body1.copyWith(
                fontSize: 14.sp,
                color: AppColors.black,
              ),
            ),
            5.horizontalSpace,
            Text(
              '*',
              style: AppTextStyle.body1.copyWith(
                fontSize: 12.sp,
                color: AppColors.contentColorRed,
              ),
            ),
            5.horizontalSpace,
            AppText(
              text: '(Up to 10 files)',
              fontSize: 12.sp,
              color: AppColors.grey2,
            ),
          ],
        ),
        5.verticalSpace,
        GestureDetector(
          onTap: _pickFile,
          behavior: HitTestBehavior.translucent,
          child: DottedBorder(
            options: const RoundedRectDottedBorderOptions(
              radius: Radius.circular(12),
              dashPattern: [9, 3],
              color: AppColors.primaryColor,
              strokeWidth: 2,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 100,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.folder_add,
                      color: AppColors.grey2,
                    ),
                    12.verticalSpace,
                    const AppText(
                      text: 'Supports: JPG, JPEG, PNG (Max 5MB each)',
                      color: AppColors.grey2,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.descriptionText != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              4.verticalSpace,
              Text(
                widget.descriptionText!,
                style: AppTextStyle.caption.copyWith(
                  letterSpacing: -0.3,
                  fontSize: 10.sp,
                  color: widget.isError ? Colors.red : AppColors.black,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
