import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_connection_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/disconnect_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/sync_channel_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/channel_bloc/channel_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/calendar_decision_footer.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/channel_connection_row.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/channel_labels.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/channel_link_field.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/channel_logo.dart';

/// Screen 23 «Канал»: one channel's calendar links, its properties, and
/// «Синхронизировать сейчас» / «Отключить».
///
/// Provides its own [ChannelBloc] through [wrappedRoute]. Stateful only for
/// the property whose calendar is shown.
final class ChannelScreen extends StatefulWidget implements GoRouterWrapper {
  const ChannelScreen({required this.channelId, super.key});

  final String channelId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<ChannelBloc>(
      create: (_) => ChannelBloc(
        getChannel: dependencies.getDep<GetChannelUsecase>(),
        syncChannel: dependencies.getDep<SyncChannelUsecase>(),
        disconnectChannel: dependencies.getDep<DisconnectChannelUsecase>(),
      )..add(ChannelRequested(channelId)),
      child: this,
    );
  }

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

final class _ChannelScreenState extends State<ChannelScreen> {
  /// The property whose calendar is shown; `null` shows the first failed
  /// one, or the first. Read by the ⋯ menu and the channel details only.
  late final ValueNotifier<String?> _selectedPropertyId;

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = ValueNotifier<String?>(null);
  }

  @override
  void dispose() {
    _selectedPropertyId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ChannelHeader(
            selectedPropertyId: _selectedPropertyId,
            onCopy: _copy,
          ),
          Expanded(
            child: _ChannelBody(
              selectedPropertyId: _selectedPropertyId,
              onPropertySelected: _selectProperty,
              onCopy: _copy,
            ),
          ),
        ],
      ),
    );
    return MultiBlocListener(
      listeners: <BlocListener<ChannelBloc, ChannelState>>[
        BlocListener<ChannelBloc, ChannelState>(
          listenWhen: (ChannelState previous, ChannelState current) =>
              previous.syncStatus != current.syncStatus,
          listener: (BuildContext context, ChannelState state) {
            if (state.syncStatus.isSuccess) {
              context.showAppSnackbar('Календари обновлены');
            } else if (state.syncFailure case final Failure failure) {
              context.showAppSnackbar(failure.userMessage);
            }
          },
        ),
        BlocListener<ChannelBloc, ChannelState>(
          listenWhen: (ChannelState previous, ChannelState current) =>
              previous.disconnectStatus != current.disconnectStatus,
          listener: (BuildContext context, ChannelState state) {
            if (state.disconnectStatus.isSuccess) {
              context.pop();
            } else if (state.disconnectFailure case final Failure failure) {
              context.showAppSnackbar(failure.userMessage);
            }
          },
        ),
      ],
      // Only whether the footer exists rebuilds the scaffold; [body] is the
      // same instance every time.
      child: BlocSelector<ChannelBloc, ChannelState, bool>(
        selector: (ChannelState state) {
          final ChannelEntity? channel = state.channel;
          return channel != null &&
              channel.status != ChannelStatus.disconnected;
        },
        builder: (BuildContext context, bool hasFooter) {
          return Scaffold(
            body: body,
            bottomNavigationBar: hasFooter ? const _ChannelFooter() : null,
          );
        },
      ),
    );
  }

  void _selectProperty(String propertyId) {
    _selectedPropertyId.value = propertyId;
  }

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      context.showAppSnackbar('Ссылка скопирована');
    }
  }
}

/// The connection whose calendar is shown: [selectedPropertyId]'s, or the
/// first failed one, or the first.
ChannelConnectionEntity? _selectedConnection(
  ChannelEntity channel,
  String? selectedPropertyId,
) {
  final List<ChannelConnectionEntity> connections = channel.connections;
  if (connections.isEmpty) {
    return null;
  }
  for (final ChannelConnectionEntity connection in connections) {
    if (connection.propertyId == selectedPropertyId) {
      return connection;
    }
  }
  final List<ChannelConnectionEntity> failed = channel.failedConnections;
  return failed.isEmpty ? connections.first : failed.first;
}

