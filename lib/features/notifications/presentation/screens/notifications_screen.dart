import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_filter.dart';
import 'package:easy_booking/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:easy_booking/features/notifications/presentation/bloc/notifications_bloc/notifications_bloc.dart';
import 'package:easy_booking/features/notifications/presentation/widgets/notification_labels.dart';
import 'package:easy_booking/features/notifications/presentation/widgets/notification_row.dart';

/// Screen 27 «Уведомления»: the feed grouped by day, filtered by chips.
/// Opening a notification marks it read and opens what it is about.
///
/// Provides its own [NotificationsBloc] through [wrappedRoute].
final class NotificationsScreen extends StatelessWidget
    implements GoRouterWrapper {
  const NotificationsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<NotificationsBloc>(
      create: (_) => NotificationsBloc(
        getNotifications: dependencies.getDep<GetNotificationsUsecase>(),
        markNotificationRead: dependencies
            .getDep<MarkNotificationReadUsecase>(),
        markAllNotificationsRead: dependencies
            .getDep<MarkAllNotificationsReadUsecase>(),
      )..add(const NotificationsRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: MultiBlocListener(
          listeners: <BlocListener<NotificationsBloc, NotificationsState>>[
            BlocListener<NotificationsBloc, NotificationsState>(
              listenWhen:
                  (NotificationsState previous, NotificationsState current) =>
                      previous.actionFailure != current.actionFailure &&
                      current.actionFailure != null,
              listener: (BuildContext context, NotificationsState state) {
                context.showAppSnackbar(state.actionFailure!.userMessage);
              },
            ),
            // Only a failed refresh: the first failure replaces the list.
            BlocListener<NotificationsBloc, NotificationsState>(
              listenWhen:
                  (NotificationsState previous, NotificationsState current) =>
                      previous.loadStatus != current.loadStatus &&
                      current.loadStatus.isFailure &&
                      current.feed != null,
              listener: (BuildContext context, NotificationsState state) {
                context.showAppSnackbar(state.loadFailure!.userMessage);
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppDetailHeader(
                title: 'Уведомления',
                backSemanticLabel: 'Назад',
                showDivider: false,
                onBack: () => context.pop(),
                action: BlocBuilder<NotificationsBloc, NotificationsState>(
                  buildWhen: (prev, curr) =>
                      curr.canMarkAllRead != prev.canMarkAllRead,
                  builder: (context, state) {
                    return _MarkAllReadButton(
                      onPressed: state.canMarkAllRead
                          ? () => context.read<NotificationsBloc>().add(
                              const NotificationsAllReadRequested(),
                            )
                          : null,
                    );
                  },
                ),
              ),
              BlocBuilder<NotificationsBloc, NotificationsState>(
                buildWhen: (prev, curr) => prev.loadStatus != curr.loadStatus,
                builder: (context, state) {
                  return Expanded(child: _buildBody(context, state));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state) {
    final NotificationFeedEntity? feed = state.feed;
    if (feed != null) {
      return _buildFeed(context, state, feed);
    }
    final Failure? failure = state.loadFailure;
    if (failure != null) {
      return ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pageGutter,
          vertical: AppSpacing.large,
        ),
        children: <Widget>[
          AppEmptyState(
            title: 'Не удалось загрузить уведомления',
            message: failure.userMessage,
            icon: SvgPicture.asset(AppAssets.icons.alertCircle),
            actionLabel: 'Повторить',
            onAction: () => context.read<NotificationsBloc>().add(
              const NotificationsRequested(),
            ),
          ),
        ],
      );
    }
    return const _NotificationsSkeleton();
  }

  Widget _buildFeed(
    BuildContext context,
    NotificationsState state,
    NotificationFeedEntity feed,
  ) {
    final NotificationsBloc bloc = context.read<NotificationsBloc>();

    return RefreshIndicator.adaptive(
      onRefresh: () {
        bloc.add(const NotificationsRequested());
        return bloc.stream.firstWhere(
          (NotificationsState state) => !state.loadStatus.isLoading,
        );
      },
      child: BlocBuilder<NotificationsBloc, NotificationsState>(
        buildWhen: (prev, curr) =>
            curr.filter != prev.filter ||
            const DeepCollectionEquality().equals(
              prev.feed?.notifications,
              curr.feed?.notifications,
            ),
        builder: (context, state) {
          final List<NotificationEntity> notifications =
              state.visibleNotifications;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 18),
                child: AppScopeFilter(
                  labels: <String>[
                    for (final NotificationFilter filter
                        in NotificationFilter.values)
                      filter.label,
                  ],
                  selectedIndex: state.filter.index,
                  onSelected: (int index) => bloc.add(
                    NotificationsFilterSelected(
                      NotificationFilter.values[index],
                    ),
                  ),
                ),
              ),
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pageGutter,
                  ),
                  child: AppEmptyState(
                    title: state.filter.emptyTitle,
                    message: 'Здесь появятся заезды, конфликты и подписи',
                    icon: SvgPicture.asset(AppAssets.icons.notification),
                  ),
                )
              else
                ..._buildGroups(context, notifications, now: feed.receivedAt),
            ],
          );
        },
      ),
    );
  }

  /// Day headers followed by their notifications, in feed order.
  List<Widget> _buildGroups(
    BuildContext context,
    List<NotificationEntity> notifications, {
    required DateTime now,
  }) {
    final List<Widget> children = <Widget>[];
    String? currentDay;
    for (int index = 0; index < notifications.length; index++) {
      final NotificationEntity notification = notifications[index];
      final String day = NotificationTimeLabels.day(
        notification.createdAt,
        now: now,
      );
      if (day != currentDay) {
        children.add(_DayHeader(label: day, isFirst: currentDay == null));
        currentDay = day;
      }
      children.add(
        NotificationRow(
          notification: notification,
          timeLabel: NotificationTimeLabels.createdAt(
            notification.createdAt,
            now: now,
          ),
          showDivider: index < notifications.length - 1,
          onTap: () => _open(context, notification),
          onAction: () => _open(context, notification),
        ),
      );
    }
    return children;
  }

  void _open(BuildContext context, NotificationEntity notification) {
    context.read<NotificationsBloc>().add(NotificationOpened(notification.id));
    final (AppRoutes route, String param) = switch (notification.kind) {
      NotificationKind.bookingConflict => (
        AppRoutes.calendarConflict,
        AppRoutes.conflictIdParam,
      ),
      // The iCal link is in the property settings.
      NotificationKind.syncFailed => (
        AppRoutes.propertySettings,
        AppRoutes.propertyIdParam,
      ),
      NotificationKind.contractUnsigned || NotificationKind.contractSigned => (
        AppRoutes.contract,
        AppRoutes.contractIdParam,
      ),
      NotificationKind.arrivalSoon => (
        AppRoutes.booking,
        AppRoutes.bookingIdParam,
      ),
      NotificationKind.propertyPublished => (
        AppRoutes.property,
        AppRoutes.propertyIdParam,
      ),
    };
    context.pushNamed(
      route.name,
      pathParameters: <String, String>{param: notification.targetId},
    );
  }
}

