import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_sync_summary.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_section_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_stay_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_task_entity.dart';
import 'package:easy_booking/features/home/domain/usecases/get_home_overview_usecase.dart';
import 'package:easy_booking/features/home/presentation/bloc/home_bloc/home_bloc.dart';
import 'package:easy_booking/features/home/presentation/widgets/home_labels.dart';
import 'package:easy_booking/features/home/presentation/widgets/home_skeleton.dart';
import 'package:easy_booking/features/home/presentation/widgets/home_stays_row.dart';
import 'package:easy_booking/features/home/presentation/widgets/home_task_row.dart';

/// Screen 01 «Сегодня»: today's arrivals, departures, and current guests,
/// the tasks before arrival, and the calendar sync status.
///
/// Provides its own [HomeBloc] through [wrappedRoute].
final class HomeScreen extends StatelessWidget implements GoRouterWrapper {
  const HomeScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<HomeBloc>(
      create: (_) => HomeBloc(
        getHomeOverview: dependencies.getDep<GetHomeOverviewUsecase>(),
      )..add(const HomeOverviewRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeBloc bloc = context.read<HomeBloc>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<HomeBloc, HomeState>(
          listenWhen: (HomeState previous, HomeState current) =>
              previous.loadStatus != current.loadStatus &&
              current.loadStatus.isFailure &&
              current.overview != null,
          listener: (BuildContext context, HomeState state) {
            final Failure? failure = state.loadFailure;
            if (failure != null) {
              context.showAppSnackbar(failure.userMessage);
            }
          },
          buildWhen: (prev, curr) => prev.loadStatus != curr.loadStatus,
          builder: (BuildContext context, HomeState state) {
            AppLogger.warning('First upper rebuild');
            final Failure? failure = state.loadFailure;

            return RefreshIndicator.adaptive(
              onRefresh: () {
                bloc.add(const HomeOverviewRequested());
                return bloc.stream.firstWhere(
                  (HomeState state) => !state.loadStatus.isLoading,
                );
              },
              child: ListView(
                children: [
                  AppRootHeader(
                    title: 'Сегодня',
                    subtitle: DateFormatter.weekdayDayMonth(DateTime.now()),
                    action: AppIconButton(
                      semanticLabel: 'Уведомления',
                      onPressed: () =>
                          context.pushNamed(AppRoutes.notifications.name),
                      icon: SvgPicture.asset(
                        AppAssets.icons.notification,
                        width: AppSizes.iconAppBar,
                        height: AppSizes.iconAppBar,
                      ),
                    ),
                  ),
                  if (state.overview != null) ...[
                    BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, state) {
                        AppLogger.warning('Second upper rebuild');
                        final HomeOverviewEntity overview = state.overview!;

                        return Column(
                          crossAxisAlignment: .start,
                          children: [
                            AppScopeFilter(
                              labels: <String>[
                                for (final HomeStayScope scope
                                    in HomeStayScope.values)
                                  '${scope.label} · ${overview.staysFor(scope).length}',
                              ],
                              selectedIndex: state.scope.index,
                              onSelected: (int index) {
                                bloc.add(
                                  HomeScopeSelected(
                                    HomeStayScope.values[index],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.xLarge),
                            HomeStaysRow(
                              scope: state.scope,
                              stays: state.stays,
                              onStaySelected: (HomeStayEntity stay) =>
                                  _openProperty(context, stay.propertyId),
                            ),
                          ],
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.pageGutter,
                        28,
                        AppSizes.pageGutter,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppSectionHeader(
                            title: 'Перед заездом',
                            actionLabel: 'Все задачи',
                            onAction: () => context.showAppSnackbar(
                              'Список задач скоро появится',
                            ),
                          ),
                          for (final HomeTaskEntity task
                              in state.overview!.tasks)
                            HomeTaskRow(
                              task: task,
                              onTap: () => _openTask(context, task),
                              onRemind: () => context.showAppSnackbar(
                                'Напоминание отправлено',
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xLarge),
                          AppSyncSummary(
                            title: state.overview!.sync.title,
                            subtitle: state.overview!.sync.subtitle,
                            // Channels live in the Calendar tab, so switch to it.
                            onTap: () =>
                                context.goNamed(AppRoutes.channels.name),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    if (failure != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.pageGutter,
                        ),
                        child: AppEmptyState(
                          title: 'Не удалось загрузить день',
                          message: failure.userMessage,
                          icon: SvgPicture.asset(AppAssets.icons.alertCircle),
                          actionLabel: 'Повторить',
                          onAction: () => context.read<HomeBloc>().add(
                            const HomeOverviewRequested(),
                          ),
                        ),
                      )
                    else
                      const HomeSkeleton(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openProperty(BuildContext context, String propertyId) {
    context.pushNamed(
      AppRoutes.property.name,
      pathParameters: <String, String>{AppRoutes.propertyIdParam: propertyId},
    );
  }

  void _openTask(BuildContext context, HomeTaskEntity task) {
    switch (task.kind) {
      case HomeTaskKind.contract:
        context.pushNamed(
          AppRoutes.contract.name,
          pathParameters: <String, String>{
            AppRoutes.contractIdParam: task.targetId,
          },
        );
      case HomeTaskKind.preparation:
        _openProperty(context, task.targetId);
    }
  }
}
