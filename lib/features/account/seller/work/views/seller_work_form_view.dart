import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_item.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_verification/views/seller_profile_verification_screen.dart';
import 'package:snip_fair/features/account/seller/work/cubit/seller_works_cubit.dart';
import 'package:snip_fair/gen/assets.gen.dart';

class SellerWorkFormWidget extends StatelessWidget {
  const SellerWorkFormWidget({super.key, this.workItem});

  final WorkItem? workItem;

  static Future<void> show(BuildContext context, [WorkItem? workItem]) {
    return AppHelper.showCustomModalBottomSheet(
      context: context,
      modal: BlocProvider.value(
        value: context.read<SellerWorksCubit>()..edit(workItem),
        child: SellerWorkFormWidget(
          workItem: workItem,
        ),
      ),
      isDarkMode: false,
    )..whenComplete(() {
        context.read<SellerWorksCubit>().resetForm();
      });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SellerWorksCubit>();
    return SafeArea(
      child: Column(
        children: [
          16.verticalSpace,
          const ModalPill(),
          12.verticalSpace,
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: workItem != null ? 'Update Work' : 'Add New Work',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    const AppText(
                      text: 'Work details',
                      fontSize: 12,
                    ),
                    24.verticalSpace,
                    CustomTextField(
                      label: 'Title',
                      isRequired: true,
                      initialText: workItem?.title,
                      hint: '',
                      onChanged: cubit.onTitleChanged,
                      isError: cubit.state.workTitle.isNotValid,
                      descriptionText:
                          cubit.state.workTitle.displayError?.message,
                    ),
                    12.verticalSpace,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: AppTextStyle.body1.copyWith(
                            fontSize: 12.sp,
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
                    5.verticalSpace,
                    BlocBuilder<SellerWorksCubit, SellerWorksState>(
                      builder: (context, state) {
                        final categories = state.workCategories.data ?? [];
                        return DropdownButtonFormField<WorkCategory>(
                          value: state.selectedWorkCategory,
                          items: List.generate(categories.length, (index) {
                            final cat = categories[index];
                            return DropdownMenuItem<WorkCategory>(
                              value: cat,
                              child: AppText(
                                text: cat.name ?? 'N/A',
                                fontSize: 16,
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              cubit.onCategoryChanged(value);
                            }
                          },
                          style: AppTextStyle.body1.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: AppColors.inputDecoration
                              .copyWith(hintText: 'Select option'),
                        );
                      },
                    ),
                    12.verticalSpace,
                    CustomTextField(
                      label: 'Add Price',
                      isRequired: true,
                      hint: '',
                      initialText: workItem?.price?.toStringAsFixed(2),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      inputType: TextInputType.number,
                      onChanged: (value) {
                        final price = value.isEmpty ? 0 : double.parse(value);
                        cubit.onPriceChanged(price.toDouble());
                      },
                      isError: cubit.state.price <
                              (AppHelper.appSettings(context)
                                      .minBookingAmount ??
                                  0) ||
                          cubit.state.price >
                              (AppHelper.appSettings(context)
                                      .maxBookingAmount ??
                                  0),
                      descriptionText: cubit.state.price <
                                  (AppHelper.appSettings(context)
                                          .minBookingAmount ??
                                      0) ||
                              cubit.state.price >
                                  (AppHelper.appSettings(context)
                                          .maxBookingAmount ??
                                      0)
                          ? 'Price must fall within ${AppHelper.appSettings(context).minBookingAmount} - ${AppHelper.appSettings(context).maxBookingAmount}'
                          : null,
                    ),
                    12.verticalSpace,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration',
                          style: AppTextStyle.body1.copyWith(
                            fontSize: 12.sp,
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
                    5.verticalSpace,
                    BlocBuilder<SellerWorksCubit, SellerWorksState>(
                      builder: (context, state) {
                        // final categories = state.workCategories.data ?? [];
                        return DropdownButtonFormField<int>(
                          value: state.durationInHours > 0
                              ? state.durationInHours
                              : null,
                          items: List.generate(12, (index) {
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: AppText(
                                text: '${index + 1} Hours',
                                fontSize: 16,
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              cubit.onDurationChanged(value);
                            }
                          },
                          style: AppTextStyle.body1.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: AppColors.inputDecoration
                              .copyWith(hintText: 'Select option'),
                        );
                      },
                    ),
                    12.verticalSpace,
                    CustomTextField(
                      label: 'Description',
                      isRequired: true,
                      initialText: workItem?.description,
                      hint:
                          'Describe the work, techniques and any special detail',
                      maxLines: 4,
                      onChanged: cubit.onDescriptionChanged,
                      isError: cubit.state.workDescription.isNotValid,
                      descriptionText:
                          cubit.state.workDescription.displayError?.message,
                    ),
                    12.verticalSpace,
                    MultiDocumentPicker(
                      label: 'Media',
                      onSelected: cubit.onSelectImages,
                      isError: cubit.state.workFilePaths.isEmpty,
                      descriptionText: cubit.state.workFilePaths.isEmpty
                          ? 'Provide atleast one media file'
                          : null,
                    ),
                    12.verticalSpace,
                    Wrap(
                      spacing: 5,
                      children: List.generate(
                        cubit.state.workFilePaths.length,
                        (index) => SizedBox.square(
                          dimension: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: cubit.state.workFilePaths[index]
                                        .isLocalFilePath
                                    ? Image.file(
                                        File(cubit.state.workFilePaths[index]),
                                        fit: BoxFit.cover,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: cubit
                                            .state.workFilePaths[index]
                                            .completeImagePath(),
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
                              GestureDetector(
                                onTap: () {
                                  cubit.onRemoveImage(
                                    cubit.state.workFilePaths[index],
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
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.grey200,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: BlocListener<SellerWorksCubit, SellerWorksState>(
              listenWhen: (previous, current) =>
                  previous.addWorkState != current.addWorkState,
              listener: (context, state) async {
                if (state.addWorkState.hasSuccess) {
                  await context
                      .read<SellerProfileMgtCubit>()
                      .getProfileDetails(true);

                  // Optionally do something after refreshing profile details
                  final profileCompleteness = context
                      .read<SellerProfileMgtCubit>()
                      .state
                      .profileDetails
                      .data
                      ?.profileCompleteness;

                  if (profileCompleteness == null) {
                    Navigator.pop(context);
                    return;
                  }

                  Navigator.pop(context);

                  final isComplete =
                      AppHelper.getAllIncompleteSteps(profileCompleteness)
                          .isEmpty;

                  if (!isComplete) {
                    AppHelper.checkAndNavigateProfileCompletion(
                      context,
                      profileCompleteness,
                    );
                  }
                }

                if (state.addWorkState.hasError) {
                  AppHelper.showAppDialog<void>(
                    context,
                    OnFailDialogContent(
                      subtext: (state.addWorkState.error! as RemoteException)
                              .errorResponse
                              ?.message ??
                          '',
                      onDoneCallback: (_) {},
                    ),
                  );
                }
              },
              child: CustomButton(
                isLoading: cubit.state.addWorkState.isLoading,
                title: workItem != null ? 'Update Work' : 'Add Work',
                onPressed: cubit.state.canSubmitWork
                    ? () => cubit.updateOrCreateWorkItem(workItem?.id)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
