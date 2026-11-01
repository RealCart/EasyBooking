import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/notification_settings_bloc/notification_settings_bloc.dart';
import 'package:easy_booking/features/profile/presentation/widgets/notification_settings_labels.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_detail_layout.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_failure_message.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_section_label.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_toggle_row.dart';

/// Screen 32 «Настройки уведомлений»: topic switches and delivery channels.
/// Changes stay on the screen until «Сохранить настройки».
///
/// Provides its own [NotificationSettingsBloc] through [wrappedRoute].
final class NotificationSettingsScreen extends StatefulWidget
    implements GoRouterWrapper {
  const NotificationSettingsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<NotificationSettingsBloc>(
      create: (_) => NotificationSettingsBloc(
        getNotificationSettings: dependencies
            .getDep<GetNotificationSettingsUsecase>(),
        updateNotificationSettings: dependencies
            .getDep<UpdateNotificationSettingsUsecase>(),
      )..add(const NotificationSettingsRequested()),
      child: this,
    );
  }

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

final class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  /// The unsaved topics; `null` until the user changes one, so the saved
  /// settings are shown. Only the topic rows listen to it.
  late final ValueNotifier<Set<NotificationTopic>?> _draftTopics;

  /// The unsaved channels; `null` until the user changes one. Only the
  /// channel chips listen to it.
  late final ValueNotifier<Set<NotificationDeliveryChannel>?> _draftChannels;

  @override
  void initState() {
    super.initState();
    _draftTopics = ValueNotifier<Set<NotificationTopic>?>(null);
    _draftChannels = ValueNotifier<Set<NotificationDeliveryChannel>?>(null);
  }

  @override
  void dispose() {
    _draftTopics.dispose();
    _draftChannels.dispose();
    super.dispose();
  }

  void _submit() {
    final NotificationSettingsBloc bloc = context
        .read<NotificationSettingsBloc>();
    final NotificationSettingsEntity? settings = bloc.state.settings;
    if (settings == null) {
      return;
    }
    bloc.add(
      NotificationSettingsSubmitted(
        UpdateNotificationSettingsParamsEntity(
          enabledTopics: Set<NotificationTopic>.unmodifiable(
            _draftTopics.value ?? settings.enabledTopics,
          ),
          channels: Set<NotificationDeliveryChannel>.unmodifiable(
            _draftChannels.value ?? settings.channels,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationSettingsBloc, NotificationSettingsState>(
      listenWhen:
          (
            NotificationSettingsState previous,
            NotificationSettingsState current,
          ) =>
              previous.saveStatus != current.saveStatus &&
              (current.saveStatus.isSuccess || current.saveStatus.isFailure),
      listener: (BuildContext context, NotificationSettingsState state) {
        final Failure? failure = state.saveFailure;
        context.showAppSnackbar(
          failure == null ? 'Настройки сохранены' : failure.profileMessage,
        );
      },
      child: ProfileDetailLayout(
        title: 'Настройки уведомлений',
        body: _NotificationSettingsBody(
          draftTopics: _draftTopics,
          draftChannels: _draftChannels,
        ),
        footer: _SaveSettingsFooter(onSave: _submit),
      ),
    );
  }
}

/// «Сохранить настройки»: enabled once the settings are loaded, busy while
/// saving.
final class _SaveSettingsFooter extends StatelessWidget {
  const _SaveSettingsFooter({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      NotificationSettingsBloc,
      NotificationSettingsState,
      (bool, bool)
    >(
      selector: (NotificationSettingsState state) =>
          (state.settings != null, state.saveStatus.isLoading),
      builder: (BuildContext context, (bool, bool) saveState) {
        final (bool hasSettings, bool isSaving) = saveState;
        return AppFlowFooter(
          primaryLabel: 'Сохранить настройки',
          onPrimaryPressed: !hasSettings || isSaving ? null : onSave,
          primaryLoading: isSaving,
        );
      },
    );
  }
}

/// The skeleton or the load error until the settings are loaded, then the
/// topics and the channels.
final class _NotificationSettingsBody extends StatelessWidget {
  const _NotificationSettingsBody({
    required this.draftTopics,
    required this.draftChannels,
  });

  final ValueNotifier<Set<NotificationTopic>?> draftTopics;
  final ValueNotifier<Set<NotificationDeliveryChannel>?> draftChannels;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
      buildWhen:
          (
            NotificationSettingsState previous,
            NotificationSettingsState current,
          ) =>
              previous.settings != current.settings ||
              (current.settings == null &&
                  previous.loadFailure != current.loadFailure),
      builder: (BuildContext context, NotificationSettingsState state) {
        final NotificationSettingsEntity? settings = state.settings;
        if (settings != null) {
          return _NotificationSettingsList(
            settings: settings,
            draftTopics: draftTopics,
            draftChannels: draftChannels,
          );
        }
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          return ProfileLoadError(
            title: 'Не удалось загрузить настройки',
            failure: failure,
            onRetry: () => context.read<NotificationSettingsBloc>().add(
              const NotificationSettingsRequested(),
            ),
          );
        }
        return const ProfileListSkeleton(rowCount: 6);
      },
    );
  }
}

final class _NotificationSettingsList extends StatelessWidget {
  const _NotificationSettingsList({
    required this.settings,
    required this.draftTopics,
    required this.draftChannels,
  });

  final NotificationSettingsEntity settings;
  final ValueNotifier<Set<NotificationTopic>?> draftTopics;
  final ValueNotifier<Set<NotificationDeliveryChannel>?> draftChannels;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      children: <Widget>[
        for (
          int index = 0;
          index < notificationTopicGroups.length;
          index++
        ) ...<Widget>[
          ProfileSectionLabel(
            label: notificationTopicGroups[index].title,
            isFirst: index == 0,
          ),
          for (final NotificationTopic topic
              in notificationTopicGroups[index].topics)
            _TopicToggleRow(
              topic: topic,
              savedTopics: settings.enabledTopics,
              draftTopics: draftTopics,
            ),
        ],
        const ProfileSectionLabel(label: 'Каналы доставки'),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            10,
            AppSizes.pageGutter,
            18,
          ),
          child: _DeliveryChannelChips(
            savedChannels: settings.channels,
            draftChannels: draftChannels,
          ),
        ),
      ],
    );
  }
}

