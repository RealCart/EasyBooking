import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/profile/domain/entity/active_session_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_event_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_security_overview_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/set_biometric_login_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/terminate_other_sessions_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/security_bloc/security_bloc.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_detail_layout.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_failure_message.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_list_row.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_section_label.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_toggle_row.dart';
import 'package:easy_booking/features/profile/presentation/widgets/security_labels.dart';

/// Screen 33 «Безопасность»: sign-in methods, the Face ID switch, active
/// sessions, and recent security events.
///
/// Provides its own [SecurityBloc] through [wrappedRoute].
final class SecurityScreen extends StatelessWidget implements GoRouterWrapper {
  const SecurityScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<SecurityBloc>(
      create: (_) => SecurityBloc(
        getSecurityOverview: dependencies.getDep<GetSecurityOverviewUsecase>(),
        setBiometricLogin: dependencies.getDep<SetBiometricLoginUsecase>(),
        terminateOtherSessions: dependencies
            .getDep<TerminateOtherSessionsUsecase>(),
      )..add(const SecurityRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<SecurityBloc, SecurityState>>[
        BlocListener<SecurityBloc, SecurityState>(
          listenWhen: (SecurityState previous, SecurityState current) =>
              previous.biometricFailure != current.biometricFailure &&
              current.biometricFailure != null,
          listener: (BuildContext context, SecurityState state) {
            context.showAppSnackbar(state.biometricFailure!.profileMessage);
          },
        ),
        BlocListener<SecurityBloc, SecurityState>(
          listenWhen: (SecurityState previous, SecurityState current) =>
              previous.terminateStatus != current.terminateStatus &&
              (current.terminateStatus.isSuccess ||
                  current.terminateStatus.isFailure),
          listener: (BuildContext context, SecurityState state) {
            final Failure? failure = state.terminateFailure;
            context.showAppSnackbar(
              failure == null
                  ? 'Другие сеансы завершены'
                  : failure.profileMessage,
            );
          },
        ),
        // Only a failed refresh: the first failure replaces the overview.
        BlocListener<SecurityBloc, SecurityState>(
          listenWhen: (SecurityState previous, SecurityState current) =>
              previous.loadStatus != current.loadStatus &&
              current.loadStatus.isFailure &&
              current.overview != null,
          listener: (BuildContext context, SecurityState state) {
            context.showAppSnackbar(state.loadFailure!.profileMessage);
          },
        ),
      ],
      child: const ProfileDetailLayout(
        title: 'Безопасность',
        body: _SecurityBody(),
        footer: _SecurityFooter(),
      ),
    );
  }
}

/// «Проверить безопасность», enabled once the overview is loaded.
final class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SecurityBloc, SecurityState, bool>(
      selector: (SecurityState state) => state.overview != null,
      builder: (BuildContext context, bool hasOverview) {
        return AppFlowFooter(
          primaryLabel: 'Проверить безопасность',
          onPrimaryPressed: hasOverview ? context.showComingSoon : null,
        );
      },
    );
  }
}

/// The skeleton or the load error until the overview is loaded, then the
/// overview.
final class _SecurityBody extends StatelessWidget {
  const _SecurityBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityBloc, SecurityState>(
      buildWhen: (SecurityState previous, SecurityState current) =>
          previous.overview != current.overview ||
          (current.overview == null &&
              previous.loadFailure != current.loadFailure),
      builder: (BuildContext context, SecurityState state) {
        final SecurityOverviewEntity? overview = state.overview;
        if (overview != null) {
          return _SecurityOverviewList(overview: overview);
        }
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          return ProfileLoadError(
            title: 'Не удалось загрузить настройки',
            failure: failure,
            onRetry: () =>
                context.read<SecurityBloc>().add(const SecurityRequested()),
          );
        }
        return const ProfileListSkeleton();
      },
    );
  }
}

/// Sign-in methods, sessions, and recent events, with pull-to-refresh.
final class _SecurityOverviewList extends StatelessWidget {
  const _SecurityOverviewList({required this.overview});

  final SecurityOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final DateTime now = overview.receivedAt;
    final List<ActiveSessionEntity> otherSessions = overview.otherSessions;

