import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
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
    final VoidCallback? onSelectCountry = enabled ? onCountryPressed : null;
    final Widget countryField = Semantics(
      button: true,
      enabled: onSelectCountry != null,
      label: '$countryLabel, $countryValue',
      onTap: onSelectCountry,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: onSelectCountry == null ? 0.4 : 1,
          child: GestureDetector(
            onTap: onSelectCountry,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadii.field),
                ),
                border: .all(color: AppColors.border),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 13,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        countryLabel,
                        style: AppTypography.caption.copyWith(
                          height: 18 / 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      Text(
                        countryValue,
                        style: AppTypography.body.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
        if (constraints.maxWidth < 320) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Expanded(flex: 71, child: countryField),
            const SizedBox(width: 12),
            Expanded(flex: 123, child: phoneField),
          ],
        );
      },
    );
  }
}