/// A topic switch; disabled while saving. Toggling changes only the draft.
final class _TopicToggleRow extends StatelessWidget {
  const _TopicToggleRow({
    required this.topic,
    required this.savedTopics,
    required this.draftTopics,
  });

  final NotificationTopic topic;
  final Set<NotificationTopic> savedTopics;
  final ValueNotifier<Set<NotificationTopic>?> draftTopics;

  void _toggle({required bool isEnabled}) {
    final Set<NotificationTopic> topics = Set<NotificationTopic>.of(
      draftTopics.value ?? savedTopics,
    );
    if (isEnabled) {
      topics.add(topic);
    } else {
      topics.remove(topic);
    }
    draftTopics.value = topics;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      NotificationSettingsBloc,
      NotificationSettingsState,
      bool
    >(
      selector: (NotificationSettingsState state) => state.saveStatus.isLoading,
      builder: (BuildContext context, bool isSaving) {
        return ValueListenableBuilder<Set<NotificationTopic>?>(
          valueListenable: draftTopics,
          builder: (BuildContext context, Set<NotificationTopic>? draft, _) {
            return ProfileToggleRow(
              title: topic.title,
              subtitle: topic.hint,
              value: (draft ?? savedTopics).contains(topic),
              onChanged: isSaving
                  ? null
                  : (bool isEnabled) => _toggle(isEnabled: isEnabled),
            );
          },
        );
      },
    );
  }
}

/// The delivery channel chips. Selecting changes only the draft, and is
/// ignored while saving.
final class _DeliveryChannelChips extends StatelessWidget {
  const _DeliveryChannelChips({
    required this.savedChannels,
    required this.draftChannels,
  });

  final Set<NotificationDeliveryChannel> savedChannels;
  final ValueNotifier<Set<NotificationDeliveryChannel>?> draftChannels;

  void _toggle(
    BuildContext context,
    NotificationDeliveryChannel channel, {
    required bool isSelected,
  }) {
    if (context.read<NotificationSettingsBloc>().state.saveStatus.isLoading) {
      return;
    }
    final Set<NotificationDeliveryChannel> channels =
        Set<NotificationDeliveryChannel>.of(
          draftChannels.value ?? savedChannels,
        );
    if (isSelected) {
      channels.add(channel);
    } else {
      channels.remove(channel);
    }
    draftChannels.value = channels;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<NotificationDeliveryChannel>?>(
      valueListenable: draftChannels,
      builder:
          (
            BuildContext context,
            Set<NotificationDeliveryChannel>? draft,
            _,
          ) {
            final Set<NotificationDeliveryChannel> channels =
                draft ?? savedChannels;
            return Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: <Widget>[
                for (final NotificationDeliveryChannel channel
                    in NotificationDeliveryChannel.values)
                  Semantics(
                    button: true,
                    selected: channels.contains(channel),
                    label: channel.label,
                    child: AppChoiceChip(
                      label: channel.label,
                      isSelected: channels.contains(channel),
                      onSelected: (bool isSelected) =>
                          _toggle(context, channel, isSelected: isSelected),
                    ),
                  ),
              ],
            );
          },
    );
  }
}
