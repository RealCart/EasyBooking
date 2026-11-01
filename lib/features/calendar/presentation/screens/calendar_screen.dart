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
import 'package:easy_booking/core/presentation/widgets/content/app_calendar_event_row.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_sync_summary.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_week_selector.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_event_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_day_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/calendar_bloc/calendar_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/calendar_labels.dart';

/// Screen 06 «Календарь»: the check-ins and check-outs of one day of the
/// week, for all or only favorite properties.
///
/// Provides its own [CalendarBloc] through [wrappedRoute].
final class CalendarScreen extends StatelessWidget implements GoRouterWrapper {
  const CalendarScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<CalendarBloc>(
      create: (_) => CalendarBloc(
        getCalendarDay: dependencies.getDep<GetCalendarDayUsecase>(),
      )..add(const CalendarRequested()),
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
            final CalendarBloc bloc = context.read<CalendarBloc>();
            bloc.add(const CalendarRequested());
            return bloc.stream.firstWhere(
              (CalendarState state) => !state.loadStatus.isLoading,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
            children: const <Widget>[
              _CalendarHeader(),
              Padding(
                padding: EdgeInsets.only(
                  right: AppSpacing.large,
                  bottom: AppSpacing.xLarge,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: _CalendarScopeFilter()),
                    _CalendarMoreButton(),
                  ],
                ),
              ),
              _CalendarBody(),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Календарь» with the month of the selected day.
final class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CalendarBloc, CalendarState, DateTime?>(
      selector: (CalendarState state) => state.selectedDate,
      builder: (BuildContext context, DateTime? selectedDate) {
        return AppRootHeader(
          title: 'Календарь',
          subtitle: selectedDate == null
              ? null
              : DateFormatter.monthYear(selectedDate),
          action: const _ChannelsButton(),
        );
      },
    );
  }
}

final class _ChannelsButton extends StatelessWidget {
  const _ChannelsButton();

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      semanticLabel: 'Каналы',
      onPressed: () => context.goNamed(AppRoutes.channels.name),
      icon: SvgPicture.asset(
        AppAssets.icons.sliders,
        width: AppSizes.iconAppBar,
        height: AppSizes.iconAppBar,
      ),
    );
  }
}

final class _CalendarScopeFilter extends StatelessWidget {
  const _CalendarScopeFilter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CalendarBloc, CalendarState, bool>(
      selector: (CalendarState state) => state.favoritesOnly,
      builder: (BuildContext context, bool favoritesOnly) {
        return AppScopeFilter(
          labels: const <String>['Все объекты', 'Избранные'],
          selectedIndex: favoritesOnly ? 1 : 0,
          padding: const EdgeInsetsDirectional.only(
            start: AppSizes.pageGutter,
          ),
          onSelected: (int index) => context.read<CalendarBloc>().add(
            CalendarScopeSelected(favoritesOnly: index == 1),
          ),
        );
      },
    );
  }
}

final class _CalendarMoreButton extends StatelessWidget {
  const _CalendarMoreButton();

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
      builder: (BuildContext sheetContext) => const _CalendarMoreSheet(),
    );
    if (route != null && context.mounted) {
      context.goNamed(route.name);
    }
  }
}

/// The ⋯ menu; pops with the chosen route.
final class _CalendarMoreSheet extends StatelessWidget {
  const _CalendarMoreSheet();

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
              title: 'Занятость объектов',
              subtitle: 'Все квартиры на одной шкале',
              onTap: () => Navigator.of(context).pop(AppRoutes.occupancy),
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

/// Before the first load the week is unknown; afterwards the week of the
/// selected day and its events.
final class _CalendarBody extends StatelessWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CalendarBloc, CalendarState, DateTime?>(
      selector: (CalendarState state) => state.selectedDate,
      builder: (BuildContext context, DateTime? selectedDate) {
        if (selectedDate == null) {
          return const _FirstLoad();
        }
        return _SelectedDay(selectedDate: selectedDate);
      },
    );
  }
}

/// Before the first day arrives, the week is unknown.
final class _FirstLoad extends StatelessWidget {
  const _FirstLoad();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: BlocSelector<CalendarBloc, CalendarState, Failure?>(
        selector: (CalendarState state) => state.loadFailure,
        builder: (BuildContext context, Failure? failure) {
          if (failure != null) {
            return _LoadError(failure: failure);
          }
          return const Column(
            children: <Widget>[
              AppSkeleton(height: 68, borderRadius: AppRadii.media),
              SizedBox(height: AppSpacing.xLarge),
              _EventsSkeleton(),
            ],
          );
        },
      ),
    );
  }
}