final class _MarkAllReadButton extends StatelessWidget {
  const _MarkAllReadButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSizes.touchTarget,
          minHeight: AppSizes.touchTarget,
        ),
        child: Center(
          child: Opacity(
            opacity: isEnabled ? 1 : 0.4,
            child: AppTextButton.muted(
              label: 'Прочитать',
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

final class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.isFirst});

  final String label;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        isFirst ? 2 : 22,
        AppSizes.pageGutter,
        AppSpacing.small,
      ),
      child: Text(
        label,
        style: AppTypography.compactBody.copyWith(
          fontWeight: FontWeight.w600,
          height: 16 / 13,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}

final class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        14,
        AppSizes.pageGutter,
        0,
      ),
      children: <Widget>[
        const Row(
          children: <Widget>[
            AppSkeleton(height: 32, width: 52),
            SizedBox(width: AppSpacing.small),
            AppSkeleton(height: 32, width: 80),
            SizedBox(width: AppSpacing.small),
            AppSkeleton(height: 32, width: 92),
          ],
        ),
        const SizedBox(height: AppSpacing.xLarge),
        for (int index = 0; index < 4; index++) ...<Widget>[
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppSkeleton(height: 40, width: 40),
              SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppSkeleton(height: 16, width: 180),
                    SizedBox(height: AppSpacing.small),
                    AppSkeleton(height: 36, borderRadius: AppRadii.field),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xLarge),
        ],
      ],
    );
  }
}
