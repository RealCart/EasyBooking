import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_sync_summary.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_section_header.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/features/home/presentation/mock/home_mock_data.dart';
import 'package:easy_booking/features/home/presentation/widgets/home_labels.dart';
import 'package:easy_booking/features/home/presentation/widgets/home_stays_row.dart';
import 'package:easy_booking/features/home/presentation/widgets/home_task_row.dart';

/// Screen 01 «Сегодня»: today's arrivals, departures, and current guests,
/// the tasks before arrival, and the calendar sync status.
///
/// Shows [HomeMockData] until the home domain and data layers exist.
final class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  late final HomeMockData _data;
  late HomeStayScope _scope;

  @override
  void initState() {
    super.initState();
    _data = HomeMockData.forDay(DateTime.now());
    _scope = HomeStayScope.arrivals;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppRootHeader(
                title: 'Сегодня',
                subtitle: DateFormatter.weekdayDayMonth(_data.date),
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
              AppScopeFilter(
                labels: <String>[
                  for (final HomeStayScope scope in HomeStayScope.values)
                    '${scope.label} · ${_data.staysFor(scope).length}',
                ],
                selectedIndex: _scope.index,
                onSelected: (int index) {
                  setState(() => _scope = HomeStayScope.values[index]);
                },
              ),
              const SizedBox(height: AppSpacing.xLarge),
              HomeStaysRow(
                scope: _scope,
                stays: _data.staysFor(_scope),
                onStaySelected: _openProperty,
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
                    for (final HomeTaskMock task in _data.tasks)
                      HomeTaskRow(
                        task: task,
                        onTap: () => _openTask(task),
                        onRemind: () => context.showAppSnackbar(
                          'Напоминание отправлено',
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xLarge),
                    AppSyncSummary(
                      title: _data.sync.title,
                      subtitle: _data.sync.subtitle,
                      // Channels live in the Calendar tab, so switch to it.
                      onTap: () => context.goNamed(AppRoutes.channels.name),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProperty(HomeStayMock stay) {
    context.pushNamed(
      AppRoutes.property.name,
      pathParameters: <String, String>{
        AppRoutes.propertyIdParam: stay.propertyId,
      },
    );
  }

  void _openTask(HomeTaskMock task) {
    switch (task.kind) {
      case HomeTaskKind.contract:
        context.pushNamed(
          AppRoutes.contract.name,
          pathParameters: <String, String>{
            AppRoutes.contractIdParam: task.targetId,
          },
        );
      case HomeTaskKind.preparation:
        context.pushNamed(
          AppRoutes.property.name,
          pathParameters: <String, String>{
            AppRoutes.propertyIdParam: task.targetId,
          },
        );
    }
  }
}
