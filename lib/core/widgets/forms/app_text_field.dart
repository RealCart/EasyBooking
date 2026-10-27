import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autocorrect = true,
    this.maxLines = 1,
    this.minLines,
    this.autofillHints,
    super.key,
  }) : assert(controller == null || initialValue == null),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0);

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final Widget? leading;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final GestureTapCallback? onTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autocorrect;
  final int? maxLines;
  final int? minLines;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autocorrect: autocorrect,
      maxLines: maxLines,
      minLines: minLines,
      autofillHints: autofillHints,
      cursorColor: AppColors.accent,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: leading,
        suffixIcon: trailing,
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surface,
        labelStyle: AppTypography.body.copyWith(color: AppColors.secondaryText),
        floatingLabelStyle: AppTypography.body.copyWith(
          color: errorText == null ? AppColors.accent : AppColors.error,
        ),
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.secondaryText,
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: _border(AppColors.border),
        disabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.accent, width: 2),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, width: 2),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
