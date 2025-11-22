import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/utils/input/email_input.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/customer/preferences/cubit/customer_prefs_settings_cubit.dart';
import 'package:snip_fair/features/account/seller/personal_details/cubit/seller_personal_details_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

@RoutePage()
class SellerPersonalDetailsScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const SellerPersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SellerPersonalDetailsCubit>();
    final currentProfile =
        context.read<SellerProfileMgtCubit>().state.profileDetails.data ??
            StylistProfileDetails();
    return BlocListener<SellerPersonalDetailsCubit, SellerPersonalDetailsState>(
      listenWhen: (previous, current) =>
          previous.updateProfile != current.updateProfile,
      listener: (context, state) {
        if (state.updateProfile.hasSuccess) {
          context.read<SellerProfileMgtCubit>().getProfileDetails(true);
          AppHelper.showAppDialog(
            context,
            const OnSuccessDialogContent(
                subtext: 'Profile Updated Successfully'),
          );
        }
      },
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
                    text: 'Personal Details',
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  5.verticalSpace,
                  const AppText(
                    text: 'Update your personal details',
                  ),
                  20.verticalSpace,
                  BlocSelector<SellerPersonalDetailsCubit,
                      SellerPersonalDetailsState, StringInput>(
                    selector: (state) {
                      return state.firstName;
                    },
                    builder: (context, firstName) {
                      return CustomTextField(
                        label: 'First Name',
                        hint: 'Enter your first name',
                        initialText: currentProfile.user!.firstName!,
                        isRequired: true,
                        onChanged: cubit.onFirstNameChanged,
                        isError: firstName.isNotValid,
                        descriptionText: firstName.displayError?.message,
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocSelector<SellerPersonalDetailsCubit,
                      SellerPersonalDetailsState, StringInput>(
                    selector: (state) {
                      return state.lastName;
                    },
                    builder: (context, lastName) {
                      return CustomTextField(
                        label: 'Last Name',
                        hint: 'Enter your last name',
                        initialText: currentProfile.user!.lastName!,
                        isRequired: true,
                        onChanged: cubit.onLastNameChanged,
                        isError: lastName.isNotValid,
                        descriptionText: lastName.displayError?.message,
                      );
                    },
                  ),
                  16.verticalSpace,
                  CustomTextField(
                    label: 'Email',
                    hint: 'example@gmail.com',
                    isRequired: true,
                    readOnly: true,
                    initialText: currentProfile.user!.email!,
                  ),
                  16.verticalSpace,
                  CustomPhoneTextField(
                    label: 'Phone',
                    isRequired: true,
                    dialCode: '+27',
                    initialPhone:
                        PhoneNumber.parse(currentProfile.user!.phone!),
                    controller:
                        TextEditingController(text: currentProfile.user!.phone),
                    onInputChanged: (phone) =>
                        cubit.onPhoneChanged(phone.international),
                  ),
                  12.verticalSpace,
                  const AppText(
                    text: 'Gender',
                    fontSize: 12,
                  ),
                  5.verticalSpace,
                  DropdownButtonFormField<StylistGender>(
                    initialValue: currentProfile.user?.gender != null
                        ? StylistGender.values.firstWhere(
                            (e) => e.name == currentProfile.user?.gender,
                            orElse: () => StylistGender.none,
                          )
                        : null,
                    items: StylistGender.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      cubit.onGenderChanged(value.name);
                    },
                    decoration: AppColors.inputDecoration.copyWith(
                      hintText: 'Gender',
                    ),
                  ),
                  12.verticalSpace,
                  BlocSelector<SellerPersonalDetailsCubit,
                      SellerPersonalDetailsState, StringInput>(
                    selector: (state) {
                      return state.businessName;
                    },
                    builder: (context, businessName) {
                      return CustomTextField(
                        label: 'Business/Salon name',
                        hint: 'Enter your business name',
                        isRequired: true,
                        initialText:
                            currentProfile.user!.stylistProfile!.businessName!,
                        onChanged: cubit.onBusinessNameChanged,
                        isError: businessName.isNotValid,
                        descriptionText: businessName.displayError?.message,
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocSelector<SellerPersonalDetailsCubit,
                      SellerPersonalDetailsState, StringInput>(
                    selector: (state) {
                      return state.address;
                    },
                    builder: (context, address) {
                      return CustomPlaceSearchField(
                        onSelected: (p0) {
                          if (p0 != null) {
                            cubit.onAddressChanged(p0.address);
                          }
                        },
                        label: 'Location',
                        hintText: 'Search for address',
                        isError: address.isNotValid,
                        initialPlace: GeoPlace(
                          address: currentProfile.user!.country!,
                          lat: 0,
                          lng: 0,
                        ),
                        descriptionText: address.displayError?.message,
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocSelector<SellerPersonalDetailsCubit,
                      SellerPersonalDetailsState, StringInput>(
                    selector: (state) {
                      return state.yearsOfExperience;
                    },
                    builder: (context, yearsOfExperience) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Years of experience',
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
                          DropdownButtonFormField<int>(
                            value: int.tryParse(yearsOfExperience.value) ??
                                currentProfile
                                    .user?.stylistProfile?.yearsOfExperience,
                            items: List.generate(20, (index) {
                              return DropdownMenuItem<int>(
                                child: AppText(
                                  text: '${index + 1}',
                                  fontSize: 16,
                                ),
                                value: index + 1,
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                cubit.onYearsOfExperienceChanged(
                                  value.toString(),
                                );
                              }
                            },
                            style: AppTextStyle.body1.copyWith(
                              color: AppColors.grey900,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: AppColors.inputDecoration
                                .copyWith(hintText: 'Select'),
                          ),
                          if (yearsOfExperience.displayError?.message != null)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                4.verticalSpace,
                                Text(
                                  yearsOfExperience.displayError!.message,
                                  style: AppTextStyle.caption.copyWith(
                                    letterSpacing: -0.3,
                                    fontSize: 10.sp,
                                    color: yearsOfExperience.isNotValid
                                        ? Colors.red
                                        : AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocSelector<SellerPersonalDetailsCubit,
                      SellerPersonalDetailsState, StringInput>(
                    selector: (state) {
                      return state.bio;
                    },
                    builder: (context, bio) {
                      return CustomTextField(
                        label: 'Professional Bio',
                        hint: 'Enter your bio',
                        isRequired: true,
                        maxLines: 4,
                        initialText: currentProfile.user?.bio,
                        onChanged: cubit.onBioChanged,
                        isError: bio.isNotValid,
                        descriptionText: bio.displayError?.message,
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocBuilder<SellerPersonalDetailsCubit,
                      SellerPersonalDetailsState>(
                    builder: (context, state) {
                      return CustomButton(
                        title: 'Update Profile',
                        isLoading: state.updateProfile.isLoading,
                        onPressed: () {
                          cubit.updateBusinessInfo(currentProfile);
                        },
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
    final currentProfile =
        context.read<SellerProfileMgtCubit>().state.profileDetails.data ??
            StylistProfileDetails();
    return BlocProvider(
      create: (context) => getIt<SellerPersonalDetailsCubit>()
        ..onFirstNameChanged(currentProfile.user!.firstName!)
        ..onLastNameChanged(currentProfile.user!.lastName!)
        ..onPhoneChanged(currentProfile.user!.phone!)
        ..onAddressChanged(currentProfile.user!.country!)
        ..onYearsOfExperienceChanged(
          currentProfile.user!.stylistProfile!.yearsOfExperience!.toString(),
        )
        ..onBioChanged(currentProfile.user!.bio!)
        ..onBusinessNameChanged(
          currentProfile.user!.stylistProfile!.businessName!,
        ),
      child: this,
    );
  }
}
