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
import 'package:easy_booking/core/presentation/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/properties_bloc/properties_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/favorite_property_card.dart';

/// Screen 04 «Избранные»: the favorite properties in a grid. Removing the
/// heart removes a property from here, not from the list.
///
/// Provides its own [PropertiesBloc] through [wrappedRoute].
final class FavoritePropertiesScreen extends StatelessWidget
    implements GoRouterWrapper {
  const FavoritePropertiesScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<PropertiesBloc>(
      create: (_) => PropertiesBloc(
        getProperties: dependencies.getDep<GetPropertiesUsecase>(),
        setFavorite: dependencies.getDep<SetPropertyFavoriteUsecase>(),
      )..add(const PropertiesRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppDetailHeader(
              title: 'Избранные',
              backSemanticLabel: 'Назад',
              showDivider: false,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: BlocListener<PropertiesBloc, PropertiesState>(
                listenWhen:
                    (PropertiesState previous, PropertiesState current) =>
                        previous.favoriteFailure != current.favoriteFailure &&
                        current.favoriteFailure != null,
                listener: (BuildContext context, PropertiesState state) {
                  context.showAppSnackbar(state.favoriteFailure!.userMessage);
                },
                child: const _FavoritesBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openProperty(BuildContext context, String propertyId) async {
  final PropertiesBloc bloc = context.read<PropertiesBloc>();
  await context.pushNamed<void>(
    AppRoutes.property.name,
    pathParameters: <String, String>{AppRoutes.propertyIdParam: propertyId},
  );
  if (!bloc.isClosed) {
    bloc.add(const PropertiesRequested());
  }
}

/// The skeleton, the first load failure, or the favorites.
final class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesBloc, PropertiesState>(
      // `hasLoaded` and `favorites` derive from these fields only.
      buildWhen: (PropertiesState previous, PropertiesState current) =>
          previous.loadStatus.isSuccess != current.loadStatus.isSuccess ||
          previous.properties != current.properties ||
          previous.loadFailure != current.loadFailure,
      builder: (BuildContext context, PropertiesState state) {
        if (state.hasLoaded) {
          return _FavoritesContent(favorites: state.favorites);
        }
        return _FavoritesPlaceholder(failure: state.loadFailure);
      },
    );
  }
}

/// The skeleton while loading, or the first load failure.
final class _FavoritesPlaceholder extends StatelessWidget {
  const _FavoritesPlaceholder({required this.failure});

  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        if (failure != null)
          AppEmptyState(
            title: 'Не удалось загрузить избранные',
            message: failure.userMessage,
            icon: SvgPicture.asset(AppAssets.icons.alertCircle),
            actionLabel: 'Повторить',
            onAction: () => context.read<PropertiesBloc>().add(
              const PropertiesRequested(),
            ),
          )
        else
          const _FavoritesSkeleton(),
      ],
    );
  }
}

/// The intro, the grid or its empty state, and the hint below.
final class _FavoritesContent extends StatelessWidget {
  const _FavoritesContent({required this.favorites});

  final List<PropertyEntity> favorites;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        AppSpacing.large,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: <Widget>[
        const _FavoritesIntroTitle(),
        const SizedBox(height: AppSpacing.small),
        const _FavoritesIntroText(),
        const SizedBox(height: AppSpacing.xLarge),
        if (favorites.isEmpty)
          AppEmptyState(
            title: 'Пока нет избранных',
            message: 'Отмечайте квартиры сердечком в списке объектов',
            icon: SvgPicture.asset(AppAssets.icons.heart),
          )
        else ...<Widget>[
          _FavoritesGrid(
            favorites: favorites,
            onOpen: (PropertyEntity property) =>
                _openProperty(context, property.id),
            onUnsave: (PropertyEntity property) => context
                .read<PropertiesBloc>()
                .add(PropertyFavoriteToggled(property.id)),
          ),
          const SizedBox(height: AppSpacing.xLarge),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          AppProfileMenuItem(
            title: 'Календарь избранных',
            subtitle: 'Занятость избранных квартир на одной шкале',
            leading: SvgPicture.asset(
              AppAssets.icons.calendarGrid,
              width: AppSizes.iconNavigation,
              height: AppSizes.iconNavigation,
            ),
            onTap: () => context.goNamed(AppRoutes.occupancy.name),
          ),
        ],
        const SizedBox(height: AppSpacing.xLarge),
        const _FavoritesHintTitle(),
        const SizedBox(height: AppSpacing.xSmall),
        const _FavoritesHintText(),
      ],
    );
  }
}

/// «Быстрый доступ».
final class _FavoritesIntroTitle extends StatelessWidget {
  const _FavoritesIntroTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Быстрый доступ',
      style: AppTypography.compactScreenTitle.copyWith(color: AppColors.text),
    );
  }
}

final class _FavoritesIntroText extends StatelessWidget {
  const _FavoritesIntroText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Квартиры, с которыми вы работаете чаще.',
      style: AppTypography.body.copyWith(color: AppColors.secondaryText),
    );
  }
}

/// «Добавляйте квартиры сердечком».
final class _FavoritesHintTitle extends StatelessWidget {
  const _FavoritesHintTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Добавляйте квартиры сердечком',
      style: AppTypography.body.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      ),
    );
  }
}

final class _FavoritesHintText extends StatelessWidget {
  const _FavoritesHintText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Они останутся в общем списке объектов.',
      style: AppTypography.compactBody.copyWith(color: AppColors.secondaryText),
    );
  }
}

/// Two columns; a row is as tall as its taller card.
final class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({
    required this.favorites,
    required this.onOpen,
    required this.onUnsave,
  });

  final List<PropertyEntity> favorites;
  final ValueChanged<PropertyEntity> onOpen;
  final ValueChanged<PropertyEntity> onUnsave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int start = 0; start < favorites.length; start += 2) ...<Widget>[
          if (start > 0) const SizedBox(height: AppSpacing.xLarge),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: FavoritePropertyCard(
                  property: favorites[start],
                  onTap: () => onOpen(favorites[start]),
                  onSavedPressed: () => onUnsave(favorites[start]),
                ),
              ),
              const SizedBox(width: AppSpacing.large),
              Expanded(
                child: start + 1 < favorites.length
                    ? FavoritePropertyCard(
                        property: favorites[start + 1],
                        onTap: () => onOpen(favorites[start + 1]),
                        onSavedPressed: () => onUnsave(favorites[start + 1]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

final class _FavoritesSkeleton extends StatelessWidget {
  const _FavoritesSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppSkeleton(height: 30, width: 200),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 18, width: 280),
        SizedBox(height: AppSpacing.xLarge),
        Row(
          children: <Widget>[
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: AppSkeleton(
                  height: double.infinity,
                  borderRadius: AppRadii.card,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.large),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: AppSkeleton(
                  height: double.infinity,
                  borderRadius: AppRadii.card,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