    return RefreshIndicator.adaptive(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
        children: <Widget>[
          const ProfileSectionLabel(label: 'Вход', isFirst: true),
          ProfileListRow(
            title: 'Номер телефона',
            subtitle: overview.phoneLabel,
            leading: const ProfileRowTile(size: 38, child: Text('№')),
            trailing: const ProfileChevron(),
            onTap: context.showComingSoon,
          ),
          ProfileListRow(
            title: 'Код приложения',
            subtitle: overview.appCodeLabel,
            leading: const ProfileRowTile(size: 38, child: Text('••')),
            trailing: const ProfileChevron(),
            onTap: context.showComingSoon,
          ),
          _BiometricLoginRow(isEnabled: overview.isBiometricLoginEnabled),
          ProfileSectionLabel(
            label: 'Активные сеансы · ${overview.sessions.length}',
          ),
          for (final ActiveSessionEntity session in overview.sessions)
            ProfileListRow(
              title: session.deviceName,
              subtitle: session.activityLabel,
              leading: ProfileRowTile(
                child: _SessionDeviceIcon(type: session.deviceType),
              ),
              trailing: session.isCurrent
                  ? const ProfileTrailingLabel(
                      label: 'Этот',
                      color: AppColors.success,
                    )
                  : const ProfileChevron(),
              onTap: session.isCurrent ? null : context.showComingSoon,
            ),
          if (overview.recentEvents.isNotEmpty) ...<Widget>[
            const ProfileSectionLabel(label: 'Последние действия'),
            for (final SecurityEventEntity event in overview.recentEvents)
              _SecurityEventRow(event: event, now: now),
          ],
          if (otherSessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pageGutter,
                22,
                AppSizes.pageGutter,
                0,
              ),
              child: _TerminateSessionsButton(
                hint: overview.terminateOthersHint,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context) {
    final SecurityBloc bloc = context.read<SecurityBloc>();
    bloc.add(const SecurityRequested());
    return bloc.stream.firstWhere(
      (SecurityState state) => !state.loadStatus.isLoading,
    );
  }
}

/// «Вход по Face ID»; shows the saved value and is disabled while the
/// change is written.
final class _BiometricLoginRow extends StatelessWidget {
  const _BiometricLoginRow({required this.isEnabled});

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SecurityBloc, SecurityState, bool>(
      selector: (SecurityState state) => state.biometricStatus.isLoading,
      builder: (BuildContext context, bool isWriting) {
        return ProfileToggleRow(
          title: 'Вход по Face ID',
          subtitle: 'Подтверждать открытие договоров',
          value: isEnabled,
          onChanged: isWriting
              ? null
              : (bool isEnabled) => context.read<SecurityBloc>().add(
                  SecurityBiometricLoginToggled(isEnabled: isEnabled),
                ),
        );
      },
    );
  }
}

/// [_TerminateSessionsAction], disabled while the sessions are terminated.
final class _TerminateSessionsButton extends StatelessWidget {
  const _TerminateSessionsButton({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SecurityBloc, SecurityState, bool>(
      selector: (SecurityState state) => state.terminateStatus.isLoading,
      builder: (BuildContext context, bool isTerminating) {
        return _TerminateSessionsAction(
          hint: hint,
          onPressed: isTerminating ? null : () => _confirmTerminate(context),
        );
      },
    );
  }

  Future<void> _confirmTerminate(BuildContext context) async {
    final SecurityBloc bloc = context.read<SecurityBloc>();
    final bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppConfirmationDialog(
          title: 'Завершить другие сеансы?',
          message: 'На других устройствах понадобится войти снова.',
          cancelLabel: 'Отмена',
          confirmLabel: 'Завершить',
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    if (isConfirmed ?? false) {
      bloc.add(const SecurityOtherSessionsTerminateRequested());
    }
  }
}

final class _SessionDeviceIcon extends StatelessWidget {
  const _SessionDeviceIcon({required this.type});

  static const double _size = 19;

  final SessionDeviceType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      SessionDeviceType.phone => SvgPicture.asset(
        AppAssets.icons.phone,
        width: _size,
        height: _size,
      ),
      SessionDeviceType.tablet => const Icon(
        Icons.tablet_mac_outlined,
        size: _size,
        color: AppColors.text,
      ),
      SessionDeviceType.computer => const Icon(
        Icons.laptop_mac_outlined,
        size: _size,
        color: AppColors.text,
      ),
    };
  }
}

/// A «Последние действия» row: a status dot, the event, and when it was.
final class _SecurityEventRow extends StatelessWidget {
  const _SecurityEventRow({required this.event, required this.now});

  static const double _dotSize = 8;

  final SecurityEventEntity event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = switch (event.kind) {
      SecurityEventKind.signedIn => AppColors.success,
      SecurityEventKind.appCodeChanged => AppColors.border,
      SecurityEventKind.otherSessionsTerminated => AppColors.warning,
    };

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pageGutter,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: SizedBox.square(
                dimension: _dotSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: <Widget>[
                  Text(
                    event.title,
                    style: AppTypography.compactBody.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 16 / 13,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    event.subtitle(now: now),
                    style: AppTypography.caption.copyWith(
                      height: 16 / 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Завершить другие сеансы» in the error color, with what it will do.
final class _TerminateSessionsAction extends StatelessWidget {
  const _TerminateSessionsAction({required this.hint, required this.onPressed});

  final String hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onPressed = this.onPressed;
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Opacity(
            opacity: onPressed == null ? 0.4 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xSmall,
                children: <Widget>[
                  Text(
                    'Завершить другие сеансы',
                    style: AppTypography.compactBody.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 16 / 13,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    hint,
                    style: AppTypography.caption.copyWith(
                      height: 18 / 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
