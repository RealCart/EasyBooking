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
final class OtpCodeField extends StatelessWidget {
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

  static const int _length = Validators.otpLength;

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
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator == null
          ? null
          : (_) => validator?.call(controller.text),
      builder: (FormFieldState<String> field) => _OtpInput(
        controller: controller,
        focusNode: focusNode,
        errorText: field.errorText ?? errorText,
        semanticLabel: semanticLabel,
        autofocus: autofocus,
        readOnly: readOnly,
        onChanged: (String code) {
          field.didChange(code);
          onChanged(code);
        },
      ),
    );
  }
}

/// The digit boxes under the invisible input, and the error below them.
final class _OtpInput extends StatelessWidget {
  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.semanticLabel,
    required this.autofocus,
    required this.readOnly,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final String semanticLabel;
  final bool autofocus;
  final bool readOnly;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final String? errorText = this.errorText;
    const int length = OtpCodeField._length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          children: <Widget>[
            ExcludeSemantics(
              child: _OtpBoxes(
                controller: controller,
                focusNode: focusNode,
                hasError: errorText != null,
              ),
            ),
            Positioned.fill(
              child: Semantics(
                label: <String>[
                  '$semanticLabel, $length цифр',
                  ?errorText,
                ].join(', '),
                child: TextSelectionTheme(
                  // The text is invisible, so its selection must be too.
                  data: const TextSelectionThemeData(
                    selectionColor: Colors.transparent,
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    readOnly: readOnly,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.oneTimeCode],
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(length),
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    showCursor: false,
                    style: const TextStyle(color: Colors.transparent),
                    decoration: const InputDecoration.collapsed(hintText: null),
                    onChanged: onChanged,
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

/// One box per digit. Only this row rebuilds on typing and on focus
/// changes, which move the active box.
final class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[controller, focusNode]),
      builder: (BuildContext context, _) {
        final String code = controller.text;
        return Row(
          spacing: AppSpacing.small,
          children: <Widget>[
            for (int index = 0; index < OtpCodeField._length; index++)
              Expanded(
                child: _OtpBox(
                  digit: index < code.length ? code[index] : '',
                  isActive: focusNode.hasFocus && index == code.length,
                  hasError: hasError,
                ),
              ),
          ],
        );
      },
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
