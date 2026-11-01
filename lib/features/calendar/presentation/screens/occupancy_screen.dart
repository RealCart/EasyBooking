import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_sync_summary.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_row_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_occupancy_week_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/occupancy_bloc/occupancy_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/occupancy_grid.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/occupancy_labels.dart';

/// Screen 20 «Занятость объектов»: every property's stays and closed dates
/// on one week, for all or only favorite properties.
///
/// Provides its own [OccupancyBloc] through [wrappedRoute].
final class OccupancyScreen extends StatelessWidget implements GoRouterWrapper {
  const OccupancyScreen({super.key});

  /// The grid's side padding is narrower than the page gutter, as in the
  /// design, to give the days more room.
  static const double _gridGutter = AppSpacing.large;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<OccupancyBloc>(
      create: (_) => OccupancyBloc(
        getOccupancyWeek: dependencies.getDep<GetOccupancyWeekUsecase>(),
      )..add(const OccupancyRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator.adaptive(
          onRefresh: () {
            final OccupancyBloc bloc = context.read<OccupancyBloc>();
            bloc.add(const OccupancyRequested());
            return bloc.stream.firstWhere(
              (OccupancyState state) => !state.loadStatus.isLoading,
            );
          },
          child: const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(child: _OccupancyHeader()),
              _OccupancyBody(),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

extension on OccupancyState {
  /// The week whose days are shown. While «Сегодня» loads, the previous
  /// week stays on screen.
  DateTime? get shownWeekStart => weekStart ?? week?.weekStart;
}

final class _OccupancyHeader extends StatelessWidget {
  const _OccupancyHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _OccupancyRootHeader(),
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.large),
          child: Row(
            children: <Widget>[
              Expanded(child: _OccupancyScopeFilter()),
              _OccupancyMoreButton(),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.large,
            AppSpacing.small,
            AppSpacing.large,
            AppSpacing.medium,
          ),
          child: _WeekNavigator(),
        ),
      ],
    );
  }
}

/// «Занятость» with the month of the shown week.
final class _OccupancyRootHeader extends StatelessWidget {
  const _OccupancyRootHeader();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OccupancyBloc, OccupancyState, DateTime?>(
      selector: (OccupancyState state) => state.shownWeekStart,
      builder: (BuildContext context, DateTime? weekStart) {
        return AppRootHeader(
          title: 'Занятость',
          subtitle: weekStart == null
              ? null
              : DateFormatter.monthYear(weekStart),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSizes.pageGutter,
            AppSpacing.medium,
            AppSizes.pageGutter,
            AppSpacing.large,
          ),
          action: const _TodayButton(),
        );
      },
    );
  }
}

final class _TodayButton extends StatelessWidget {
  const _TodayButton();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSizes.touchTarget,
        minHeight: AppSizes.touchTarget,
      ),
      child: Center(
        child: AppTextButton.underlined(
          label: 'Сегодня',
          onPressed: () => context.read<OccupancyBloc>().add(
            const OccupancyCurrentWeekSelected(),
          ),
        ),
      ),
    );
  }
}

final class _OccupancyScopeFilter extends StatelessWidget {
  const _OccupancyScopeFilter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OccupancyBloc, OccupancyState, bool>(
      selector: (OccupancyState state) => state.favoritesOnly,
      builder: (BuildContext context, bool favoritesOnly) {
        return AppScopeFilter(
          labels: const <String>['Все объекты', 'Избранные'],
          selectedIndex: favoritesOnly ? 1 : 0,
          padding: const EdgeInsetsDirectional.only(
            start: AppSizes.pageGutter,
          ),
          onSelected: (int index) => context.read<OccupancyBloc>().add(
            OccupancyScopeSelected(favoritesOnly: index == 1),
          ),
        );
      },
    );
  }
}

final class _OccupancyMoreButton extends StatelessWidget {
  const _OccupancyMoreButton();

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      semanticLabel: 'Ещё',
      onPressed: () => _showMore(context),
      icon: SvgPicture.asset(
        AppAssets.icons.moreHorizontal,
        width: AppSizes.iconAppBar,
        height: AppSizes.iconAppBar,
      ),
    );
  }

  Future<void> _showMore(BuildContext context) async {
    final AppRoutes? route = await showModalBottomSheet<AppRoutes>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext sheetContext) => const _OccupancyMoreSheet(),
    );
    if (route != null && context.mounted) {
      context.goNamed(route.name);
    }
  }
}

