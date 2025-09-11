import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // if (label != null)
        //   Column(
        //     mainAxisSize: MainAxisSize.min,
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         label!,
        //         style: AppTextStyle.body1.copyWith(
        //           fontSize: 12.sp,
        //           color: AppColors.black,
        //         ),
        //       ),
        //       5.verticalSpace,
        //     ],
        //   ),
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
            fontSize: 14.sp,
            color: AppColors.grey900,
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
            // suffixIconConstraints:
            //     const BoxConstraints(maxHeight: 30, maxWidth: 30),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12).dg,
              child: suffixIcon,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,

            hintText: hint,
            hintStyle: AppTextStyle.body1.copyWith(
              fontSize: 12.sp,
              color: AppColors.grey500,
            ),
            // labelText: label,
            label: label != null
                ? Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: Text(
                      label!,
                      style: AppTextStyle.body1.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.black,
                      ),
                    ),
                  )
                : null,
            labelStyle: AppTextStyle.body1.copyWith(
              fontSize: 10.sp,
              color: AppColors.grey500,
            ),
            alignLabelWithHint: true,

            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10).dg,
            // floatingLabelBehavior: FloatingLabelBehavior.always,
            fillColor: AppColors.grey300,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.contentColorRed),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: const BorderSide(color: AppColors.grey2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.grey2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10).r,
              borderSide: BorderSide.none,
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
          )
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
  const CustomPhoneTextField(
      {super.key,
      this.controller,
      this.suffixWidget,
      this.suffixIcon,
      this.dialCode,
      this.contentPadding,
      this.onInputChanged});

  final TextEditingController? controller;
  final Widget? suffixWidget;
  final String? suffixIcon, dialCode;
  final EdgeInsetsGeometry? contentPadding;
  final void Function(PhoneNumber)? onInputChanged;

  @override
  Widget build(BuildContext context) {
    return InternationalPhoneNumberInput(
      onInputChanged: onInputChanged,
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        setSelectorButtonAsPrefixIcon: true,
      ),
      ignoreBlank: false,
      autoValidateMode: AutovalidateMode.disabled,
      selectorTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 12.sp,
      ),
      textFieldController: controller,
      formatInput: false,
      initialValue: PhoneNumber(
        isoCode: 'NG',
      ),
      keyboardType: TextInputType.number,
      textStyle: AppTextStyle.body1.copyWith(
        fontSize: 14.sp,
        color: AppColors.grey900,
        fontWeight: FontWeight.w400,
      ),
      inputDecoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: 'Enter your phone number',
        hintStyle: AppTextStyle.body1.copyWith(
          fontSize: 12.sp,
          color: AppColors.grey500,
        ),
        fillColor: AppColors.grey300,
        filled: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppTextStyle.body1.copyWith(
          fontSize: 10.sp,
          color: AppColors.grey500,
        ),
        alignLabelWithHint: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10).r,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10).r,
          borderSide: const BorderSide(color: AppColors.contentColorRed),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10).r,
          borderSide: const BorderSide(color: AppColors.grey2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.grey2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10).r,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10).r,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
