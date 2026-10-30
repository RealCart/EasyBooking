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
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _setController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _setController(widget.controller);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  // Insets for a 1 px border. A thicker focus border takes its extra width
  // from the padding, so the pill keeps its 66 px height in every state.
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 12,
  );
  static const EdgeInsets _paddingWithClear = EdgeInsets.fromLTRB(
    18,
    10,
    10,
    10,
  );

  @override
  Widget build(BuildContext context) {
    final bool hasQuery = _controller.text.isNotEmpty;
    final double borderWidth = _hasFocus ? 2 : 1;
    final EdgeInsets padding =
        (hasQuery ? _paddingWithClear : _padding) -
        EdgeInsets.all(borderWidth - 1);
    final TextStyle hintStyle = AppTypography.body.copyWith(
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    );
    final String? subtitle = hasQuery ? null : widget.subtitle;

    return Focus(
      onFocusChange: (bool hasFocus) => setState(() => _hasFocus = hasFocus),
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.4,
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(
              color: _hasFocus ? AppColors.text : AppColors.border,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(AppAssets.icons.search, width: 20, height: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _controller,
                      enabled: widget.enabled,
                      textInputAction: TextInputAction.search,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      // The empty line matches the hint so the pill keeps
                      // its height; typed text uses the 16 px body.
                      style: hasQuery
                          ? AppTypography.bodyLarge.copyWith(
                              color: AppColors.text,
                            )
                          : hintStyle,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: hintStyle,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
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
                ),
              ),
              if (hasQuery)
                AppIconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.secondaryText,
                  ),
                  semanticLabel: widget.clearSemanticLabel,
                  onPressed: widget.enabled ? _clear : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setController(TextEditingController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? TextEditingController();
    _controller.addListener(_handleControllerChanged);
  }
}
