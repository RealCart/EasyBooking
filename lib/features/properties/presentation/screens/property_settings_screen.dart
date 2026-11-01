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
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_property_settings_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_settings_bloc/property_settings_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_group_label.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_labels.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_management_labels.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_section_tabs.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_settings_row.dart';

/// Screen 29 «Объект · настройки»: a summary of the property's settings and
/// the «Принимать бронирования» switch, saved with «Сохранить изменения».
///
/// Provides its own [PropertySettingsBloc] through [wrappedRoute].
final class PropertySettingsScreen extends StatefulWidget
    implements GoRouterWrapper {
  const PropertySettingsScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<PropertySettingsBloc>(
      create: (_) => PropertySettingsBloc(
        getSettings: dependencies.getDep<GetPropertySettingsUsecase>(),
        saveSettings: dependencies.getDep<SavePropertySettingsUsecase>(),
      )..add(PropertySettingsRequested(propertyId)),
      child: this,
    );
  }

  @override
  State<PropertySettingsScreen> createState() => _PropertySettingsScreenState();
}

final class _PropertySettingsScreenState extends State<PropertySettingsScreen> {
  static const String _comingSoon = 'Скоро будет';

  /// The switch as the user set it; `null` until touched, so the stored
  /// value is shown. Listened to by the switch row only, so a toggle does
  /// not rebuild the screen.
  late final ValueNotifier<bool?> _acceptsBookings;

  @override
  void initState() {
    super.initState();
    _acceptsBookings = ValueNotifier<bool?>(null);
  }

  @override
  void dispose() {
    _acceptsBookings.dispose();
    super.dispose();
  }

  void _showComingSoon() => context.showAppSnackbar(_comingSoon);

  void _save() {
    final PropertySettingsBloc bloc = context.read<PropertySettingsBloc>();
    final PropertySettingsEntity? settings = bloc.state.settings;
    if (settings == null) {
      return;
    }
    bloc.add(
      PropertySettingsSubmitted(
        SavePropertySettingsParamsEntity(
          propertyId: widget.propertyId,
          acceptsBookings: _acceptsBookings.value ?? settings.acceptsBookings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertySettingsBloc, PropertySettingsState>(
      // The result of a save, as a one-off message.
      listenWhen:
          (PropertySettingsState previous, PropertySettingsState current) =>
              previous.saveStatus != current.saveStatus &&
              (current.saveStatus.isSuccess || current.saveStatus.isFailure),
      listener: (BuildContext context, PropertySettingsState state) {
        final Failure? failure = state.saveFailure;
        context.showAppSnackbar(
          failure == null ? 'Изменения сохранены' : failure.userMessage,
        );
      },
      // Rebuilds the frame once, when the settings arrive: the save footer
      // exists only then. The parts below select their own data.
      child: BlocSelector<PropertySettingsBloc, PropertySettingsState, bool>(
        selector: (PropertySettingsState state) => state.settings != null,
        builder: (BuildContext context, bool hasSettings) {
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SettingsHeader(onMorePressed: _showComingSoon),
                  PropertySectionTabs(
                    selected: PropertySection.settings,
                    onSelected: (PropertySection section) =>
                        openPropertySection(
                          context,
                          propertyId: widget.propertyId,
                          from: PropertySection.settings,
                          to: section,
                        ),
                  ),
                  Expanded(
                    child: hasSettings
                        ? _SettingsBody(
                            acceptsBookings: _acceptsBookings,
                            onComingSoon: _showComingSoon,
                          )
                        : const _SettingsPlaceholder(),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: hasSettings
                ? _SaveFooter(onPressed: _save)
                : null,
          );
        },
      ),
    );
  }
}

/// The header with «Ещё»; follows the property title only.
final class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onMorePressed});

  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PropertySettingsBloc, PropertySettingsState, String?>(
      selector: (PropertySettingsState state) =>
          state.settings?.property.shortTitle,
      builder: (BuildContext context, String? title) {
        return AppDetailHeader(
          title: title ?? 'Настройки',
          backSemanticLabel: 'Назад',
          showDivider: false,
          onBack: () => context.pop(),
          action: AppIconButton(
            semanticLabel: 'Ещё',
            onPressed: onMorePressed,
            icon: SvgPicture.asset(
              AppAssets.icons.moreHorizontal,
              width: AppSizes.iconAppBar,
              height: AppSizes.iconAppBar,
            ),
          ),
        );
      },
    );
  }
}