Future<void> _confirmDisconnect(
  BuildContext context,
  ChannelEntity channel,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AppConfirmationDialog(
      title: 'Отключить ${channel.name}?',
      message:
          'Брони с ${channel.name} перестанут попадать в календарь, '
          'а площадка не будет получать занятость из EasyBooking.',
      cancelLabel: 'Отмена',
      confirmLabel: 'Отключить',
      onCancel: () => Navigator.of(dialogContext).pop(false),
      onConfirm: () => Navigator.of(dialogContext).pop(true),
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<ChannelBloc>().add(const ChannelDisconnectRequested());
  }
}

/// The header: the channel's name, back, and the ⋯ menu.
final class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({
    required this.selectedPropertyId,
    required this.onCopy,
  });

  final ValueListenable<String?> selectedPropertyId;
  final Future<void> Function(String url) onCopy;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      buildWhen: (ChannelState previous, ChannelState current) =>
          previous.channel != current.channel ||
          previous.syncStatus != current.syncStatus ||
          previous.disconnectStatus != current.disconnectStatus,
      builder: (BuildContext context, ChannelState state) {
        final ChannelEntity? channel = state.channel;
        return AppDetailHeader(
          title: channel?.name ?? 'Канал',
          backSemanticLabel: 'Назад',
          showDivider: false,
          isBackEnabled: !state.disconnectStatus.isLoading,
          onBack: () => context.pop(),
          action: channel == null
              ? null
              : _ChannelMoreButton(
                  channel: channel,
                  isEnabled: !state.isBusy,
                  selectedPropertyId: selectedPropertyId,
                  onCopy: onCopy,
                ),
        );
      },
    );
  }
}

/// The ⋯ menu: copying the shown import link, and disconnecting.
final class _ChannelMoreButton extends StatelessWidget {
  const _ChannelMoreButton({
    required this.channel,
    required this.isEnabled,
    required this.selectedPropertyId,
    required this.onCopy,
  });

  final ChannelEntity channel;
  final bool isEnabled;
  final ValueListenable<String?> selectedPropertyId;
  final Future<void> Function(String url) onCopy;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      semanticLabel: 'Ещё',
      onPressed: isEnabled ? () => _showMore(context) : null,
      icon: SvgPicture.asset(
        AppAssets.icons.moreHorizontal,
        width: AppSizes.iconAppBar,
        height: AppSizes.iconAppBar,
      ),
    );
  }

  Future<void> _showMore(BuildContext context) async {
    final ChannelConnectionEntity? selected = _selectedConnection(
      channel,
      selectedPropertyId.value,
    );
    final _ChannelMenuAction? action =
        await showModalBottomSheet<_ChannelMenuAction>(
          context: context,
          useRootNavigator: true,
          builder: (BuildContext sheetContext) => _ChannelMoreSheet(
            importTitle: selected?.title,
            canDisconnect: channel.status != ChannelStatus.disconnected,
          ),
        );
    if (!context.mounted) {
      return;
    }
    switch (action) {
      case _ChannelMenuAction.copyImportUrl when selected != null:
        await onCopy(selected.importUrl);
      case _ChannelMenuAction.disconnect:
        await _confirmDisconnect(context, channel);
      case _ChannelMenuAction.copyImportUrl || null:
        break;
    }
  }
}

/// The ⋯ menu's items; pops with the chosen action.
final class _ChannelMoreSheet extends StatelessWidget {
  const _ChannelMoreSheet({
    required this.importTitle,
    required this.canDisconnect,
  });

  /// The shown calendar's title; hides «Скопировать ссылку импорта» when
  /// `null`.
  final String? importTitle;
  final bool canDisconnect;

