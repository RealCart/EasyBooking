import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/widgets/navigation/app_root_header.dart';

/// Temporary destination for a route whose feature screen is not built yet.
///
/// Replace the route's builder with the feature screen when it is ready.
final class RoutePlaceholderScreen extends StatelessWidget {
  const RoutePlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (canPop)
              AppDetailHeader(
                title: title,
                backSemanticLabel: 'Назад',
                onBack: () => context.pop(),
              )
            else
              AppRootHeader(title: title),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xLarge),
                  child: Text(
                    'Экран в разработке',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
