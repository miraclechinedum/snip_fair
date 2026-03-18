import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:auto_route/annotations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/keyboard_dismisser.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/features/account/customer/billing_info/cubit/customer_billing_info_cubit.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';

@RoutePage()
class CustomerBillingInfoScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const CustomerBillingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerBillingInfoCubit>();
    final initialBillingInfo = context
        .read<CustomerProfileMgtCubit>()
        .state
        .profileDetails
        .data
        ?.customerProfile;
    return BlocListener<CustomerBillingInfoCubit, CustomerBillingInfoState>(
      listenWhen: (previous, current) =>
          previous.updateBillingInfoState != current.updateBillingInfoState,
      listener: (context, state) {
        if (state.updateBillingInfoState.hasSuccess) {
          context.read<CustomerProfileMgtCubit>().getProfileDetails();
          AppHelper.showSnackBar(
            context,
            message: 'Billing information updated successfully',
          );
          context.pop();
        }

        if (state.updateBillingInfoState.hasError) {
          AppHelper.showSnackBar(
            context,
            message: (state.updateBillingInfoState.error! as RemoteException)
                    .errorResponse
                    ?.message
                     ??
                'Failed to update billing information',
          );
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
                    const AppText(
                      text: 'Billing Information',
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    20.verticalSpace,
                    BlocSelector<CustomerBillingInfoCubit,
                        CustomerBillingInfoState, StringInput>(
                      selector: (state) {
                        return state.name;
                      },
                      builder: (context, name) {
                        return CustomTextField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          isRequired: true,
                          onChanged: cubit.nameChanged,
                          initialText: initialBillingInfo?.billingName ?? '',
                          isError: name.isNotValid,
                          descriptionText: name.displayError?.message,
                        );
                      },
                    ),
                    16.verticalSpace,
                    BlocSelector<CustomerBillingInfoCubit,
                        CustomerBillingInfoState, StringInput>(
                      selector: (state) {
                        return state.email;
                      },
                      builder: (context, email) {
                        return CustomTextField(
                          label: 'Email Address',
                          hint: 'Enter your email address',
                          isRequired: true,
                          onChanged: cubit.emailChanged,
                          initialText: initialBillingInfo?.billingEmail ?? '',
                          isError: email.isNotValid,
                          descriptionText: email.displayError?.message,
                        );
                      },
                    ),
                    16.verticalSpace,
                    BlocSelector<CustomerBillingInfoCubit,
                        CustomerBillingInfoState, StringInput>(
                      selector: (state) {
                        return state.city;
                      },
                      builder: (context, city) {
                        return CustomTextField(
                          label: 'City',
                          hint: 'Enter your city',
                          isRequired: true,
                          onChanged: cubit.cityChanged,
                          initialText:
                              initialBillingInfo?.billingCity?.toString() ?? '',
                          isError: city.isNotValid,
                          descriptionText: city.displayError?.message,
                        );
                      },
                    ),
                    16.verticalSpace,
                    BlocSelector<CustomerBillingInfoCubit,
                        CustomerBillingInfoState, StringInput>(
                      selector: (state) {
                        return state.zipCode;
                      },
                      builder: (context, zipCode) {
                        return CustomTextField(
                          label: 'Zip Code',
                          hint: 'Enter your zip code',
                          isRequired: true,
                          onChanged: cubit.zipCodeChanged,
                          initialText:
                              initialBillingInfo?.billingZip?.toString() ?? '',
                          isError: zipCode.isNotValid,
                          descriptionText: zipCode.displayError?.message,
                        );
                      },
                    ),
                    16.verticalSpace,
                    BlocSelector<CustomerBillingInfoCubit,
                        CustomerBillingInfoState, StringInput>(
                      selector: (state) {
                        return state.zipCode;
                      },
                      builder: (context, zipCode) {
                        return CustomPlaceSearchField(
                          label: 'Location',
                          hintText: 'Enter your location',
                          initialPlace: initialBillingInfo?.billingLocation !=
                                  null
                              ? GeoPlace(
                                  address: initialBillingInfo!.billingLocation!
                                      .toString(),
                                  lat: 0,
                                  lng: 0,)
                              : null,
                          onSelected: (place) => place != null
                              ? cubit.locationChanged(place.address)
                              : null,
                          isError: zipCode.isNotValid,
                          descriptionText: zipCode.displayError?.message,
                        );
                      },
                    ),
                    16.verticalSpace,
                    14.verticalSpace,
                    BlocBuilder<CustomerBillingInfoCubit,
                        CustomerBillingInfoState>(
                      builder: (context, state) {
                        return CustomButton(
                          title: 'Update billing information',
                          isLoading: state.updateBillingInfoState.isLoading,
                          onPressed: state.canSubmit ? cubit.submit : null,
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
    final initialBillingInfo = context
        .read<CustomerProfileMgtCubit>()
        .state
        .profileDetails
        .data
        ?.customerProfile;
    return BlocProvider(
      create: (context) => getIt<CustomerBillingInfoCubit>()
        ..nameChanged(initialBillingInfo?.billingName ?? '')
        ..locationChanged(initialBillingInfo?.billingLocation?.toString() ?? '')
        ..cityChanged(initialBillingInfo?.billingCity?.toString() ?? '')
        ..zipCodeChanged(initialBillingInfo?.billingZip?.toString() ?? '')
        ..emailChanged(initialBillingInfo?.billingEmail ?? ''),
      child: this,
    );
  }
}
