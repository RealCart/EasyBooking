import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';

/// An underlined text action («Открыть», «Заменить», «Показать») with a
/// touch target of at least 44 × 44 around the text.
final class ContractTextAction extends StatelessWidget {
  const ContractTextAction({
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.isMuted = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Announced instead of [label] when the label alone is ambiguous.
  final String? semanticLabel;

  /// Draws the label without the underline in the secondary text color.
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.touchTarget,
            minHeight: AppSizes.touchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: isMuted
                ? AppTextButton.muted(label: label)
                : AppTextButton.underlined(label: label),
          ),
        ),
      ),
    );
  }
}
