import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppAccountIdentity extends StatelessWidget {
  const AppAccountIdentity({
    required this.name,
    required this.details,
    required this.avatarUrl,
    super.key,
  });
  final String name;
  final String details;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClipOval(
          child: Image.network(
            avatarUrl,
            width: 72.0,
            height: 72.0,
            color: AppColors.surface,
            fit: .cover,
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
              const AppTextButton.underlined(label: 'Edit profile'),
            ],
          ),
        ),
      ],
    );
  }

  // String _initialsFrom(String value) {
  //   final List<String> parts = value
  //       .trim()
  //       .split(RegExp(r'\s+'))
  //       .where((String part) => part.isNotEmpty)
  //       .toList();
  //   if (parts.isEmpty) return '';
  //   if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  //   return '${parts.first.characters.first}${parts.last.characters.first}'
  //       .toUpperCase();
  // }
}
