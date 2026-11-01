import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_account_identity.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_workspace_summary.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/profile_bloc/profile_bloc.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_labels.dart';

enum _MoreAction { billing, signOut }

/// Screen 05 «Профиль»: the user, a workspace summary, and the settings
/// menu. The ⋯ menu holds billing and sign-out.
///
/// Provides its own [ProfileBloc] through [wrappedRoute].
final class ProfileScreen extends StatelessWidget implements GoRouterWrapper {
  const ProfileScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<ProfileBloc>(
      create: (_) => ProfileBloc(
        getProfile: dependencies.getDep<GetProfileUsecase>(),
        signOut: dependencies.getDep<SignOutUsecase>(),
      )..add(const ProfileRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (ProfileState previous, ProfileState current) =>
              (previous.signOutStatus != current.signOutStatus &&
                  current.signOutStatus.isFailure) ||
              (previous.loadStatus != current.loadStatus &&
                  current.loadStatus.isFailure &&
                  current.profile != null),
          listener: (BuildContext context, ProfileState state) {
            final Failure? failure = state.signOutStatus.isFailure
                ? state.signOutFailure
                : state.loadFailure;
            if (failure != null) {
              context.showAppSnackbar(failure.userMessage);
            }
          },
          child: RefreshIndicator.adaptive(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
              children: const <Widget>[
                AppRootHeader(title: 'Профиль', action: _MoreButton()),
                _ProfileSummary(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.pageGutter,
                    AppSpacing.medium,
                    AppSizes.pageGutter,
                    0,
                  ),
                  child: _ProfileMenu(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) {
    final ProfileBloc bloc = context.read<ProfileBloc>();
    bloc.add(const ProfileRequested());
    return bloc.stream.firstWhere(
      (ProfileState state) => !state.loadStatus.isLoading,
    );
  }
}

/// The ⋯ header action; disabled while signing out.
final class _MoreButton extends StatelessWidget {
  const _MoreButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileBloc, ProfileState, bool>(
      selector: (ProfileState state) => state.signOutStatus.isLoading,
      builder: (BuildContext context, bool isSigningOut) {
        return AppIconButton(
          semanticLabel: 'Ещё',
          onPressed: isSigningOut ? null : () => _showMore(context),
          icon: SvgPicture.asset(
            AppAssets.icons.moreHorizontal,
            width: AppSizes.iconAppBar,
            height: AppSizes.iconAppBar,
          ),
        );
      },
    );
  }

  Future<void> _showMore(BuildContext context) async {
    final ProfileBloc bloc = context.read<ProfileBloc>();
    final _MoreAction? action = await showModalBottomSheet<_MoreAction>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _MoreSheet(),
    );
    if (!context.mounted || action == null) {
      return;
    }
    switch (action) {
      case _MoreAction.billing:
        context.goNamed(AppRoutes.billing.name);
      case _MoreAction.signOut:
        final bool isConfirmed = await _confirmSignOut(context);
        if (isConfirmed) {
          bloc.add(const ProfileSignOutRequested());
        }
    }
  }

  Future<bool> _confirmSignOut(BuildContext context) async {
    final bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppConfirmationDialog(
          title: 'Выйти из аккаунта?',
          message: 'Чтобы войти снова, понадобится код из SMS.',
          cancelLabel: 'Отмена',
          confirmLabel: 'Выйти',
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    return isConfirmed ?? false;
  }
}

/// The ⋯ sheet: billing and sign-out. Pops with the chosen [_MoreAction].
final class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

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
              title: 'Тариф и оплата',
              subtitle: 'Pro, счета и способ оплаты',
              onTap: () => Navigator.of(context).pop(_MoreAction.billing),
            ),
            AppProfileMenuItem(
              title: 'Выйти из аккаунта',
              showDivider: false,
              trailing: const SizedBox.shrink(),
              onTap: () => Navigator.of(context).pop(_MoreAction.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

/// The identity and the workspace numbers, or their loading and error
/// states. The menu below works without them.
final class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        AppSpacing.small,
        AppSizes.pageGutter,
        0,
      ),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        buildWhen: (ProfileState previous, ProfileState current) =>
            previous.profile != current.profile ||
            previous.loadFailure != current.loadFailure,
        builder: (BuildContext context, ProfileState state) {
          final ProfileEntity? profile = state.profile;
          final Failure? failure = state.loadFailure;
          if (profile != null) {
            return _ProfileDetails(profile: profile);
          }
          if (failure != null) {
            return _ProfileLoadError(failure: failure);
          }
          return const _ProfileSkeleton();
        },
      ),
    );
  }
}

final class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppAccountIdentity(
          name: profile.fullName,
          details: profile.details,
          actionLabel: 'Редактировать профиль',
          onAction: () => _editProfile(context),
        ),
        const SizedBox(height: 28),
        AppWorkspaceSummary(metrics: profile.metrics),
      ],
    );
  }

  /// Pushed rather than gone to, so the profile reloads with the saved
  /// details when the user comes back.
  Future<void> _editProfile(BuildContext context) async {
    final ProfileBloc bloc = context.read<ProfileBloc>();
    await context.pushNamed<void>(AppRoutes.editProfile.name);
    if (!context.mounted) {
      return;
    }
    bloc.add(const ProfileRequested());
  }
}

final class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Не удалось загрузить профиль',
      message: failure.userMessage,
      icon: SvgPicture.asset(AppAssets.icons.alertCircle),
      actionLabel: 'Повторить',
      onAction: () => context.read<ProfileBloc>().add(const ProfileRequested()),
    );
  }
}

final class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppProfileMenuItem(
          title: 'Гости и договоры',
          subtitle: 'Документы, подписи, шаблоны',
          leading: _MenuIcon(path: AppAssets.icons.documentTextSmall),
          onTap: () => context.goNamed(AppRoutes.guests.name),
        ),
        AppProfileMenuItem(
          title: 'Команда и доступ',
          subtitle: 'Менеджеры и клинеры',
          leading: _MenuIcon(path: AppAssets.icons.users),
          onTap: () => context.goNamed(AppRoutes.team.name),
        ),
        AppProfileMenuItem(
          title: 'Уведомления',
          subtitle: 'Заезды, конфликты и подписи',
          leading: _MenuIcon(path: AppAssets.icons.notification),
          onTap: () => context.goNamed(AppRoutes.notificationSettings.name),
        ),
        AppProfileMenuItem(
          title: 'Безопасность',
          subtitle: 'Вход и защита документов',
          leading: _MenuIcon(path: AppAssets.icons.lock),
          onTap: () => context.goNamed(AppRoutes.security.name),
        ),
        AppProfileMenuItem(
          title: 'Помощь',
          subtitle: 'Поддержка и ответы на вопросы',
          leading: _MenuIcon(path: AppAssets.icons.helpCircle),
          onTap: () => context.goNamed(AppRoutes.help.name),
        ),
      ],
    );
  }
}

final class _MenuIcon extends StatelessWidget {
  const _MenuIcon({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: AppSizes.iconNavigation,
      height: AppSizes.iconNavigation,
    );
  }
}

final class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            AppSkeleton(height: 72, width: 72),
            SizedBox(width: AppSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSkeleton(height: 20, width: 190),
                  SizedBox(height: AppSpacing.small),
                  AppSkeleton(height: 16, width: 130),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 28),
        AppSkeleton(height: 96, borderRadius: AppRadii.media),
      ],
    );
  }
}
