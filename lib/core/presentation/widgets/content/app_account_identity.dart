import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';

/// Avatar, name, details, and an optional underlined action such as
/// «Редактировать профиль». Without [avatarUrl], or when it fails to load,
/// the avatar shows the initials of [name].
class AppAccountIdentity extends StatelessWidget {
  const AppAccountIdentity({
    required this.name,
    required this.details,
    this.avatarUrl,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null && onAction == null) ||
             (actionLabel != null && onAction != null),
       );

  static const double _avatarSize = 72;

  final String name;
  final String details;
  final String? avatarUrl;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = this.avatarUrl;
    final String? actionLabel = this.actionLabel;
    final Widget initials = _Initials(initials: _initialsFrom(name));

    return Row(
      children: <Widget>[
        SizedBox.square(
          dimension: _avatarSize,
          child: avatarUrl == null
              ? initials
              : ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: _avatarSize,
                    height: _avatarSize,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => initials,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: <Widget>[
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.text,
                ),
              ),
              Text(
                details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              if (actionLabel != null)
                AppTextButton.underlined(
                  label: actionLabel,
                  onPressed: onAction,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// `БН` for `Бексултан Нишанбек`: the first letters of the first and last
  /// words.
  static String _initialsFrom(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.sectionTitle.copyWith(
            fontSize: 22,
            height: 34 / 22,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}
