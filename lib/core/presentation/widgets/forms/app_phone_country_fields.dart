import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';

enum AppPhoneCountryLayout {
  /// Side by side, stacking only below 320 px of width.
  adaptive,

  /// Country above phone, both full width.
  stacked,
}

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
    this.phoneInputFormatters,
    this.layout = AppPhoneCountryLayout.adaptive,
    this.isCountryReadOnly = false,
    this.enabled = true,
    super.key,
  });

  static const double _fieldMinHeight = 72;
  static const double _adaptiveBreakpoint = 320;

  final String countryValue;

  /// Opens a country selector. Without a callback the country looks and is
  /// announced as disabled, unless [isCountryReadOnly] is set.
  final VoidCallback? onCountryPressed;
  final TextEditingController? phoneController;
  final String countryLabel;
  final String phoneLabel;
  final String? phoneHint;
  final String? phoneErrorText;
  final ValueChanged<String>? onPhoneChanged;
  final List<TextInputFormatter>? phoneInputFormatters;
  final AppPhoneCountryLayout layout;

  /// Shows the country as a fixed value: not tappable, not dimmed, and
  /// announced as read-only. [onCountryPressed] is ignored.
  final bool isCountryReadOnly;

  /// Dims and disables both fields.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool isStacked = layout == AppPhoneCountryLayout.stacked;
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
      inputFormatters: phoneInputFormatters,
    );

    if (isStacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.large,
        children: <Widget>[_buildCountryField(isStacked: true), phoneField],
      );
    }

    final Widget countryField = _buildCountryField(isStacked: false);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < _adaptiveBreakpoint) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              countryField,
              const SizedBox(height: AppSpacing.medium),
              phoneField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 71, child: countryField),
            const SizedBox(width: AppSpacing.medium),
            Expanded(flex: 123, child: phoneField),
          ],
        );
      },
    );
  }

  Widget _buildCountryField({required bool isStacked}) {
    final VoidCallback? onSelectCountry = enabled && !isCountryReadOnly
        ? onCountryPressed
        : null;
    final bool isDimmed = isCountryReadOnly
        ? !enabled
        : onSelectCountry == null;

    final Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.field)),
        border: .all(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _fieldMinHeight),
        // One pixel more than the Paper padding, which includes the border.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
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
                // Full-width fields use the same value size as text fields.
                style:
                    (isStacked ? AppTypography.bodyLarge : AppTypography.body)
                        .copyWith(color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );

    if (isCountryReadOnly) {
      return Semantics(
        container: true,
        readOnly: true,
        enabled: enabled,
        label: '$countryLabel, $countryValue',
        child: ExcludeSemantics(
          child: Opacity(opacity: isDimmed ? 0.4 : 1, child: box),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: onSelectCountry != null,
      label: '$countryLabel, $countryValue',
      onTap: onSelectCountry,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: isDimmed ? 0.4 : 1,
          child: GestureDetector(onTap: onSelectCountry, child: box),
        ),
      ),
    );
  }
}