final class _SelectedDay extends StatelessWidget {
  const _SelectedDay({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            0,
            AppSizes.pageGutter,
            AppSpacing.xLarge,
          ),
          child: AppWeekSelector(
            days: _weekOf(selectedDate),
            selectedDate: selectedDate,
            onSelected: (AppWeekDay day) =>
                context.read<CalendarBloc>().add(CalendarDaySelected(day.date)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            0,
            AppSizes.pageGutter,
            20,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DateFormatter.dayMonthWeekday(selectedDate),
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              AppTextButton.underlined(
                label: 'Неделя',
                onPressed: () => context.goNamed(AppRoutes.occupancy.name),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
          child: _DayEvents(),
        ),
      ],
    );
  }

  /// Monday to Sunday of the week of [date].
  static List<AppWeekDay> _weekOf(DateTime date) {
    final DateTime monday = DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - DateTime.monday),
    );
    return <AppWeekDay>[
      for (int offset = 0; offset < DateTime.daysPerWeek; offset++)
        _weekDay(DateTime(monday.year, monday.month, monday.day + offset)),
    ];
  }

  static AppWeekDay _weekDay(DateTime date) {
    return AppWeekDay(
      date: date,
      weekdayLabel: DateFormatter.weekdayShort(date),
      semanticLabel: DateFormatter.dayMonthWeekday(date),
    );
  }
}

/// The selected day's events, its skeleton while it loads, or the error.
final class _DayEvents extends StatelessWidget {
  const _DayEvents();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      buildWhen: (CalendarState previous, CalendarState current) =>
          previous.loadFailure != current.loadFailure ||
          previous.selectedDay != current.selectedDay ||
          previous.favoritesOnly != current.favoritesOnly,
      builder: (BuildContext context, CalendarState state) {
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          return _LoadError(failure: failure);
        }
        final CalendarDayEntity? day = state.selectedDay;
        if (day == null) {
          return const _EventsSkeleton();
        }
        return _DayContent(day: day, favoritesOnly: state.favoritesOnly);
      },
    );
  }
}

final class _DayContent extends StatelessWidget {
  const _DayContent({required this.day, required this.favoritesOnly});

  final CalendarDayEntity day;
  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (day.events.isEmpty)
          AppEmptyState(
            title: 'Ни заездов, ни выездов',
            message: favoritesOnly
                ? 'У избранных квартир в этот день нет событий'
                : 'В этот день квартиры свободны от смены гостей',
            icon: SvgPicture.asset(AppAssets.icons.calendarGrid),
          )
        else
          for (final CalendarEventEntity event in day.events)
            AppCalendarEventRow(
              time: DateFormatter.time(event.at),
              title: event.title,
              propertyName: event.propertyLabel,
              subtitle: event.details,
              imageUrl: event.imageUrl,
              onTap: () => context.pushNamed(
                AppRoutes.booking.name,
                pathParameters: <String, String>{
                  AppRoutes.bookingIdParam: event.bookingId,
                },
              ),
            ),
        const SizedBox(height: AppSpacing.medium),
        AppSyncSummary(
          title: day.syncTitle,
          subtitle: day.syncSubtitle,
          isSuccessful: day.isSyncHealthy,
          onTap: () => context.goNamed(AppRoutes.channels.name),
        ),
      ],
    );
  }
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Не удалось загрузить календарь',
      message: failure.userMessage,
      icon: SvgPicture.asset(AppAssets.icons.alertCircle),
      actionLabel: 'Повторить',
      onAction: () =>
          context.read<CalendarBloc>().add(const CalendarRequested()),
    );
  }
}

final class _EventsSkeleton extends StatelessWidget {
  const _EventsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < 3; index++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppSkeleton(height: 18, width: 44),
                SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppSkeleton(height: 20, width: 160),
                      SizedBox(height: AppSpacing.small),
                      AppSkeleton(height: 16, width: 200),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.medium),
                AppSkeleton(
                  height: 64,
                  width: 56,
                  borderRadius: AppRadii.card,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
