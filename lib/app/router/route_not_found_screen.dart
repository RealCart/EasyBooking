import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/widgets/feedback/app_empty_state.dart';

/// Shown for unknown locations, for example an outdated deep link.
final class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xLarge),
            child: AppEmptyState(
              title: 'Страница не найдена',
              message: 'Ссылка устарела или указана с ошибкой.',
              actionLabel: 'На главную',
              onAction: () => context.goNamed(AppRoutes.today.name),
            ),
          ),
        ),
      ),
    );
  }
}
