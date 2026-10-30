import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_primary_button.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';

final class AppStickyActionBar extends StatelessWidget {
  const AppStickyActionBar.rate({
    required String rate,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    String? rateCaption,
    this.leading,
    this.showTopDivider = true,
    super.key,
  }) : title = rate,
       subtitle = rateCaption,
       _isFlow = false,
       secondaryLabel = null,
       onSecondaryPressed = null;

  const AppStickyActionBar.flow({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    String? supportingText,
    this.showTopDivider = true,
    super.key,
  }) : assert(
         (secondaryLabel == null && onSecondaryPressed == null) ||
             (secondaryLabel != null && onSecondaryPressed != null),
       ),
       title = supportingText,
       subtitle = null,
       _isFlow = true,
       leading = null;

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final bool showTopDivider;
  final bool _isFlow;

  @override
  Widget build(BuildContext context) {
    if (_isFlow) {
      return AppFlowFooter(
        primaryLabel: primaryLabel,
        onPrimaryPressed: onPrimaryPressed,
        secondaryLabel: secondaryLabel,
        onSecondaryPressed: onSecondaryPressed,
        message: title,
        showTopDivider: showTopDivider,
      );
    }
    return Material(
      color: AppColors.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showTopDivider
              ? const Border(top: BorderSide(color: AppColors.border))
              : null,
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: AppSpacing.small),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xLarge,
              AppSpacing.large,
              AppSpacing.xLarge,
              AppSpacing.xSmall,
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool shouldStack = constraints.maxWidth < 320;
                final Widget? content = _buildContent();
                final Widget actions = AppPrimaryButton.compact(
                  label: primaryLabel,
                  onPressed: onPrimaryPressed,
                );
                if (content == null) {
                  return actions;
                }
                if (shouldStack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      content,
                      const SizedBox(height: AppSpacing.medium),
                      actions,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: content),
                    const SizedBox(width: AppSpacing.large),
                    SizedBox(width: 156, child: actions),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildContent() {
    final String? title = this.title;
    if (title == null) {
      return null;
    }
    final Widget? leading = this.leading;
    final String? subtitle = this.subtitle;
    final Widget text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sectionTitle.copyWith(color: AppColors.text),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
      ],
    );
    if (leading == null) {
      return text;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        leading,
        const SizedBox(width: AppSpacing.medium),
        Flexible(child: text),
      ],
    );
  }
}
