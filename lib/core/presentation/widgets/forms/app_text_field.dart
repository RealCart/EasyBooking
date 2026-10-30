import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppTextField extends StatefulWidget {
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
    this.inputFormatters,
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
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownedFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(_handleFocus);
      if (widget.focusNode != null) {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
      _focusNode.addListener(_handleFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;
    final Color borderColor = hasError
        ? AppColors.error
        : _focusNode.hasFocus
        ? AppColors.text
        : AppColors.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Opacity(
          opacity: widget.enabled ? 1 : 0.4,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(
                color: borderColor,
                width: _focusNode.hasFocus && !hasError ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
            child: Row(
              children: <Widget>[
                if (widget.leading != null) ...<Widget>[
                  widget.leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (widget.label case final String label) ...<Widget>[
                        ExcludeSemantics(
                          child: Text(
                            label,
                            style:
                                const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  height: 18 / 12,
                                ).copyWith(
                                  color: hasError
                                      ? AppColors.error
                                      : AppColors.secondaryText,
                                ),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Semantics(
                        label: <String>[
                          if (widget.label case final String label) label,
                          if (widget.errorText case final String error) error,
                        ].join(', '),
                        child: TextFormField(
                          controller: widget.controller,
                          initialValue: widget.initialValue,
                          focusNode: _focusNode,
                          onChanged: widget.onChanged,
                          onFieldSubmitted: widget.onSubmitted,
                          onTap: widget.onTap,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          obscureText: widget.obscureText,
                          enabled: widget.enabled,
                          readOnly: widget.readOnly,
                          autocorrect: widget.autocorrect,
                          maxLines: widget.maxLines,
                          minLines: widget.minLines,
                          autofillHints: widget.autofillHints,
                          inputFormatters: widget.inputFormatters,
                          cursorColor: AppColors.accent,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.text,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            hintStyle: AppTypography.bodyLarge.copyWith(
                              color: AppColors.secondaryText,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.trailing != null) ...<Widget>[
                  const SizedBox(width: 8),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
        if (widget.errorText case final String errorText) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              height: 18 / 12,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
