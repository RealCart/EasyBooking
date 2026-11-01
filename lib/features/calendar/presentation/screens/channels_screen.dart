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
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channels_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/channels_bloc/channels_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/channel_labels.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/channel_tile.dart';

/// Screen 22 «Каналы»: the booking channels, their sync status, and the
/// calendars that need attention.
///
/// Provides its own [ChannelsBloc] through [wrappedRoute].
final class ChannelsScreen extends StatelessWidget implements GoRouterWrapper {
  const ChannelsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<ChannelsBloc>(
      create: (_) =>
          ChannelsBloc(getChannels: dependencies.getDep<GetChannelsUsecase>())
            ..add(const ChannelsRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChannelsBloc, ChannelsState>(
      // A failed reload keeps the last channels on screen and only says so.
      listenWhen: (ChannelsState previous, ChannelsState current) =>
          current.overview != null &&
          current.loadFailure != null &&
          previous.loadFailure != current.loadFailure,
      listener: (BuildContext context, ChannelsState state) {
        context.showAppSnackbar(state.loadFailure!.userMessage);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator.adaptive(
            onRefresh: () {
              final ChannelsBloc bloc = context.read<ChannelsBloc>();
              bloc.add(const ChannelsRequested());
              return bloc.stream.firstWhere(
                (ChannelsState state) => !state.loadStatus.isLoading,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
              children: const <Widget>[_ChannelsHeader(), _ChannelsBody()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reloads afterwards: the channel may have been synced or disconnected.
Future<void> _openChannel(BuildContext context, ChannelEntity channel) async {
  await context.pushNamed(
    AppRoutes.channel.name,
    pathParameters: <String, String>{AppRoutes.channelIdParam: channel.id},
  );
  if (context.mounted) {
    context.read<ChannelsBloc>().add(const ChannelsRequested());
  }
}

/// «Каналы» with the overview's summary.
final class _ChannelsHeader extends StatelessWidget {
  const _ChannelsHeader();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChannelsBloc, ChannelsState, String?>(
      selector: (ChannelsState state) => state.overview?.summary,
      builder: (BuildContext context, String? summary) {
        return AppRootHeader(
          title: 'Каналы',
          subtitle: summary,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSizes.pageGutter,
            AppSpacing.medium,
            AppSizes.pageGutter,
            AppSpacing.large,
          ),
        );
      },
    );
  }
}

/// The channels, or before they arrive their skeleton or the error.
final class _ChannelsBody extends StatelessWidget {
  const _ChannelsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelsBloc, ChannelsState>(
      buildWhen: (ChannelsState previous, ChannelsState current) =>
          previous.overview != current.overview ||
          previous.loadFailure != current.loadFailure,
      builder: (BuildContext context, ChannelsState state) {
        final ChannelsOverviewEntity? overview = state.overview;
        if (overview == null) {
          return _ChannelsPlaceholder(failure: state.loadFailure);
        }
        return _ChannelsList(overview: overview);
      },
    );
  }
}

final class _ChannelsPlaceholder extends StatelessWidget {
  const _ChannelsPlaceholder({required this.failure});

  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: failure == null
          ? const _ChannelsSkeleton()
          : AppEmptyState(
              title: 'Не удалось загрузить каналы',
              message: failure.userMessage,
              icon: SvgPicture.asset(AppAssets.icons.alertCircle),
              actionLabel: 'Повторить',
              onAction: () =>
                  context.read<ChannelsBloc>().add(const ChannelsRequested()),
            ),
    );
  }
}

final class _ChannelsList extends StatelessWidget {
  const _ChannelsList({required this.overview});

  final ChannelsOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final DateTime now = overview.receivedAt;
    final List<ChannelEntity> channels = overview.channels;
    final List<ChannelEntity> failedChannels = channels
        .where((ChannelEntity channel) => channel.failedConnections.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              overview.checkedLabel(now: now),
              style: AppTypography.compactBody.copyWith(
                height: 16 / 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          if (channels.isEmpty)
            AppEmptyState(
              title: 'Каналы не подключены',
              message:
                  'Подключите Airbnb или Booking.com, чтобы календари '
                  'обновлялись сами',
              icon: SvgPicture.asset(AppAssets.icons.calendarGrid),
            )
          else
            for (int index = 0; index < channels.length; index++)
              _ChannelListTile(
                channel: channels[index],
                now: now,
                isLast: index == channels.length - 1,
                onTap: () => _openChannel(context, channels[index]),
              ),
          for (final ChannelEntity channel in failedChannels)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: AppCallout(
                title: channel.failureTitle,
                message: channel.failureMessage,
                tone: AppFeedbackTone.error,
                actionLabel: 'Исправить',
                onAction: () => _openChannel(context, channel),
              ),
            ),
        ],
      ),
    );
  }
}

final class _ChannelListTile extends StatelessWidget {
  const _ChannelListTile({
    required this.channel,
    required this.now,
    required this.isLast,
    required this.onTap,
  });

  final ChannelEntity channel;
  final DateTime now;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? statusLabel = channel.statusLabel;
    return ChannelTile(
      initial: channel.initial,
      title: channel.name,
      subtitle: channel.listSubtitle(now: now),
      trailing: statusLabel ?? 'Настроить',
      trailingTone: switch (channel.status) {
        ChannelStatus.connected => ChannelTileTrailingTone.success,
        ChannelStatus.failed => ChannelTileTrailingTone.error,
        ChannelStatus.disconnected => ChannelTileTrailingTone.neutral,
        ChannelStatus.manual => ChannelTileTrailingTone.link,
      },
      showBottomDivider: isLast,
      onTap: onTap,
    );
  }
}

final class _ChannelsSkeleton extends StatelessWidget {
  const _ChannelsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppSkeleton(height: 16, width: 180),
        const SizedBox(height: AppSpacing.large),
        for (int index = 0; index < 3; index++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
            child: Row(
              children: <Widget>[
                AppSkeleton(
                  height: 44,
                  width: 44,
                  borderRadius: AppRadii.media,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppSkeleton(height: 16, width: 120),
                      SizedBox(height: AppSpacing.small),
                      AppSkeleton(height: 14, width: 200),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
