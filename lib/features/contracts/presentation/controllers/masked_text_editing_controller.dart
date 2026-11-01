import 'package:flutter/material.dart';

import 'package:easy_booking/features/contracts/presentation/widgets/contract_labels.dart';

/// A text controller that can draw its text masked, except for the last
/// [visibleTail] characters (`•••••••••214`), while [text] keeps the real
/// value for validation and submit.
///
/// The masked text has the same length as [text], so the caret and the
/// selection stay in place while the user edits a masked value.
final class MaskedTextEditingController extends TextEditingController {
  MaskedTextEditingController({required this.visibleTail});

  final int visibleTail;

  bool _isMasked = true;

  bool get isMasked => _isMasked;

  set isMasked(bool value) {
    if (_isMasked == value) {
      return;
    }
    _isMasked = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    // While an IME composes a word the real text is shown, so the
    // composing underline matches what is typed.
    final bool isComposing =
        withComposing &&
        value.isComposingRangeValid &&
        !value.composing.isCollapsed;
    if (!_isMasked || isComposing) {
      return super.buildTextSpan(
        context: context,
        withComposing: withComposing,
        style: style,
      );
    }
    return TextSpan(
      style: style,
      text: ContractMask.tail(text, visibleTail: visibleTail),
    );
  }
}