  @override
  Widget build(BuildContext context) {
    final String? importTitle = this.importTitle;
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
            if (importTitle != null)
              AppProfileMenuItem(
                title: 'Скопировать ссылку импорта',
                subtitle: importTitle,
                onTap: () => Navigator.of(
                  context,
                ).pop(_ChannelMenuAction.copyImportUrl),
              ),
            if (canDisconnect)
              AppProfileMenuItem(
                title: 'Отключить канал',
                subtitle: 'Календарь перестанет синхронизироваться',
                showDivider: false,
                onTap: () =>
                    Navigator.of(context).pop(_ChannelMenuAction.disconnect),
              ),
          ],
        ),
      ),
    );
  }
}

/// The channel, or before it arrives its skeleton or the error.
final class _ChannelBody extends StatelessWidget {
  const _ChannelBody({
    required this.selectedPropertyId,
    required this.onPropertySelected,
    required this.onCopy,
  });

  final ValueListenable<String?> selectedPropertyId;
  final ValueChanged<String> onPropertySelected;
  final Future<void> Function(String url) onCopy;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      buildWhen: (ChannelState previous, ChannelState current) =>
          previous.channel != current.channel ||
          previous.loadFailure != current.loadFailure ||
          previous.channelId != current.channelId,
      builder: (BuildContext context, ChannelState state) {
        final ChannelEntity? channel = state.channel;
        if (channel == null) {
          return _ChannelPlaceholder(
            failure: state.loadFailure,
            channelId: state.channelId,
          );
        }
        return ValueListenableBuilder<String?>(
          valueListenable: selectedPropertyId,
          builder: (BuildContext context, String? propertyId, Widget? _) {
            return _ChannelDetails(
              channel: channel,
              selectedPropertyId: propertyId,
              onPropertySelected: onPropertySelected,
              onCopy: onCopy,
            );
          },
        );
      },
    );
  }
}

final class _ChannelPlaceholder extends StatelessWidget {
  const _ChannelPlaceholder({required this.failure, required this.channelId});

  final Failure? failure;

  /// The requested channel, for retrying.
  final String channelId;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    if (failure == null) {
      return const _ChannelSkeleton();
    }
    final bool isMissing =
        failure is ServerFailure && failure.statusCode == 404;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        if (isMissing)
          AppEmptyState(
            title: 'Канал не найден',
            message: 'Возможно, его удалили или ссылка устарела',
            icon: SvgPicture.asset(AppAssets.icons.calendarGrid),
          )
        else
          AppEmptyState(
            title: 'Не удалось загрузить канал',
            message: failure.userMessage,
            icon: SvgPicture.asset(AppAssets.icons.alertCircle),
            actionLabel: 'Повторить',
            onAction: () => context.read<ChannelBloc>().add(
              ChannelRequested(channelId),
            ),
          ),
      ],
    );
  }
}

final class _ChannelDetails extends StatelessWidget {
  const _ChannelDetails({
    required this.channel,
    required this.selectedPropertyId,
    required this.onPropertySelected,
    required this.onCopy,
  });

  final ChannelEntity channel;
  final String? selectedPropertyId;
  final ValueChanged<String> onPropertySelected;
  final Future<void> Function(String url) onCopy;