/// «Сохранить изменения»; follows the save status only.
final class _SaveFooter extends StatelessWidget {
  const _SaveFooter({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PropertySettingsBloc, PropertySettingsState, bool>(
      selector: (PropertySettingsState state) => state.saveStatus.isLoading,
      builder: (BuildContext context, bool isSaving) {
        return AppFlowFooter(
          primaryLabel: 'Сохранить изменения',
          primaryLoading: isSaving,
          onPrimaryPressed: onPressed,
        );
      },
    );
  }
}

/// The skeleton while loading, or the load failure.
final class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertySettingsBloc, PropertySettingsState>(
      buildWhen:
          (PropertySettingsState previous, PropertySettingsState current) =>
              previous.loadFailure != current.loadFailure ||
              previous.propertyId != current.propertyId,
      builder: (BuildContext context, PropertySettingsState state) {
        final Failure? failure = state.loadFailure;
        if (failure == null) {
          return const _SettingsSkeleton();
        }
        return _SettingsLoadError(
          failure: failure,
          propertyId: state.propertyId,
        );
      },
    );
  }
}

/// The first load failure with «Повторить».
final class _SettingsLoadError extends StatelessWidget {
  const _SettingsLoadError({required this.failure, required this.propertyId});

  final Failure failure;

  /// The requested property, for the retry.
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        AppEmptyState(
          title: 'Не удалось загрузить настройки',
          message: failure.userMessage,
          icon: SvgPicture.asset(AppAssets.icons.alertCircle),
          actionLabel: 'Повторить',
          onAction: () => context.read<PropertySettingsBloc>().add(
            PropertySettingsRequested(propertyId),
          ),
        ),
      ],
    );
  }
}

/// The loaded settings; follows the settings entity only.
final class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.acceptsBookings,
    required this.onComingSoon,
  });

  final ValueNotifier<bool?> acceptsBookings;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      PropertySettingsBloc,
      PropertySettingsState,
      PropertySettingsEntity?
    >(
      selector: (PropertySettingsState state) => state.settings,
      builder: (BuildContext context, PropertySettingsEntity? settings) {
        if (settings == null) {
          return const SizedBox.shrink();
        }
        return _SettingsList(
          settings: settings,
          acceptsBookings: acceptsBookings,
          onComingSoon: onComingSoon,
        );
      },
    );
  }
}

