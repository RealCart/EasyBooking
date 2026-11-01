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
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_guest_booking_summary.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_section_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_sticky_action_bar.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_tabs.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/upcoming_stay_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_detail_bloc/property_detail_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_gallery.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_labels.dart';

/// Screen 03 «Ваш объект»: photos, the next arrival, and the connected
/// channels of one property. The other tabs open their own screens.
///
/// Provides its own [PropertyDetailBloc] through [wrappedRoute].
final class PropertyScreen extends StatelessWidget implements GoRouterWrapper {
  const PropertyScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<PropertyDetailBloc>(
      create: (_) => PropertyDetailBloc(
        getProperty: dependencies.getDep<GetPropertyUsecase>(),
        setFavorite: dependencies.getDep<SetPropertyFavoriteUsecase>(),
      )..add(PropertyDetailRequested(propertyId)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertyDetailBloc, PropertyDetailState>(
      listenWhen: (PropertyDetailState previous, PropertyDetailState current) =>
          previous.favoriteFailure != current.favoriteFailure &&
          current.favoriteFailure != null,
      listener: (BuildContext context, PropertyDetailState state) {
        context.showAppSnackbar(state.favoriteFailure!.userMessage);
      },
      // Rebuilds the frame once, when the property arrives: the «Изменить»
      // action and the rate bar exist only then. The parts below select
      // their own data.
      child: BlocSelector<PropertyDetailBloc, PropertyDetailState, bool>(
        selector: (PropertyDetailState state) => state.property != null,
        builder: (BuildContext context, bool hasProperty) {
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppDetailHeader(
                    title: 'Ваш объект',
                    backSemanticLabel: 'Назад',
                    showDivider: false,
                    onBack: () => context.pop(),
                    action: hasProperty
                        ? _EditButton(
                            onPressed: () => _openPropertyChild(
                              context,
                              AppRoutes.propertySettings,
                              propertyId: propertyId,
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: hasProperty
                        ? _PropertyDetails(propertyId: propertyId)
                        : const _PropertyPlaceholder(),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: hasProperty ? const _RateBar() : null,
          );
        },
      ),
    );
  }
}

/// Pushes the sibling section [route] of [propertyId].
void _openPropertyChild(
  BuildContext context,
  AppRoutes route, {
  required String propertyId,
}) {
  context.pushNamed(
    route.name,
    pathParameters: <String, String>{AppRoutes.propertyIdParam: propertyId},
  );
}

void _openBooking(BuildContext context, UpcomingStayEntity stay) {
  context.pushNamed(
    AppRoutes.booking.name,
    pathParameters: <String, String>{AppRoutes.bookingIdParam: stay.bookingId},
  );
}

/// «Изменить» in the header, with a full touch target.
final class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSizes.touchTarget,
        minHeight: AppSizes.touchTarget,
      ),
      child: Center(
        child: AppTextButton.underlined(
          label: 'Изменить',
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// The base price and «Календарь»; follows the price only.
final class _RateBar extends StatelessWidget {
  const _RateBar();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PropertyDetailBloc, PropertyDetailState, String?>(
      selector: (PropertyDetailState state) => state.property?.price,
      builder: (BuildContext context, String? rate) {
        if (rate == null) {
          return const SizedBox.shrink();
        }
        return AppStickyActionBar.rate(
          rate: rate,
          rateCaption: 'Базовая цена за ночь',
          primaryLabel: 'Календарь',
          onPrimaryPressed: () => context.goNamed(AppRoutes.calendar.name),
        );
      },
    );
  }
}

/// The skeleton while loading, or the load failure.
final class _PropertyPlaceholder extends StatelessWidget {
  const _PropertyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyDetailBloc, PropertyDetailState>(
      buildWhen: (PropertyDetailState previous, PropertyDetailState current) =>
          previous.loadFailure != current.loadFailure ||
          previous.propertyId != current.propertyId,
      builder: (BuildContext context, PropertyDetailState state) {
        final Failure? failure = state.loadFailure;
        if (failure == null) {
          return const _PropertySkeleton();
        }
        return _PropertyLoadError(
          failure: failure,
          propertyId: state.propertyId,
        );
      },
    );
  }
}

/// «Объект не найден» for a 404, otherwise the failure with «Повторить».
final class _PropertyLoadError extends StatelessWidget {
  const _PropertyLoadError({required this.failure, required this.propertyId});

  final Failure failure;

  /// The requested property, for the retry.
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final Failure failure = this.failure;
    final bool isMissing =
        failure is ServerFailure && failure.statusCode == 404;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        if (isMissing)
          AppEmptyState(
            title: 'Объект не найден',
            message: 'Возможно, его удалили или ссылка устарела',
            icon: SvgPicture.asset(AppAssets.icons.building),
          )
        else
          AppEmptyState(
            title: 'Не удалось загрузить объект',
            message: failure.userMessage,
            icon: SvgPicture.asset(AppAssets.icons.alertCircle),
            actionLabel: 'Повторить',
            onAction: () => context.read<PropertyDetailBloc>().add(
              PropertyDetailRequested(propertyId),
            ),
          ),
      ],
    );
  }
}