  @override
  Widget build(BuildContext context) {
    final ChannelConnectionEntity? selected = _selectedConnection(
      channel,
      selectedPropertyId,
    );
    final Color statusColor = switch (channel.status) {
      ChannelStatus.connected => AppColors.success,
      ChannelStatus.failed => AppColors.error,
      ChannelStatus.manual ||
      ChannelStatus.disconnected => AppColors.secondaryText,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        20,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            ChannelLogo.large(initial: channel.initial),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    channel.name,
                    style: AppTypography.smallScreenTitle.copyWith(
                      letterSpacing: 0,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    channel.detailSubtitle,
                    style: AppTypography.compactBody.copyWith(
                      height: 16 / 13,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          channel.lastSyncLabel(now: channel.receivedAt),
          style: AppTypography.compactBody.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        if (channel.status == ChannelStatus.disconnected) ...<Widget>[
          const SizedBox(height: AppSpacing.large),
          const AppCallout(
            title: 'Канал отключён',
            message:
                'Брони с этой площадки больше не попадают в календарь, '
                'а EasyBooking не передаёт ей занятость.',
            tone: AppFeedbackTone.info,
          ),
        ],
        if (selected != null) ...<Widget>[
          const SizedBox(height: 18),
          _SectionTitle(title: 'Календарь ${selected.title}'),
          ChannelLinkField(label: 'Импорт занятости', url: selected.importUrl),
          const SizedBox(height: 10),
          Text(
            channel.checkIntervalLabel,
            style: AppTypography.caption.copyWith(
              height: 18 / 12,
              color: AppColors.secondaryText,
            ),
          ),
          if (selected.exportUrl case final String exportUrl) ...<Widget>[
            const SizedBox(height: 14),
            ChannelLinkField(label: 'Экспорт из EasyBooking', url: exportUrl),
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.touchTarget,
                ),
                child: Center(
                  widthFactor: 1,
                  child: AppTextButton.underlined(
                    label: 'Скопировать ссылку',
                    onPressed: () => onCopy(exportUrl),
                  ),
                ),
              ),
            ),
          ],
        ],
        if (channel.connections.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.large),
          const _SectionTitle(title: 'Объекты'),
          for (final ChannelConnectionEntity connection in channel.connections)
            ChannelConnectionRow(
              title: connection.title,
              subtitle: connection.modeLabel,
              statusLabel: connection.statusLabel,
              isFailed: connection.isFailed,
              isSelected:
                  channel.connections.length > 1 &&
                  connection.propertyId == selected?.propertyId,
              onTap: () => onPropertySelected(connection.propertyId),
            ),
        ],
      ],
    );
  }
}

/// «Отключить» and «Синхронизировать сейчас», with the next check time.
final class _ChannelFooter extends StatelessWidget {
  const _ChannelFooter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      buildWhen: (ChannelState previous, ChannelState current) =>
          previous.channel != current.channel ||
          previous.syncStatus != current.syncStatus ||
          previous.disconnectStatus != current.disconnectStatus,
      builder: (BuildContext context, ChannelState state) {
        final ChannelEntity? channel = state.channel;
        // The scaffold only shows the footer for a loaded channel.
        if (channel == null) {
          return const SizedBox.shrink();
        }
        return CalendarDecisionFooter(
          message: channel.nextCheckLabel(now: channel.receivedAt),
          secondaryLabel: 'Отключить',
          onSecondaryPressed: state.isBusy
              ? null
              : () => _confirmDisconnect(context, channel),
          isSecondaryLoading: state.disconnectStatus.isLoading,
          primaryLabel: 'Синхронизировать сейчас',
          onPrimaryPressed: state.isBusy
              ? null
              : () => context.read<ChannelBloc>().add(
                  const ChannelSyncRequested(),
                ),
          isPrimaryLoading: state.syncStatus.isLoading,
        );
      },
    );
  }
}

enum _ChannelMenuAction { copyImportUrl, disconnect }

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Text(
        title,
        style: AppTypography.sectionTitle.copyWith(color: AppColors.text),
      ),
    );
  }
}

final class _ChannelSkeleton extends StatelessWidget {
  const _ChannelSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        20,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: const <Widget>[
        Row(
          children: <Widget>[
            AppSkeleton(height: 52, width: 52, borderRadius: AppRadii.media),
            SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSkeleton(height: 24, width: 140),
                  SizedBox(height: AppSpacing.small),
                  AppSkeleton(height: 14, width: 160),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xLarge),
        AppSkeleton(height: 20, width: 240),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 64, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 64, borderRadius: AppRadii.field),
      ],
    );
  }
}