/// The ⋯ menu; pops with the chosen route.
final class _OccupancyMoreSheet extends StatelessWidget {
  const _OccupancyMoreSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pageGutter,
          vertical: AppSpacing.small,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppProfileMenuItem(
              title: 'Календарь по дням',
              subtitle: 'Заезды и выезды выбранного дня',
              onTap: () => Navigator.of(context).pop(AppRoutes.calendar),
            ),
            AppProfileMenuItem(
              title: 'Каналы',
              subtitle: 'Airbnb, Booking.com и синхронизация',
              showDivider: false,
              onTap: () => Navigator.of(context).pop(AppRoutes.channels),
            ),
          ],
        ),
      ),
    );
  }
}

/// ‹ week range ›; the arrows are disabled until the first week arrives.
final class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OccupancyBloc, OccupancyState, DateTime?>(
      selector: (OccupancyState state) => state.shownWeekStart,
      builder: (BuildContext context, DateTime? weekStart) {
        return Row(
          children: <Widget>[
            AppIconButton(
              semanticLabel: 'Предыдущая неделя',
              icon: SvgPicture.asset(
                AppAssets.icons.chevronLeft,
                width: AppSizes.iconAction,
                height: AppSizes.iconAction,
              ),
              onPressed: weekStart == null
                  ? null
                  : () => context.read<OccupancyBloc>().add(
                      OccupancyWeekSelected(weekStart.addDays(-7)),
                    ),
            ),
            Expanded(
              child: Text(
                weekStart == null
                    ? ''
                    : DateFormatter.dayRange(
                        weekStart,
                        weekStart.addDays(DateTime.daysPerWeek - 1),
                      ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.action.copyWith(color: AppColors.text),
              ),
            ),
            AppIconButton(
              semanticLabel: 'Следующая неделя',
              icon: SvgPicture.asset(
                AppAssets.icons.chevronRight,
                width: AppSizes.iconAction,
                height: AppSizes.iconAction,
              ),
              onPressed: weekStart == null
                  ? null
                  : () => context.read<OccupancyBloc>().add(
                      OccupancyWeekSelected(weekStart.addDays(7)),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// A sliver: the first-load placeholder, or the shown week's days and rows.
final class _OccupancyBody extends StatelessWidget {
  const _OccupancyBody();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OccupancyBloc, OccupancyState, DateTime?>(
      selector: (OccupancyState state) => state.shownWeekStart,
      builder: (BuildContext context, DateTime? weekStart) {
        if (weekStart == null) {
          return const SliverToBoxAdapter(child: _FirstLoad());
        }
        return SliverMainAxisGroup(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: OccupancyScreen._gridGutter,
              ),
              sliver: SliverToBoxAdapter(
                child: _DaysHeader(weekStart: weekStart),
              ),
            ),
            const _WeekRows(),
          ],
        );
      },
    );
  }
}

final class _DaysHeader extends StatelessWidget {
  const _DaysHeader({required this.weekStart});

  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OccupancyBloc, OccupancyState, DateTime?>(
      selector: (OccupancyState state) => state.week?.today,
      builder: (BuildContext context, DateTime? today) {
        return OccupancyDaysHeader(
          days: <DateTime>[
            for (int day = 0; day < DateTime.daysPerWeek; day++)
              weekStart.addDays(day),
          ],
          today: today,
        );
      },
    );
  }
}

/// Before the first week arrives, the days are unknown.
final class _FirstLoad extends StatelessWidget {
  const _FirstLoad();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OccupancyScreen._gridGutter,
      ),
      child: BlocSelector<OccupancyBloc, OccupancyState, Failure?>(
        selector: (OccupancyState state) => state.loadFailure,
        builder: (BuildContext context, Failure? failure) {
          if (failure != null) {
            return _LoadError(failure: failure);
          }
          return const Column(
            children: <Widget>[
              AppSkeleton(height: 38, borderRadius: AppRadii.field),
              SizedBox(height: AppSpacing.small),
              _RowsSkeleton(),
            ],
          );
        },
      ),
    );
  }
}

