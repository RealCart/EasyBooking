import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/validators.dart';

/// SMS code input drawn as one box per digit.
///
/// A single invisible [TextField] covers the boxes and receives the input,
/// so SMS autofill (`oneTimeCode`) and paste work as in a normal field. The
/// owner of [controller] and [focusNode] (the screen) disposes them.
final class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.validator,
    this.errorText,
    this.semanticLabel = 'Код из SMS',
    this.autofocus = false,
    this.readOnly = false,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  /// Validates the code inside an enclosing `Form`. Its message takes
  /// precedence over [errorText].
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final String semanticLabel;
  final bool autofocus;

  /// Keeps focus but ignores input, for example while the code is checked.
  final bool readOnly;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

final class _OtpCodeFieldState extends State<OtpCodeField> {
  static const int _length = Validators.otpLength;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator == null
          ? null
          : (_) => widget.validator?.call(widget.controller.text),
      builder: _buildField,
    );
  }

  Widget _buildField(FormFieldState<String> field) {
    final String? errorText = field.errorText ?? widget.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          children: <Widget>[
            ExcludeSemantics(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (_, TextEditingValue value, _) {
                  final String code = value.text;
                  return Row(
                    spacing: AppSpacing.small,
                    children: <Widget>[
                      for (int index = 0; index < _length; index++)
                        Expanded(
                          child: _OtpBox(
                            digit: index < code.length ? code[index] : '',
                            isActive:
                                widget.focusNode.hasFocus && index == code.length,
                            hasError: errorText != null,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Semantics(
                label: <String>[
                  '${widget.semanticLabel}, $_length цифр',
                  ?errorText,
                ].join(', '),
                child: TextSelectionTheme(
                  // The text is invisible, so its selection must be too.
                  data: const TextSelectionThemeData(
                    selectionColor: Colors.transparent,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    autofocus: widget.autofocus,
                    readOnly: widget.readOnly,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.oneTimeCode],
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_length),
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    showCursor: false,
                    style: const TextStyle(color: Colors.transparent),
                    decoration: const InputDecoration.collapsed(hintText: null),
                    onChanged: (String code) {
                      field.didChange(code);
                      widget.onChanged(code);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.small),
          Text(
            errorText,
            style: AppTypography.compactBody.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

final class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  static const double _minHeight = 64;

  final String digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = hasError
        ? AppColors.error
        : isActive
        ? AppColors.text
        : AppColors.border;

    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: borderColor),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.field)),
      ),
      child: Text(
        digit,
        style: AppTypography.compactScreenTitle.copyWith(
          letterSpacing: 0,
          color: AppColors.text,
        ),
      ),
    );
  }
}
