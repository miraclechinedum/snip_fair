import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/services/location_service.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscure;
  final TextEditingController? textController;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validation;
  final TextInputType? inputType;
  final String? initialText;
  final String? descriptionText;
  final bool readOnly;
  final bool isError;
  final bool isSuccess;
  final int? minLines;
  final int? maxLines;
  final TextCapitalization? textCapitalization;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool isRequired;

  const CustomTextField({
    Key? key,
    this.label,
    this.suffixIcon,
    this.prefixIcon,
    this.onTap,
    this.obscure = false,
    this.validation,
    this.onChanged,
    this.textController,
    this.inputType,
    this.initialText,
    this.descriptionText,
    this.readOnly = false,
    this.isError = false,
    this.isSuccess = false,
    this.textCapitalization,
    this.textInputAction,
    this.hint = 'Type here',
    this.minLines,
    this.maxLines = 1,
    this.inputFormatters,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label!,
                style: AppTextStyle.body1.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.black,
                ),
              ),
              5.horizontalSpace,
              if (isRequired)
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
        ],
        TextFormField(
          cursorColor: AppColors.primaryColor,
          onTap: onTap,
          onChanged: onChanged,
          obscureText: obscure,
          obscuringCharacter: '*',
          controller: textController,
          validator: validation,
          textAlignVertical: TextAlignVertical.center,
          style: AppTextStyle.body1.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w400,
          ),
          cursorWidth: 1,
          minLines: minLines,

          maxLines: maxLines,
          keyboardType: inputType,
          initialValue: initialText,
          readOnly: readOnly,
          
          inputFormatters: inputFormatters,
          
          //autovalidateMode: AutovalidateMode.always,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            prefixIconConstraints:
                BoxConstraints(maxHeight: 30.h, minWidth: 50.w),

            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12).dg,
              child: suffixIcon,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,

            hintText: hint,
            hintStyle: AppTextStyle.body2.copyWith(
              color: AppColors.grey2,
            ),
            fillColor: readOnly ? AppColors.grey100 : AppColors.white,
            filled: true,

            alignLabelWithHint: true,

            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14).dg,
            // floatingLabelBehavior: FloatingLabelBehavior.always,

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.contentColorRed),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.grey2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.grey2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
        if (descriptionText != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              4.verticalSpace,
              Text(
                descriptionText!,
                style: AppTextStyle.caption.copyWith(
                  letterSpacing: -0.3,
                  fontSize: 10.sp,
                  color: isError
                      ? Colors.red
                      : isSuccess
                          ? AppColors.grey3
                          : AppColors.black,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class CustomDatePickerField extends StatefulWidget {
  CustomDatePickerField({
    required this.onDateofBirthSet,
    super.key,
    this.label,
    this.descriptionText,
    this.isError,
    this.lastDate,
  });

  final String? label;
  final String? descriptionText;
  final bool? isError;
  final ValueChanged<String> onDateofBirthSet;
  final DateTime? lastDate;

  @override
  State<CustomDatePickerField> createState() => _CustomDatePickerFieldState();
}

class _CustomDatePickerFieldState extends State<CustomDatePickerField> {
  final _textController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      textController: _textController,
      prefixIcon: const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(child: Icon(Icons.calendar_month)),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.utc(1900),
          lastDate: widget.lastDate ?? DateTime.now(),
        );
        if (date != null) {
          _textController.text = _dateFormat.format(date);
          widget.onDateofBirthSet(_dateFormat.format(date));
        }
      },
      hint: 'DD-MM-YYYY',
      readOnly: true,
      descriptionText: widget.descriptionText,
      isError: widget.isError ?? false,
      // validation: (dob) {
      //   if (dob == null) {
      //     return 'Please pick a date';
      //   }
      //   return null;
      // },
    );
  }
}

class CustomPhoneTextField extends StatelessWidget {
  const CustomPhoneTextField({
    Key? key,
    this.controller,
    this.dialCode,
    this.contentPadding,
    this.onInputChanged,
    this.isRequired = false,
    this.label,
    this.initialPhone,
  }) : super(key: key);

  final TextEditingController? controller;

  final String? dialCode;
  final EdgeInsetsGeometry? contentPadding;
  final void Function(PhoneNumber)? onInputChanged;
  final bool isRequired;
  final String? label;
  final PhoneNumber? initialPhone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label!,
                style: AppTextStyle.body1.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.black,
                ),
              ),
              5.horizontalSpace,
              if (isRequired)
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
        ],
        PhoneFormField(
          initialValue: initialPhone ??
              PhoneNumber.parse(dialCode ?? '+27'), // or use the controller
          validator: PhoneValidator.compose(
            [
              PhoneValidator.required(context),
              PhoneValidator.validMobile(context),
            ],
          ),
          onChanged: onInputChanged,
          countryButtonStyle: const CountryButtonStyle(
            flagSize: 16,
          ),
          style: AppTextStyle.body1.copyWith(
            color: AppColors.grey900,
            fontWeight: FontWeight.w400,
          ),

          decoration: InputDecoration(
            hintText: '000 000 0000',
            hintStyle: AppTextStyle.body1.copyWith(
              color: AppColors.grey2,
            ),
            alignLabelWithHint: true,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14).dg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.grey2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.contentColorRed),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.grey2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.grey2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomPlaceSearchField extends StatefulWidget {
  const CustomPlaceSearchField({
    Key? key,
    this.label = '',
    this.hintText = '',
    required this.onSelected,
    this.isError = false,
    this.descriptionText,
    this.readOnly = false,
    this.initialPlace,
  }) : super(key: key);

  final String label;
  final String hintText;
  final void Function(GeoPlace?) onSelected;
  final bool isError;
  final String? descriptionText;
  final GeoPlace? initialPlace;
  final bool readOnly;

  @override
  State<CustomPlaceSearchField> createState() => _CustomPlaceSearchFieldState();
}

class _CustomPlaceSearchFieldState extends State<CustomPlaceSearchField> {
  GeoPlace? _geoPlace;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _geoPlace = widget.initialPlace;
  }

  void _selectedAddress(GeoPlace place) {
    setState(() {
      _geoPlace = place;
      widget.onSelected.call(_geoPlace);
    });
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
        if (_geoPlace != null)
          Material(
            child: ListTile(
              title: AppText(text: _geoPlace!.address),
              tileColor: AppColors.grey5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.grey1),
              ),
              trailing: CloseButton(
                onPressed: () {
                  if (widget.readOnly) return;
                  setState(() {
                    _geoPlace = null;
                    widget.onSelected.call(_geoPlace);
                  });
                },
              ),
            ),
          )
        else
          DropDownSearchField<GeoPlace>(
            displayAllSuggestionWhenTap: true,
            isMultiSelectDropdown: false,
            textFieldConfiguration: TextFieldConfiguration(
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                _selectedAddress(GeoPlace(address: value, lat: 0, lng: 0));
              },
              decoration:
                  AppColors.inputDecoration.copyWith(hintText: widget.hintText),
            ),
            suggestionsCallback: (pattern) async {
              if (pattern.isEmpty) return [];
              return getIt<LocationService>().placeSearch(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                leading: const Icon(Iconsax.location),
                title: AppText(
                  text: suggestion.address,
                  fontSize: 12,
                ),
              );
            },
            hideOnEmpty: true,
            onSuggestionSelected: _selectedAddress,
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