/// A sliver: the selected week's rows, its skeleton, the error, or the
/// empty state.
final class _WeekRows extends StatelessWidget {
  const _WeekRows();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OccupancyBloc, OccupancyState>(
      buildWhen: (OccupancyState previous, OccupancyState current) =>
          previous.loadFailure != current.loadFailure ||
          previous.selectedWeek != current.selectedWeek ||
          previous.favoritesOnly != current.favoritesOnly,
      builder: (BuildContext context, OccupancyState state) {
        final Failure? failure = state.loadFailure;
        final OccupancyWeekEntity? week = state.selectedWeek;
        if (failure != null || week == null) {
          return _WeekPlaceholder(failure: failure);
        }
        if (week.rows.isEmpty) {
          return _EmptyWeek(favoritesOnly: state.favoritesOnly);
        }
        return _WeekContent(week: week);
      },
    );
  }
}

/// A sliver: the rows' skeleton while the week loads, or the error.
final class _WeekPlaceholder extends StatelessWidget {
  const _WeekPlaceholder({required this.failure});

  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: OccupancyScreen._gridGutter,
      ),
      sliver: SliverToBoxAdapter(
        child: failure == null
            ? const _RowsSkeleton()
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.small),
                child: _LoadError(failure: failure),
              ),
      ),
    );
  }
}

/// A sliver: no properties in the chosen scope.
final class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        OccupancyScreen._gridGutter,
        AppSpacing.small,
        OccupancyScreen._gridGutter,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: AppEmptyState(
          title: favoritesOnly ? 'Нет избранных квартир' : 'Пока нет квартир',
          message: favoritesOnly
              ? 'Отметьте квартиры сердечком, чтобы видеть их здесь'
              : 'Добавьте квартиру, чтобы видеть её занятость',
          icon: SvgPicture.asset(AppAssets.icons.building),
        ),
      ),
    );
  }
}

/// A sliver: one row per property, then the sync summary.
final class _WeekContent extends StatelessWidget {
  const _WeekContent({required this.week});

  final OccupancyWeekEntity week;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: OccupancyScreen._gridGutter,
          ),
          sliver: SliverList.builder(
            itemCount: week.rows.length,
            itemBuilder: (BuildContext context, int index) {
              final OccupancyRowEntity row = week.rows[index];
              return OccupancyPropertyRow(
                row: row,
                weekStart: week.weekStart,
                showBottomDivider: index == week.rows.length - 1,
                onBlockTap: (OccupancyBlockEntity block) =>
                    _openBlock(context, block),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            AppSpacing.small,
            AppSizes.pageGutter,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: AppSyncSummary(
              title: week.syncTitle,
              subtitle: week.syncSubtitle,
              isSuccessful: week.isSyncHealthy,
              onTap: () => context.goNamed(AppRoutes.channels.name),
            ),
          ),
        ),
      ],
    );
  }

  /// A conflicting stay opens the conflict; any other stay its booking.
  /// The week reloads afterwards, since resolving a conflict cancels a stay.
  Future<void> _openBlock(
    BuildContext context,
    OccupancyBlockEntity block,
  ) async {
    final String? conflictId = block.conflictId;
    final String? bookingId = block.bookingId;
    if (conflictId != null) {
      await context.pushNamed(
        AppRoutes.calendarConflict.name,
        pathParameters: <String, String>{
          AppRoutes.conflictIdParam: conflictId,
        },
      );
      if (context.mounted) {
        context.read<OccupancyBloc>().add(const OccupancyRequested());
      }
    } else if (bookingId != null) {
      await context.pushNamed(
        AppRoutes.booking.name,
        pathParameters: <String, String>{AppRoutes.bookingIdParam: bookingId},
      );
    }
  }
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Не удалось загрузить занятость',
      message: failure.userMessage,
      icon: SvgPicture.asset(AppAssets.icons.alertCircle),
      actionLabel: 'Повторить',
      onAction: () =>
          context.read<OccupancyBloc>().add(const OccupancyRequested()),
    );
  }
}

final class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < 3; index++)
          const SizedBox(
            height: 104,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 116,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppSkeleton(height: 14, width: 84),
                      SizedBox(height: AppSpacing.small),
                      AppSkeleton(height: 12, width: 56),
                    ],
                  ),
                ),
                Expanded(
                  child: AppSkeleton(height: 58, borderRadius: AppRadii.field),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
