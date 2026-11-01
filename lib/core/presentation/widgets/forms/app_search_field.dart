import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    this.controller,
    this.hint = 'Search',
    this.subtitle,
    this.onChanged,
    this.onSubmitted,
    this.clearSemanticLabel = 'Clear search',
    this.enabled = true,
    super.key,
  });

  final TextEditingController? controller;
  final String hint;
  final String? subtitle;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String clearSemanticLabel;
  final bool enabled;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late bool _ownsController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'AppSearchField');
    _setController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    if (_ownsController) {
      _controller.dispose();
    }
    _setController(widget.controller);
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  // The decorator keeps this gap between an icon and the input.
  static const double _iconGap = 4;

  // The input's end inset without a query; the clear button replaces it.
  static const double _endInset = 19 - _iconGap;

  static const OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(999)),
    borderSide: BorderSide(color: AppColors.border),
  );

  @override
  Widget build(BuildContext context) {
    // The pill, the icons and the hint are the field's own decoration, so a
    // tap anywhere on the pill focuses the input. Only the hint and the
    // clear button listen to the text, so typing does not rebuild the field.
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        // Only this field's node: another field tapped meanwhile keeps focus.
        onTapUpOutside: (_) => _focusNode.unfocus(),
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        cursorColor: AppColors.accent,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.text),
        decoration: InputDecoration(
          hint: _SearchHint(
            controller: _controller,
            hint: widget.hint,
            subtitle: widget.subtitle,
          ),
          // Without a query the field is only as tall as its input line;
          // the 66 px minimum keeps the pill's height.
          maintainHintSize: false,
          isDense: true,
          constraints: const BoxConstraints(minHeight: 66),
          // The end inset comes from the suffix: icons sit at the edges and
          // bring their own padding.
          contentPadding: const EdgeInsetsDirectional.only(
            top: 5.0,
            bottom: 5.0,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 19,
              end: 12 - _iconGap,
            ),
            child: SvgPicture.asset(
              AppAssets.icons.search,
              width: 20,
              height: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: _ClearButton(
            controller: _controller,
            semanticLabel: widget.clearSemanticLabel,
            onPressed: widget.enabled ? _clear : null,
          ),
          suffixIconConstraints: const BoxConstraints(),
          filled: false,
          hoverColor: Colors.transparent,
          border: _border,
          enabledBorder: _border,
          disabledBorder: _border,
          focusedBorder: _border.copyWith(
            borderSide: const BorderSide(color: AppColors.text, width: 2),
          ),
        ),
      ),
    );
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  void _setController(TextEditingController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? TextEditingController();
  }
}

/// The hint and its optional subtitle, removed as soon as there is a query so
/// the subtitle does not fade out late.
final class _SearchHint extends StatelessWidget {
  const _SearchHint({
    required this.controller,
    required this.hint,
    required this.subtitle,
  });

  final TextEditingController controller;
  final String hint;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, _) {
        if (value.text.isNotEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              hint,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The clear button, shown only with a query. Without one it keeps the
/// input's end inset, since the field always has a suffix.
final class _ClearButton extends StatelessWidget {
  const _ClearButton({
    required this.controller,
    required this.semanticLabel,
    required this.onPressed,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? button) {
        if (value.text.isEmpty) {
          return const SizedBox(width: _AppSearchFieldState._endInset);
        }
        return button!;
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 11),
        child: SizedBox.square(
          dimension: 20.0,
          child: AppIconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.secondaryText,
            ),
            semanticLabel: semanticLabel,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
