import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';

/// One notification: a toned badge, the title with its [timeLabel], the
/// body, and an unread dot. A booking conflict is highlighted and offers
/// «Разрешить конфликт» through [onAction].
final class NotificationRow extends StatelessWidget {
  const NotificationRow({
    required this.notification,
    required this.timeLabel,
    required this.onTap,
    this.onAction,
    this.showDivider = true,
    super.key,
  });

  static const double _badgeSize = 40;
  static const double _dotSize = 7;

  final NotificationEntity notification;
  final String timeLabel;
  final VoidCallback onTap;

  /// The conflict action; ignored for other kinds.
  final VoidCallback? onAction;
  final bool showDivider;

  bool get _isHighlighted =>
      notification.kind == NotificationKind.bookingConflict;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onAction = this.onAction;

    return Semantics(
      button: true,
      label: notification.isRead ? null : 'Непрочитанное',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _isHighlighted ? AppColors.errorHighlight : null,
            border: _isHighlighted
                ? const Border.symmetric(
                    horizontal: BorderSide(
                      color: AppColors.errorHighlightBorder,
                    ),
                  )
                : showDivider
                ? const Border(bottom: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pageGutter,
              vertical: AppSpacing.large,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Badge(kind: notification.kind, size: _badgeSize),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTypography.action.copyWith(
                                height: 18 / 14,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.small),
                          Text(
                            timeLabel,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              height: 14 / 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(
                        notification.body,
                        style: AppTypography.compactBody.copyWith(
                          height: 19 / 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      if (_isHighlighted && onAction != null) ...<Widget>[
                        const SizedBox(height: 6),
                        AppTextButton.underlined(
                          label: 'Разрешить конфликт',
                          onPressed: onAction,
                        ),
                      ],
                    ],
                  ),
                ),
                // A fixed lane, so titles and times align with or without
                // the dot.
                SizedBox(
                  width: AppSpacing.large,
                  child: notification.isRead
                      ? null
                      : Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            key: const ValueKey<String>('unread-dot'),
                            margin: const EdgeInsets.only(top: 5),
                            width: _dotSize,
                            height: _dotSize,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _Badge extends StatelessWidget {
  const _Badge({required this.kind, required this.size});

  final NotificationKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (kind) {
      NotificationKind.bookingConflict => (
        AppColors.errorSurface,
        AppColors.error,
      ),
      NotificationKind.syncFailed => (
        AppColors.warningSurface,
        AppColors.warning,
      ),
      NotificationKind.contractUnsigned => (AppColors.surface, AppColors.text),
      NotificationKind.arrivalSoon => (AppColors.infoSurface, AppColors.info),
      NotificationKind.contractSigned || NotificationKind.propertyPublished => (
        AppColors.successSurface,
        AppColors.success,
      ),
    };
    final ColorFilter tint = ColorFilter.mode(foreground, BlendMode.srcIn);
    final TextStyle glyphStyle = AppTypography.sectionTitle.copyWith(
      fontWeight: FontWeight.w700,
      color: foreground,
    );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: switch (kind) {
        NotificationKind.bookingConflict => Text('!', style: glyphStyle),
        NotificationKind.syncFailed => SvgPicture.asset(
          AppAssets.icons.refresh,
          width: AppSizes.iconInline,
          height: AppSizes.iconInline,
          colorFilter: tint,
        ),
        NotificationKind.contractUnsigned => SvgPicture.asset(
          AppAssets.icons.documentTextSmall,
          width: AppSizes.iconInline,
          height: AppSizes.iconInline,
          colorFilter: tint,
        ),
        NotificationKind.arrivalSoon => Text(
          'IN',
          style: glyphStyle.copyWith(fontSize: 13, height: 16 / 13),
        ),
        NotificationKind.contractSigned ||
        NotificationKind.propertyPublished => SvgPicture.asset(
          AppAssets.icons.checkSmall,
          width: AppSizes.iconInline,
          height: AppSizes.iconInline,
          colorFilter: tint,
        ),
      },
    );
  }
}