/// The loaded property; follows the property entity only.
final class _PropertyDetails extends StatelessWidget {
  const _PropertyDetails({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      PropertyDetailBloc,
      PropertyDetailState,
      PropertyEntity?
    >(
      selector: (PropertyDetailState state) => state.property,
      builder: (BuildContext context, PropertyEntity? property) {
        if (property == null) {
          return const SizedBox.shrink();
        }
        return _PropertyOverview(property: property, propertyId: propertyId);
      },
    );
  }
}

/// Photos, the title, the section tabs, the next arrival, and the channels.
final class _PropertyOverview extends StatelessWidget {
  const _PropertyOverview({required this.property, required this.propertyId});

  final PropertyEntity property;
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final UpcomingStayEntity? stay = property.upcomingStay;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
      children: <Widget>[
        PropertyGallery(
          imageUrls: property.imageUrls,
          isSaved: property.isFavorite,
          onSavedPressed: () => context.read<PropertyDetailBloc>().add(
            const PropertyDetailFavoriteToggled(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            AppSpacing.xLarge,
            AppSizes.pageGutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                property.fullTitle,
                style: AppTypography.compactScreenTitle.copyWith(
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                property.cityAddress,
                style: AppTypography.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                property.specs,
                style: AppTypography.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              AppTabs(
                labels: const <String>['Обзор', 'Бронирования', 'Настройки'],
                selectedIndex: 0,
                onSelected: (int index) {
                  switch (index) {
                    case 1:
                      _openPropertyChild(
                        context,
                        AppRoutes.propertyBookings,
                        propertyId: propertyId,
                      );
                    case 2:
                      _openPropertyChild(
                        context,
                        AppRoutes.propertySettings,
                        propertyId: propertyId,
                      );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xLarge),
              if (stay != null) ...<Widget>[
                AppSectionHeader(
                  title: 'Ближайший заезд',
                  actionLabel: 'Открыть',
                  onAction: () => _openBooking(context, stay),
                ),
                const SizedBox(height: AppSpacing.large),
                AppGuestBookingSummary(
                  guestName: stay.guestName,
                  stayDetails: stay.details,
                  trailingText: DateFormatter.time(stay.checkIn),
                  onTap: () => _openBooking(context, stay),
                ),
              ] else ...const <Widget>[
                AppSectionHeader(title: 'Ближайший заезд'),
                SizedBox(height: AppSpacing.small),
                _NoBookingsText(),
              ],
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _ChannelsSummary(
                property: property,
                onTap: () => context.goNamed(AppRoutes.channels.name),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// «Бронирований пока нет» under «Ближайший заезд».
final class _NoBookingsText extends StatelessWidget {
  const _NoBookingsText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Бронирований пока нет',
      style: AppTypography.body.copyWith(color: AppColors.secondaryText),
    );
  }
}

/// «Подключённые площадки»: the channel names and the last import.
final class _ChannelsSummary extends StatelessWidget {
  const _ChannelsSummary({required this.property, required this.onTap});

  final PropertyEntity property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Подключённые площадки',
                      style: AppTypography.primaryText.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      property.channelNames.isEmpty
                          ? 'Площадки не подключены'
                          : property.channelNames.join(' · '),
                      style: AppTypography.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      'Обновлены ${DateFormatter.relativeDayTime(property.syncedAt, now: property.receivedAt)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              ExcludeSemantics(
                child: SvgPicture.asset(
                  AppAssets.icons.refresh,
                  width: AppSizes.iconAction,
                  height: AppSizes.iconAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PropertySkeleton extends StatelessWidget {
  const _PropertySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: const <Widget>[
        AspectRatio(
          aspectRatio: 430 / 266,
          child: AppSkeleton(height: double.infinity, borderRadius: 0),
        ),
        Padding(
          padding: EdgeInsets.all(AppSizes.pageGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppSkeleton(height: 30, width: 280),
              SizedBox(height: AppSpacing.medium),
              AppSkeleton(height: 18, width: 220),
              SizedBox(height: AppSpacing.xLarge),
              AppSkeleton(height: 64, borderRadius: AppRadii.media),
            ],
          ),
        ),
      ],
    );
  }
}
