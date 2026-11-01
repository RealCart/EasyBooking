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
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_large_listing_card.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_property_row.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_search_field.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_list_options.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/properties_bloc/properties_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_labels.dart';

/// Screen 02 «Ваши объекты»: every property, searched, filtered by
/// availability, and sorted. The first result is shown large.
///
/// Provides its own [PropertiesBloc] through [wrappedRoute].
final class PropertiesScreen extends StatelessWidget
    implements GoRouterWrapper {
  const PropertiesScreen({super.key});

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
        child: BlocListener<PropertiesBloc, PropertiesState>(
          // A failed favorite write, or a failed refresh: the first load
          // failure is shown in place of the list.
          listenWhen: (PropertiesState previous, PropertiesState current) =>
              (previous.favoriteFailure != current.favoriteFailure &&
                  current.favoriteFailure != null) ||
              (previous.loadStatus != current.loadStatus &&
                  current.loadStatus.isFailure &&
                  current.properties.isNotEmpty),
          listener: (BuildContext context, PropertiesState state) {
            final Failure? failure = state.favoriteFailure ?? state.loadFailure;
            if (failure != null) {
              context.showAppSnackbar(failure.userMessage);
            }
          },
          child: RefreshIndicator.adaptive(
            onRefresh: () {
              final PropertiesBloc bloc = context.read<PropertiesBloc>();
              bloc.add(const PropertiesRequested());
              return bloc.stream.firstWhere(
                (PropertiesState state) => !state.loadStatus.isLoading,
              );
            },
            child: const _PropertiesList(),
          ),
        ),
      ),
    );
  }
}

void _openProperty(BuildContext context, String propertyId) {
  _open(
    context,
    AppRoutes.property.name,
    pathParameters: <String, String>{AppRoutes.propertyIdParam: propertyId},
  );
}

/// Pushes [routeName] and reloads on return, so hearts changed there show
/// here.
Future<void> _open(
  BuildContext context,
  String routeName, {
  Map<String, String> pathParameters = const <String, String>{},
}) async {
  final PropertiesBloc bloc = context.read<PropertiesBloc>();
  await context.pushNamed<void>(routeName, pathParameters: pathParameters);
  if (!bloc.isClosed) {
    bloc.add(const PropertiesRequested());
  }
}

/// Opens the sort sheet with the current sort checked.
Future<void> _chooseSort(BuildContext context) async {
  final PropertiesBloc bloc = context.read<PropertiesBloc>();
  final PropertySort current = bloc.state.sort;
  final PropertySort? sort = await showModalBottomSheet<PropertySort>(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext sheetContext) => _SortSheet(current: current),
  );
  if (sort != null && !bloc.isClosed) {
    bloc.add(PropertiesSortSelected(sort));
  }
}

/// The scrollable page: the header, then the skeleton, the first load
/// failure, or the search, the filter chips, and the results.
///
/// The header, search, and chips are `const` and select their own data, so
/// they are skipped when the results rebuild.
final class _PropertiesList extends StatelessWidget {
  const _PropertiesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesBloc, PropertiesState>(
      // `hasLoaded` and `visibleProperties` derive from these fields only.
      buildWhen: (PropertiesState previous, PropertiesState current) =>
          previous.loadStatus.isSuccess != current.loadStatus.isSuccess ||
          previous.properties != current.properties ||
          previous.loadFailure != current.loadFailure ||
          previous.filter != current.filter ||
          previous.query != current.query ||
          previous.sort != current.sort,
      builder: (BuildContext context, PropertiesState state) {
        final Failure? failure = state.loadFailure;
        final List<PropertyEntity> properties = state.hasLoaded
            ? state.visibleProperties
            : const <PropertyEntity>[];
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
          children: <Widget>[
            const _PropertiesHeader(),
            if (!state.hasLoaded)
              if (failure != null)
                _PropertiesLoadError(failure: failure)
              else
                const _PropertiesSkeleton()
            else ...<Widget>[
              const _SearchRow(),
              const _FilterChips(),
              if (properties.isEmpty)
                _EmptyResults(
                  hasQuery: state.query.trim().isNotEmpty,
                  filter: state.filter,
                )
              else
                for (int index = 0; index < properties.length; index++)
                  _PropertyItem(property: properties[index], index: index),
            ],
          ],
        );
      },
    );
  }
}

/// «Ваши объекты» with the favorites button; follows the subtitle only.
final class _PropertiesHeader extends StatelessWidget {
  const _PropertiesHeader();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PropertiesBloc, PropertiesState, String?>(
      selector: (PropertiesState state) =>
          state.hasLoaded ? _subtitle(state) : null,
      builder: (BuildContext context, String? subtitle) {
        return AppRootHeader(
          title: 'Ваши объекты',
          subtitle: subtitle,
          action: AppIconButton(
            semanticLabel: 'Избранные',
            onPressed: () => _open(context, AppRoutes.favoriteProperties.name),
            icon: SvgPicture.asset(
              AppAssets.icons.heart,
              width: AppSizes.iconAppBar,
              height: AppSizes.iconAppBar,
            ),
          ),
        );
      },
    );
  }

  /// `4 квартиры в Алматы`, or just the count when the cities differ.
  static String _subtitle(PropertiesState state) {
    final int count = state.properties.length;
    final String apartments = Plural.format(
      count,
      one: 'квартира',
      few: 'квартиры',
      many: 'квартир',
    );
    final Set<String> cities = <String>{
      for (final PropertyEntity property in state.properties) property.city,
    };
    return cities.length == 1 ? '$apartments в ${cities.single}' : apartments;
  }
}

