import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/features/account/seller/payment_methods/cubit/seller_payment_methods_cubit.dart';
import 'package:snip_fair/features/account/seller/payment_methods/views/seller_payment_method_form_view.dart';

@RoutePage()
class SellerPaymentMethodsScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const SellerPaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment Methods',
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () {
              SellerPaymentMethodFormWidget.show(context);
            },
            child: Material(
              elevation: 6,
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.appgradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    10.horizontalSpace,
                    const AppText(
                      text: 'Add New Account',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              text: 'Your payment methods',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            12.verticalSpace,
            Expanded(
              child: BlocBuilder<SellerPaymentMethodsCubit,
                  SellerPaymentMethodsState>(
                builder: (context, state) {
                  if (state.paymentMethods.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final methods = state.paymentMethods.data ?? [];
                  if (methods.isEmpty) {
                    return const Center(
                      child: AppText(text: 'No Payment Methods'),
                    );
                  }
                  return ListView.separated(
                    itemBuilder: (context, index) {
                      final method = methods[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: AppColors.grey300,
                          ),
                        ),
                        leading: Checkbox(
                          value: method.isActive,
                          onChanged: (value) {
                            context
                                .read<SellerPaymentMethodsCubit>()
                                .togglePaymentMethodActive(method.id!);
                          },
                          activeColor: AppColors.primaryColor,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                                child: AppText(
                              text: method.bankName ?? 'N/A',
                              maxLines: 1,
                            )),
                            12.horizontalSpace,
                            // ignore: use_if_null_to_convert_nulls_to_bools
                            if (method.isDefault == true)
                              const AppText(
                                text: 'DEFAULT',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                          ],
                        ),
                        subtitle: AppText(
                          text:
                              'Acct No: ${method.accountNumber.showLast4Digits()}',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              if (method.isDefault == false)
                                PopupMenuItem<void>(
                                  onTap: () {
                                    context
                                        .read<SellerPaymentMethodsCubit>()
                                        .makePaymentMethodDefault(method.id!);
                                  },
                                  child: const ListTile(
                                    leading: Icon(
                                      Iconsax.empty_wallet_tick,
                                      size: 20,
                                    ),
                                    title: AppText(text: 'Set as Default'),
                                  ),
                                ),
                              PopupMenuItem<void>(
                                onTap: () {
                                  SellerPaymentMethodFormWidget.show(
                                    context,
                                    method,
                                  );
                                },
                                child: const ListTile(
                                  leading: Icon(
                                    Iconsax.edit_2,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  title: AppText(text: 'Edit account'),
                                ),
                              ),
                              PopupMenuItem<void>(
                                onTap: () {
                                  context
                                      .read<SellerPaymentMethodsCubit>()
                                      .deletePaymentMethod(method.id!);
                                },
                                child: const ListTile(
                                  leading: Icon(
                                    Iconsax.trash,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  title: AppText(text: 'Delete account'),
                                ),
                              ),
                            ];
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => 12.verticalSpace,
                    itemCount: methods.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SellerPaymentMethodsCubit>()
        ..getPaymentMethods()
        ..getBanks(),
      child: this,
    );
  }
}
