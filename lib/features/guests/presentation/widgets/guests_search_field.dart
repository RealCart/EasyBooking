import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';

/// The compact search box of «Гости и договоры». The decoration draws the
/// whole box, so a tap anywhere on it focuses the input. A clear button
/// appears with a query.
final class GuestsSearchField extends StatelessWidget {
  const GuestsSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.hint = 'Имя, телефон или объект',
    super.key,
  });

  static const double _height = 50;
  static const double _iconSize = 19;

  // The decorator keeps this gap between an icon and the input.
  static const double _iconGap = 4;

  // The input's end inset without a query; the clear button replaces it.
  static const double _endInset = AppSpacing.large - _iconGap;

  static const OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
    borderSide: BorderSide(color: AppColors.border),
  );

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    // Only the clear button listens to the text, so typing does not rebuild
    // the field.
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onTapUpOutside: (_) => focusNode.unfocus(),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: AppColors.accent,
      style: AppTypography.body.copyWith(color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body.copyWith(
          height: 18 / 14,
          color: AppColors.secondaryText,
        ),
        isDense: true,
        constraints: const BoxConstraints(minHeight: _height),
        // The end inset comes from the suffix.
        contentPadding: const EdgeInsetsDirectional.only(top: 8.0, bottom: 8.0),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.large,
            end: 10 - _iconGap,
          ),
          child: SvgPicture.asset(
            AppAssets.icons.searchMuted,
            width: _iconSize,
            height: _iconSize,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: _ClearButton(controller: controller, onPressed: _clear),
        suffixIconConstraints: const BoxConstraints(),
        filled: false,
        hoverColor: Colors.transparent,
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border.copyWith(
          borderSide: const BorderSide(color: AppColors.text, width: 2),
        ),
      ),
    );
  }

  void _clear() {
    controller.clear();
    onChanged('');
  }
}

/// The clear button, shown only with a query. Without one it keeps the
/// input's end inset, since the field always has a suffix.
final class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.controller, required this.onPressed});

  final TextEditingController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? button) {
        if (value.text.isEmpty) {
          return const SizedBox(width: GuestsSearchField._endInset);
        }
        return button!;
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xSmall),
        child: SizedBox.square(
          dimension: 20.0,
          child: AppIconButton(
            icon: const Icon(
              Icons.close,
              size: 20.0,
              color: AppColors.secondaryText,
            ),
            semanticLabel: 'Очистить поиск',
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