/// The first load failure with «Повторить».
final class _PropertiesLoadError extends StatelessWidget {
  const _PropertiesLoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: AppEmptyState(
        title: 'Не удалось загрузить объекты',
        message: failure.userMessage,
        icon: SvgPicture.asset(AppAssets.icons.alertCircle),
        actionLabel: 'Повторить',
        onAction: () =>
            context.read<PropertiesBloc>().add(const PropertiesRequested()),
      ),
    );
  }
}

/// The search field and the sort button; reads no state.
final class _SearchRow extends StatelessWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: Row(
        crossAxisAlignment: .start,
        children: <Widget>[
          Expanded(
            child: AppSearchField(
              hint: 'Найти квартиру',
              subtitle: 'Название или адрес',
              clearSemanticLabel: 'Очистить поиск',
              onChanged: (String query) => context.read<PropertiesBloc>().add(
                PropertiesQueryChanged(query),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          _SortButton(onPressed: () => _chooseSort(context)),
        ],
      ),
    );
  }
}

/// The availability chips with their counts; follows the properties and
/// the selected filter only.
final class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesBloc, PropertiesState>(
      buildWhen: (PropertiesState previous, PropertiesState current) =>
          previous.properties != current.properties ||
          previous.filter != current.filter,
      builder: (BuildContext context, PropertiesState state) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: AppScopeFilter(
            labels: <String>[
              for (final PropertiesFilter filter in PropertiesFilter.values)
                '${filter.label} · ${state.countFor(filter)}',
            ],
            selectedIndex: state.filter.index,
            onSelected: (int index) => context.read<PropertiesBloc>().add(
              PropertiesFilterSelected(PropertiesFilter.values[index]),
            ),
          ),
        );
      },
    );
  }
}

/// No result: for the search when there is a query, else for the filter.
final class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.hasQuery, required this.filter});

  final bool hasQuery;
  final PropertiesFilter filter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: hasQuery
          ? const AppEmptyState(
              title: 'Ничего не нашли',
              message: 'Проверьте название или адрес',
            )
          : AppEmptyState(
              title: filter.emptyTitle,
              message: 'Попробуйте другой фильтр',
              icon: SvgPicture.asset(AppAssets.icons.building),
            ),
    );
  }
}

/// A result: the first one as a large card, the others as rows.
final class _PropertyItem extends StatelessWidget {
  const _PropertyItem({required this.property, required this.index});

  final PropertyEntity property;

  /// The position in the results; sets the layout and the top spacing.
  final int index;

  @override
  Widget build(BuildContext context) {
    void toggleFavorite() => context.read<PropertiesBloc>().add(
      PropertyFavoriteToggled(property.id),
    );
    void open() => _openProperty(context, property.id);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        index == 0 ? 0 : (index == 1 ? AppSpacing.xLarge : AppSpacing.large),
        AppSizes.pageGutter,
        0,
      ),
      child: index == 0
          ? AppLargeListingCard(
              title: property.fullTitle,
              imageUrl: property.imageUrls.first,
              subtitle: property.addressWithRooms,
              details: property.syncDetails,
              price: property.price,
              unitLabel: 'за ночь',
              badgeLabel: property.availability.badge,
              isSaved: property.isFavorite,
              onSavedPressed: toggleFavorite,
              onTap: open,
            )
          : AppPropertyRow(
              title: property.shortTitle,
              imageUrl: property.imageUrls.first,
              subtitle: property.addressWithRooms,
              status: property.availability.status(),
              price: property.price,
              unitLabel: 'ночь',
              showDivider: false,
              isSaved: property.isFavorite,
              onSavedPressed: toggleFavorite,
              onTap: open,
            ),
    );
  }
}

/// The sort options, with [current] checked; pops the chosen one.
final class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});

  final PropertySort current;

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
            for (final PropertySort sort in PropertySort.values)
              AppProfileMenuItem(
                title: sort.label,
                showDivider: sort != PropertySort.values.last,
                trailing: sort == current
                    ? SvgPicture.asset(
                        AppAssets.icons.checkSmall,
                        width: AppSizes.iconAction,
                        height: AppSizes.iconAction,
                      )
                    : const SizedBox.shrink(),
                onTap: () => Navigator.of(context).pop(sort),
              ),
          ],
        ),
      ),
    );
  }
}

/// The 48 px outlined sliders button next to the search field.
final class _SortButton extends StatelessWidget {
  const _SortButton({required this.onPressed});

  static const double _size = 48;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: 'Сортировка',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: ExcludeSemantics(
            child: SvgPicture.asset(
              AppAssets.icons.sliders,
              width: AppSizes.iconAction,
              height: AppSizes.iconAction,
            ),
          ),
        ),
      ),
    );
  }
}

final class _PropertiesSkeleton extends StatelessWidget {
  const _PropertiesSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSkeleton(height: 66),
          SizedBox(height: 20),
          Row(
            children: <Widget>[
              AppSkeleton(height: 36, width: 76),
              SizedBox(width: AppSpacing.small),
              AppSkeleton(height: 36, width: 112),
              SizedBox(width: AppSpacing.small),
              AppSkeleton(height: 36, width: 100),
            ],
          ),
          SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 382 / 210,
            child: AppSkeleton(
              height: double.infinity,
              borderRadius: AppRadii.card,
            ),
          ),
          SizedBox(height: AppSpacing.large),
          AppSkeleton(height: 20, width: 220),
          SizedBox(height: AppSpacing.xLarge),
          AppSkeleton(height: 92, borderRadius: AppRadii.media),
        ],
      ),
    );
  }
}
