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
/// so SMS autofill (`oneTimeCode`) and paste work as in a normal field.
final class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    required this.code,
    required this.onChanged,
    this.errorText,
    this.semanticLabel = 'Код из SMS',
    this.autofocus = false,
    this.readOnly = false,
    super.key,
  });

  /// Digits entered so far. A change from outside (for example, clearing
  /// the code after a failure) replaces the text in the field.
  final String code;
  final ValueChanged<String> onChanged;
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

  late final TextEditingController _controller = TextEditingController(
    text: widget.code,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != oldWidget.code && widget.code != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final String? errorText = widget.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          children: <Widget>[
            ExcludeSemantics(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
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
                                _focusNode.hasFocus && index == code.length,
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
                    controller: _controller,
                    focusNode: _focusNode,
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
                    onChanged: widget.onChanged,
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
