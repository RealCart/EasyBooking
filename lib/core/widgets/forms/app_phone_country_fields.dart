import 'package:flutter/material.dart';

import 'package:easy_booking/core/widgets/forms/app_text_field.dart';

class AppPhoneCountryFields extends StatelessWidget {
  const AppPhoneCountryFields({
    required this.countryValue,
    required this.onCountryPressed,
    this.phoneController,
    this.countryLabel = 'Country',
    this.phoneLabel = 'Phone number',
    this.phoneHint,
    this.phoneErrorText,
    this.onPhoneChanged,
    this.enabled = true,
    super.key,
  });

  final String countryValue;
  final VoidCallback? onCountryPressed;
  final TextEditingController? phoneController;
  final String countryLabel;
  final String phoneLabel;
  final String? phoneHint;
  final String? phoneErrorText;
  final ValueChanged<String>? onPhoneChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Widget countryField = AppTextField(
      key: ValueKey<String>(countryValue),
      initialValue: countryValue,
      label: countryLabel,
      readOnly: true,
      enabled: enabled,
      onTap: enabled ? onCountryPressed : null,
      trailing: const Icon(Icons.keyboard_arrow_down, size: 20),
    );
    final Widget phoneField = AppTextField(
      controller: phoneController,
      label: phoneLabel,
      hint: phoneHint,
      errorText: phoneErrorText,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.telephoneNumber],
      onChanged: onPhoneChanged,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              countryField,
              const SizedBox(height: 12),
              phoneField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 2, child: countryField),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: phoneField),
          ],
        );
      },
    );
  }
}
