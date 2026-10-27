import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/widgets/forms/app_text_field.dart';

enum AppValueFieldType { money, time }

class AppValueField extends StatelessWidget {
  const AppValueField({
    required this.type,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.errorText,
    this.currencySymbol = r'$',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    super.key,
  }) : assert(controller == null || initialValue == null);

  final AppValueFieldType type;
  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? errorText;
  final String currencySymbol;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final bool readOnly;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Widget leading = switch (type) {
      AppValueFieldType.money => Center(
        widthFactor: 1,
        child: Text(
          currencySymbol,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 16),
        ),
      ),
      AppValueFieldType.time => const Icon(
        Icons.access_time,
        color: AppColors.secondaryText,
        size: 20,
      ),
    };

    return AppTextField(
      controller: controller,
      initialValue: initialValue,
      label: label,
      hint: hint,
      errorText: errorText,
      leading: leading,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: type == AppValueFieldType.money
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.datetime,
      textInputAction: TextInputAction.done,
    );
  }
}
