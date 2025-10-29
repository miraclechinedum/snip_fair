import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:iconsax/iconsax.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile_details.dart';
import 'package:snip_fair/core/domain/entities/dispute_list/customer.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/utils/base/base_stateless_page.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/customer/personal_details/cubit/customer_personal_details_cubit.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/personal_details/cubit/seller_personal_details_cubit.dart';

@RoutePage()
class CustomerPersonalDetailsScreen
    extends BaseStatelessPage<CustomerPersonalDetailsCubit>
    implements AutoRouteWrapper {
  const CustomerPersonalDetailsScreen({super.key});

  @override
  Widget buildPage(BuildContext context) {
    final cubit = context.read<CustomerPersonalDetailsCubit>();
    final currentProfile =
        context.read<CustomerProfileMgtCubit>().state.profileDetails.data ??
            CustomerProfileDetails();
    return BlocListener<CustomerPersonalDetailsCubit,
        CustomerPersonalDetailsState>(
      listenWhen: (previous, current) =>
          previous.updateProfile != current.updateProfile,
      listener: (context, state) async {
        if (state.updateProfile.hasSuccess) {
          context
              .read<CustomerProfileMgtCubit>()
              .getProfileDetails(true)
              .then((_) {
            context.router.pop();
          });
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(),
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
                  BlocBuilder<CustomerProfileMgtCubit, CustomerProfileMgtState>(
                    builder: (context, state) {
                      return GestureDetector(
                        onTap: () {
                          context
                              .read<CustomerProfileMgtCubit>()
                              .pickAndUploadAvatar();
                        },
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CustomerProfileAvatar(
                                profileDetails: state.profileDetails.data,
                                isLoading: state.updateAvatarState.isLoading,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.contentColorBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.edit,
                                  size: 15,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocSelector<CustomerPersonalDetailsCubit,
                      CustomerPersonalDetailsState, StringInput>(
                    selector: (state) {
                      return state.firstName;
                    },
                    builder: (context, firstName) {
                      return CustomTextField(
                        label: 'First Name',
                        hint: 'Enter your first name',
                        initialText: currentProfile.user?.firstName,
                        isRequired: true,
                        onChanged: cubit.onFirstNameChanged,
                        isError: firstName.isNotValid,
                        descriptionText: firstName.displayError?.message,
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocSelector<CustomerPersonalDetailsCubit,
                      CustomerPersonalDetailsState, StringInput>(
                    selector: (state) {
                      return state.lastName;
                    },
                    builder: (context, lastName) {
                      return CustomTextField(
                        label: 'Last Name',
                        hint: 'Enter your last name',
                        initialText: currentProfile.user?.lastName,
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
                    initialText: currentProfile.user?.email,
                  ),
                  16.verticalSpace,
                  CustomPhoneTextField(
                    label: 'Phone',
                    isRequired: true,
                    dialCode: '+27',
                    initialPhone: currentProfile.user?.phone != null &&
                            currentProfile.user!.phone!.isNotEmpty
                        ? PhoneNumber.parse(currentProfile.user?.phone ?? '')
                        : null,
                    controller: TextEditingController(
                      text: currentProfile.user?.phone ?? '',
                    ),
                    onInputChanged: (phone) =>
                        cubit.onPhoneChanged(phone.international),
                  ),
                  12.verticalSpace,
                  BlocSelector<CustomerPersonalDetailsCubit,
                      CustomerPersonalDetailsState, StringInput>(
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
                        initialPlace: currentProfile.user?.country != null
                            ? GeoPlace(
                                address: currentProfile.user!.country!,
                                lat: 0,
                                lng: 0,
                              )
                            : null,
                        descriptionText: address.displayError?.message,
                      );
                    },
                  ),
                  16.verticalSpace,
                  BlocSelector<CustomerPersonalDetailsCubit,
                      CustomerPersonalDetailsState, StringInput>(
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
                  BlocBuilder<CustomerPersonalDetailsCubit,
                      CustomerPersonalDetailsState>(
                    builder: (context, state) {
                      return CustomButton(
                        title: 'Update Profile',
                        isLoading: state.updateProfile.isLoading,
                        onPressed: () {
                          cubit.updateProfile(currentProfile);
                        },
                      );
                    },
                  ),
                  12.verticalSpace,
                  Center(
                    child: BlocListener<CustomerProfileMgtCubit,
                        CustomerProfileMgtState>(
                      listenWhen: (previous, current) =>
                          previous.deleteAccountState !=
                          current.deleteAccountState,
                      listener: (context, state) {
                        if (state.deleteAccountState.hasSuccess) {
                          Fluttertoast.showToast(
                            msg: 'Account deleted successfully',
                          );
                          // Navigate to initial route or login screen
                          context.read<AppCubit>().onLogout();
                        }
                      },
                      child: TextButton(
                        onPressed: () {
                          AppHelper.showAppDialog(
                            context,
                            OnConfirmDialog(
                              title: 'Delete Account',
                              content:
                                  'Are you sure you want to delete your account? This action cannot be undone.',
                              onConfirmed: (ctx) {
                                context
                                    .read<CustomerProfileMgtCubit>()
                                    .deleteAccount();
                              },
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          textStyle: AppTextStyle.body2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          minimumSize: Size.fromHeight(40.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('DELETE ACCOUNT'),
                      ),
                    ),
                  ),
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
        context.read<CustomerProfileMgtCubit>().state.profileDetails.data ??
            CustomerProfileDetails();
    return BlocProvider(
      create: (context) => getIt<CustomerPersonalDetailsCubit>()
        ..onFirstNameChanged(currentProfile.user?.firstName ?? '')
        ..onLastNameChanged(currentProfile.user?.lastName ?? '')
        ..onPhoneChanged(currentProfile.user?.phone ?? '')
        ..onAddressChanged(currentProfile.user?.country ?? '')
        ..onBioChanged(currentProfile.user?.bio ?? '')
        ..onAvatarChanged(currentProfile.user?.avatar ?? ''),
      child: this,
    );
  }
}

class CustomerProfileAvatar extends StatelessWidget {
  const CustomerProfileAvatar({
    super.key,
    required this.profileDetails,
    this.radius = 30,
    this.isLoading = false,
  });

  final CustomerProfileDetails? profileDetails;
  final double radius;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: profileDetails?.user?.avatar != null
          ? CachedNetworkImageProvider(
              profileDetails!.user!.avatar!.completeImagePath(),
            )
          : null,
      child: isLoading
          ? const CircularProgressIndicator()
          : profileDetails?.user?.avatar != null
              ? null
              : AppText(
                  text: profileDetails?.user?.firstName != null &&
                          profileDetails?.user?.lastName != null
                      ? AppHelper.initialsFromName(
                          profileDetails!.user!.firstName!,
                          profileDetails!.user!.lastName!,
                        )
                      : 'N/A',
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
    );
  }
}
