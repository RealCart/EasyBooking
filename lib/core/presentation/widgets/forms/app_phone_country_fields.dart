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
    this.phoneFocusNode,
    this.countryLabel = 'Country',
    this.phoneLabel = 'Phone number',
    this.phoneHint,
    this.phoneErrorText,
    this.onPhoneChanged,
    this.onPhoneSubmitted,
    this.phoneValidator,
    this.phoneInputFormatters,
    this.layout = AppPhoneCountryLayout.adaptive,
    this.isCountryReadOnly = false,
    this.enabled = true,
    super.key,
  });

  static const double _adaptiveBreakpoint = 320;

  final String countryValue;

  /// Opens a country selector. Without a callback the country looks and is
  /// announced as disabled, unless [isCountryReadOnly] is set.
  final VoidCallback? onCountryPressed;
  final TextEditingController? phoneController;
  final FocusNode? phoneFocusNode;
  final String countryLabel;
  final String phoneLabel;
  final String? phoneHint;
  final String? phoneErrorText;
  final ValueChanged<String>? onPhoneChanged;
  final ValueChanged<String>? onPhoneSubmitted;

  /// Validates the phone inside an enclosing `Form`.
  final FormFieldValidator<String>? phoneValidator;
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
      focusNode: phoneFocusNode,
      label: phoneLabel,
      hint: phoneHint,
      errorText: phoneErrorText,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.telephoneNumber],
      onChanged: onPhoneChanged,
      onSubmitted: onPhoneSubmitted,
      validator: phoneValidator,
      inputFormatters: phoneInputFormatters,
    );

    if (isStacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.large,
        children: <Widget>[
          _CountryField(
            label: countryLabel,
            value: countryValue,
            isStacked: true,
            isReadOnly: isCountryReadOnly,
            enabled: enabled,
            onPressed: onCountryPressed,
          ),
          phoneField,
        ],
      );
    }

    final Widget countryField = _CountryField(
      label: countryLabel,
      value: countryValue,
      isStacked: false,
      isReadOnly: isCountryReadOnly,
      enabled: enabled,
      onPressed: onCountryPressed,
    );
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
}

/// The country box: tappable, or a fixed value when [isReadOnly].
final class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.label,
    required this.value,
    required this.isStacked,
    required this.isReadOnly,
    required this.enabled,
    required this.onPressed,
  });

  static const double _minHeight = 72;

  final String label;
  final String value;

  /// Full width: the value uses the text field size.
  final bool isStacked;
  final bool isReadOnly;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onSelectCountry = enabled && !isReadOnly
        ? onPressed
        : null;
    final bool isDimmed = isReadOnly ? !enabled : onSelectCountry == null;

    final Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.field)),
        border: .all(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        // One pixel more than the Paper padding, which includes the border.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  height: 18 / 12,
                  color: AppColors.secondaryText,
                ),
              ),
              Text(
                value,
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

    if (isReadOnly) {
      return Semantics(
        container: true,
        readOnly: true,
        enabled: enabled,
        label: '$label, $value',
        child: ExcludeSemantics(
          child: Opacity(opacity: isDimmed ? 0.4 : 1, child: box),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: onSelectCountry != null,
      label: '$label, $value',
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
