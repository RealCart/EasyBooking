import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// A text field drawn as a 72 px box with the label above the input.
///
/// The box is the [TextFormField]'s own decoration, so a tap anywhere on it
/// focuses the input, and [validator] runs as part of the enclosing `Form`.
/// Its message is shown below the box and takes precedence over [errorText].
/// A tap outside the field unfocuses it.
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
    this.validator,
    super.key,
  }) : assert(controller == null || initialValue == null),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0);

  // The decorator draws a floating label at 0.75 of its style, so a 16 px
  // style shows the 12 px / 18 px label of the design.
  static const TextStyle _labelStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 18 / 12,
  );

  // The input starts `4 + 0.75 × labelStyle.fontSize` below the top padding
  // when the label floats. This size gives 20 px: the 18 px label and a 2 px
  // gap. The inline style is otherwise never shown.
  static const double _labelSlotHeight = 20;
  static const TextStyle _labelSlotStyle = TextStyle(
    fontSize: (_labelSlotHeight - 4) / 0.75,
  );

  // A filled, non-outline decoration adds this gap on both sides of the
  // input, so the paddings below are 4 px narrower than the design.
  static const double _inputGap = 4;

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

  /// Runs on `FormState.validate()` of the enclosing `Form` with the current
  /// text. Its message is shown like [errorText] and takes precedence.
  final FormFieldValidator<String>? validator;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  /// Used when the owner passes no [AppTextField.focusNode], so an outside
  /// tap can still unfocus this field.
  late FocusNode? _fallbackFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _fallbackFocusNode!;

  @override
  void initState() {
    super.initState();
    _fallbackFocusNode = widget.focusNode == null ? FocusNode() : null;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode == null) {
      _fallbackFocusNode ??= FocusNode();
    } else {
      _fallbackFocusNode?.dispose();
      _fallbackFocusNode = null;
    }
  }

  @override
  void dispose() {
    _fallbackFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? leading = widget.leading;
    final Widget? trailing = widget.trailing;
    final String? errorText = widget.errorText;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.initialValue,
        focusNode: _focusNode,
        validator: widget.validator,
        errorBuilder: (BuildContext context, String errorText) =>
            _FieldError(errorText: errorText),
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
        // Only this field's node: another field tapped meanwhile keeps focus.
        onTapUpOutside: (_) => _focusNode.unfocus(),
        style: AppTypography.bodyLarge.copyWith(color: AppColors.text),
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: AppTextField._labelSlotStyle,
          floatingLabelStyle: WidgetStateTextStyle.resolveWith(
            (Set<WidgetState> states) => AppTextField._labelStyle.copyWith(
              color: states.contains(WidgetState.error)
                  ? AppColors.error
                  : AppColors.secondaryText,
            ),
          ),
          hintText: widget.hint,
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.secondaryText,
          ),
          error: errorText == null ? null : _FieldError(errorText: errorText),
          prefixIcon: leading == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 16,
                    end: 12 - AppTextField._inputGap,
                  ),
                  child: leading,
                ),
          prefixIconConstraints: const BoxConstraints(),
          prefixIconColor: AppColors.text,
          suffixIcon: trailing == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 8 - AppTextField._inputGap,
                    end: 16,
                  ),
                  child: trailing,
                ),
          suffixIconConstraints: const BoxConstraints(),
          suffixIconColor: AppColors.text,
          constraints: const BoxConstraints(minHeight: 72),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16 - AppTextField._inputGap,
            vertical: 12,
          ),
          filled: true,
          fillColor: AppColors.background,
          hoverColor: Colors.transparent,
          border: const _AppFieldBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: const _AppFieldBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
          disabledBorder: const _AppFieldBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: const _AppFieldBorder(
            borderSide: BorderSide(color: AppColors.text, width: 2),
          ),
          errorBorder: const _AppFieldBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: const _AppFieldBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

/// The validator or external error under the box.
final class _FieldError extends StatelessWidget {
  const _FieldError({required this.errorText});

  static const TextStyle _style = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 18 / 12,
    color: AppColors.error,
  );

  final String errorText;

  @override
  Widget build(BuildContext context) {
    // With the decorator's 4 px gap, 6 px between the box and the message.
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(errorText, style: _style),
    );
  }
}

/// A rounded box border drawn inside the field's bounds.
///
/// Unlike `OutlineInputBorder` it is not an outline border for the
/// decorator, so the floating label sits inside the box under the top
/// padding instead of being notched into the border line.
final class _AppFieldBorder extends InputBorder {
  const _AppFieldBorder({super.borderSide});

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadii.field),
  );

  @override
  bool get isOutline => false;

  @override
  _AppFieldBorder copyWith({BorderSide? borderSide}) {
    return _AppFieldBorder(borderSide: borderSide ?? this.borderSide);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  _AppFieldBorder scale(double t) {
    return _AppFieldBorder(borderSide: borderSide.scale(t));
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is _AppFieldBorder) {
      return _AppFieldBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is _AppFieldBorder) {
      return _AppFieldBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(_radius.toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(_radius.toRRect(rect));
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    canvas.drawRRect(
      _radius.toRRect(rect).deflate(borderSide.width / 2),
      borderSide.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _AppFieldBorder && other.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}