/// The settings summary rows and the «Принимать бронирования» switch.
final class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.settings,
    required this.acceptsBookings,
    required this.onComingSoon,
  });

  final PropertySettingsEntity settings;
  final ValueNotifier<bool?> acceptsBookings;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final int photoCount = settings.property.imageUrls.length;
    final List<String> channelNames = settings.property.channelNames;
    final int errorCount = settings.channelErrorCount;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            18,
            AppSizes.pageGutter,
            10,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Управление объектом',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                settings.acceptsBookings ? 'Активен' : 'Приостановлен',
                style: AppTypography.caption.copyWith(
                  color: settings.acceptsBookings
                      ? AppColors.success
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
        ),
        PropertySettingsRow(
          glyph: 'i',
          title: 'Основная информация',
          subtitle: '${settings.type.label} · ${settings.property.address}',
          onTap: onComingSoon,
        ),
        PropertySettingsRow(
          glyph: '$photoCount',
          title: 'Фотографии',
          subtitle: Plural.format(
            photoCount,
            one: 'фотография',
            few: 'фотографии',
            many: 'фотографий',
          ),
          trailingText: '$photoCount',
          onTap: onComingSoon,
        ),
        PropertySettingsRow(
          glyph: '₸',
          title: 'Цена и депозит',
          subtitle: settings.terms.priceAndDeposit,
          onTap: onComingSoon,
        ),
        PropertySettingsRow(
          glyph: '↔',
          title: 'Заезд и выезд',
          subtitle: settings.terms.checkInOut,
          onTap: onComingSoon,
        ),
        PropertySettingsRow(
          glyph: '✓',
          title: 'Правила проживания',
          subtitle: settings.houseRules.isEmpty
              ? 'Правила не заданы'
              : settings.houseRules.join(' · '),
          onTap: onComingSoon,
        ),
        PropertySettingsRow(
          glyph: '↻',
          title: 'Каналы',
          subtitle: _channelsSummary(channelNames, errorCount),
          trailingText: errorCount > 0 ? 'Проверить' : null,
          onTap: () => context.goNamed(AppRoutes.channels.name),
        ),
        const PropertyGroupLabel(label: 'ДОСТУП', topPadding: 22),
        PropertySettingsRow(
          glyph: '${settings.teamMemberCount}',
          title: 'Команда',
          subtitle: _teamSummary(settings.teamMemberCount),
          onTap: () => context.goNamed(AppRoutes.team.name),
        ),
        PropertySettingsRow(
          glyph: 'ID',
          title: 'Инструкции гостю',
          subtitle: settings.guestInstructionTopics.isEmpty
              ? 'Пока не заполнены'
              : settings.guestInstructionTopics.join(', '),
          onTap: onComingSoon,
        ),
        _AcceptsBookingsRow(
          storedValue: settings.acceptsBookings,
          acceptsBookings: acceptsBookings,
        ),
      ],
    );
  }

  /// `Airbnb, Booking.com · одна ошибка`
  static String _channelsSummary(List<String> channelNames, int errorCount) {
    final String channels = channelNames.isEmpty
        ? 'Площадки не подключены'
        : channelNames.join(', ');
    if (errorCount == 0) {
      return channels;
    }
    final String errors = errorCount == 1
        ? 'одна ошибка'
        : Plural.format(
            errorCount,
            one: 'ошибка',
            few: 'ошибки',
            many: 'ошибок',
          );
    return '$channels · $errors';
  }

  /// `2 участника имеют доступ`
  static String _teamSummary(int count) {
    final String members = Plural.format(
      count,
      one: 'участник',
      few: 'участника',
      many: 'участников',
    );
    final String verb = Plural.select(
      count,
      one: 'имеет',
      few: 'имеют',
      many: 'имеют',
    );
    return '$members $verb доступ';
  }
}

/// «Принимать бронирования»: the user's choice in [acceptsBookings], or
/// [storedValue] until the switch is touched.
final class _AcceptsBookingsRow extends StatelessWidget {
  const _AcceptsBookingsRow({
    required this.storedValue,
    required this.acceptsBookings,
  });

  final bool storedValue;
  final ValueNotifier<bool?> acceptsBookings;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pageGutter,
          vertical: 17,
        ),
        child: ValueListenableBuilder<bool?>(
          valueListenable: acceptsBookings,
          builder: (BuildContext context, bool? choice, Widget? child) {
            final bool value = choice ?? storedValue;
            return Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: <Widget>[
                      Text(
                        'Принимать бронирования',
                        style: AppTypography.action.copyWith(
                          color: AppColors.text,
                          height: 18 / 14,
                        ),
                      ),
                      Text(
                        value
                            ? 'Объект доступен во всех каналах'
                            : 'Новые брони не принимаются',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondaryText,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Switch(
                  value: value,
                  activeThumbColor: AppColors.background,
                  activeTrackColor: AppColors.text,
                  inactiveThumbColor: AppColors.background,
                  inactiveTrackColor: AppColors.border,
                  trackOutlineColor: const WidgetStatePropertyAll<Color>(
                    Colors.transparent,
                  ),
                  onChanged: (bool newValue) =>
                      acceptsBookings.value = newValue,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        18,
        AppSizes.pageGutter,
        0,
      ),
      children: <Widget>[
        const AppSkeleton(height: 22, width: 200),
        for (int index = 0; index < 6; index++) ...const <Widget>[
          SizedBox(height: AppSpacing.large),
          Row(
            children: <Widget>[
              AppSkeleton(height: 38, width: 38, borderRadius: AppRadii.field),
              SizedBox(width: AppSpacing.medium),
              Expanded(
                child: AppSkeleton(height: 34, borderRadius: AppRadii.field),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
