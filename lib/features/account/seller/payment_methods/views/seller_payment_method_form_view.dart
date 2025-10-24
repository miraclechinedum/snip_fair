// ignore_for_file: use_build_context_synchronously

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/domain/entities/bank/bank.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/seller/payment_methods/cubit/seller_payment_methods_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

class SellerPaymentMethodFormWidget extends StatelessWidget {
  const SellerPaymentMethodFormWidget({super.key, this.paymentMethod});

  final PaymentMethod? paymentMethod;

  static Future<void> show(BuildContext context,
      [PaymentMethod? paymentMethod]) {
    return AppHelper.showCustomModalBottomSheet(
      context: context,
      modal: BlocProvider.value(
        value: context.read<SellerPaymentMethodsCubit>()..edit(paymentMethod),
        child: SellerPaymentMethodFormWidget(
          paymentMethod: paymentMethod,
        ),
      ),
      isDarkMode: false,
    )..whenComplete(() {
        context.read<SellerPaymentMethodsCubit>().resetForm();
      });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SellerPaymentMethodsCubit>();
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
                      text: paymentMethod != null
                          ? 'Update Payment Method'
                          : 'Add Payment Method',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    const AppText(
                      text: 'Work details',
                      fontSize: 12,
                    ),
                    24.verticalSpace,
                    CustomTextField(
                      label: 'Account Holder Name',
                      isRequired: true,
                      initialText: paymentMethod?.accountName,
                      hint: '',
                      onChanged: cubit.onAccountNameChanged,
                      isError: cubit.state.accountName.isNotValid,
                      descriptionText:
                          cubit.state.accountName.displayError?.message,
                    ),
                    12.verticalSpace,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Name',
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
                    BlocBuilder<SellerPaymentMethodsCubit,
                        SellerPaymentMethodsState>(
                      builder: (context, state) {
                        final banks = state.banks.data ?? [];
                        final editBank = banks
                            .where((e) => e.name == paymentMethod?.bankName)
                            .firstOrNull;
                        return DropdownButtonFormField<Bank>(
                          value: state.selectedBank ?? editBank,
                          isExpanded: true,
                          items: List.generate(banks.length, (index) {
                            return DropdownMenuItem<Bank>(
                              value: banks[index],
                              child: AppText(
                                text: banks[index].name ?? '',
                                fontSize: 16,
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              cubit.onSelectBank(value);
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
                      label: 'Account Number',
                      isRequired: true,
                      initialText: paymentMethod?.accountNumber,
                      hint: '',
                      onChanged: cubit.onAccountNumberChanged,
                      isError: cubit.state.accountNumber.isNotValid,
                      descriptionText:
                          cubit.state.accountNumber.displayError?.message,
                    ),
                    12.verticalSpace,
                    BlocBuilder<SellerPaymentMethodsCubit,
                        SellerPaymentMethodsState>(
                      buildWhen: (previous, current) =>
                          previous.selectedBank != current.selectedBank,
                      builder: (context, state) {
                        return CustomTextField(
                          textController: TextEditingController(
                            text: state.selectedBank?.branchCode ??
                                paymentMethod?.routingNumber!,
                          ),
                          label: 'Branch Code',
                          isRequired: true,
                          readOnly: true,
                          hint: '',
                          onChanged: cubit.onBranchNameChanged,
                          isError: cubit.state.branchName.isNotValid,
                          descriptionText:
                              cubit.state.branchName.displayError?.message,
                        );
                      },
                    ),
                    12.verticalSpace,
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
            child: BlocListener<SellerPaymentMethodsCubit,
                SellerPaymentMethodsState>(
              listenWhen: (previous, current) =>
                  previous.addPaymentMethodState !=
                  current.addPaymentMethodState,
              listener: (context, state) async {
                if (state.addPaymentMethodState.hasSuccess) {
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

                if (state.addPaymentMethodState.hasError) {
                  AppHelper.showAppDialog<void>(
                    context,
                    OnFailDialogContent(
                      subtext: (state.addPaymentMethodState.error!
                                  as RemoteException)
                              .errorResponse
                              ?.message ??
                          '',
                      onDoneCallback: (_) {},
                    ),
                  );
                }
              },
              child: CustomButton(
                isLoading: cubit.state.addPaymentMethodState.isLoading,
                title: paymentMethod != null ? 'Update Method' : 'Add Method',
                onPressed: cubit.state.canSubmit
                    ? () => cubit.updateOrCreatePaymentMethod(paymentMethod?.id)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
