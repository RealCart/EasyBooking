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
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_detail_bloc/property_detail_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_labels.dart';

/// Screen 16 «Квартира добавлена»: the end of the add-property flow, opened
/// with `goNamed` so the flow is gone from the stack.
///
/// Provides its own [PropertyDetailBloc] through [wrappedRoute].
final class PropertyReadyScreen extends StatelessWidget
    implements GoRouterWrapper {
  const PropertyReadyScreen({required this.propertyId, super.key});

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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<PropertyDetailBloc, PropertyDetailState>(
          buildWhen:
              (PropertyDetailState previous, PropertyDetailState current) =>
                  previous.property != current.property ||
                  previous.loadFailure != current.loadFailure ||
                  previous.propertyId != current.propertyId,
          builder: (BuildContext context, PropertyDetailState state) {
            final PropertyEntity? property = state.property;
            if (property != null) {
              return _ReadyContent(property: property);
            }
            final Failure? failure = state.loadFailure;
            if (failure == null) {
              return const _ReadySkeleton();
            }
            return _ReadyError(failure: failure, propertyId: state.propertyId);
          },
        ),
      ),
      bottomNavigationBar: AppFlowFooter(
        message: 'Квартира сохранена в списке объектов.',
        messageStyle: AppTypography.caption.copyWith(
          color: AppColors.secondaryText,
          height: 18 / 12,
        ),
        secondaryLabel: 'На главную',
        onSecondaryPressed: () => context.goNamed(AppRoutes.today.name),
        primaryLabel: 'Открыть объект',
        onPrimaryPressed: () => context.goNamed(
          AppRoutes.property.name,
          pathParameters: <String, String>{
            AppRoutes.propertyIdParam: propertyId,
          },
        ),
      ),
    );
  }
}

/// The loaded property: the success header, the property, and the next
/// steps with the channel statuses.
final class _ReadyContent extends StatelessWidget {
  const _ReadyContent({required this.property});

  final PropertyEntity property;

  @override
  Widget build(BuildContext context) {
    final List<BookingChannel> connected = <BookingChannel>[
      for (final BookingChannel channel in BookingChannel.values)
        if (property.channelNames.contains(channel.title)) channel,
    ];
    final List<BookingChannel> missing = <BookingChannel>[
      for (final BookingChannel channel in BookingChannel.values)
        if (!connected.contains(channel)) channel,
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            28,
            AppSizes.pageGutter,
            AppSpacing.xLarge,
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.successSurface,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  AppAssets.icons.checkSmall,
                  width: AppSizes.iconNavigation,
                  height: AppSizes.iconNavigation,
                  colorFilter: const ColorFilter.mode(
                    AppColors.success,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Semantics(
                header: true,
                child: Text(
                  'Квартира добавлена',
                  textAlign: TextAlign.center,
                  style: AppTypography.smallScreenTitle.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${property.fullTitle}\nготова принимать бронирования',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const _InsetDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pageGutter,
            vertical: 20,
          ),
          child: Row(
            children: <Widget>[
              _Initials(name: property.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: <Widget>[
                    Text(
                      property.shortTitle,
                      style: AppTypography.rowTitle.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      '${property.city} · ${property.price} за ночь',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondaryText,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              const _StatusText(label: 'Активна'),
            ],
          ),
        ),
        const _InsetDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            22,
            AppSizes.pageGutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  'Что дальше',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _NextStep(
                number: 1,
                title: 'Проверьте календари',
                message: _calendarsHint(connected, missing),
              ),
              const _NextStep(
                number: 2,
                title: 'Добавьте первую бронь',
                message:
                    'Даты сразу заблокируются во всех подключённых календарях.',
              ),
              const _NextStep(
                number: 3,
                title: 'Подготовьте инструкции гостю',
                message: 'Домофон, Wi-Fi и правила можно заполнить позже.',
              ),
              const SizedBox(height: 18),
              for (final BookingChannel channel in BookingChannel.values)
                _ChannelStatusRow(
                  title: channel.title,
                  isConnected: connected.contains(channel),
                  onConnect: () => context.goNamed(AppRoutes.channels.name),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// `Airbnb уже подключён. Добавьте Booking.com, если используете
  /// площадку.`
  static String _calendarsHint(
    List<BookingChannel> connected,
    List<BookingChannel> missing,
  ) {
    String names(List<BookingChannel> channels) {
      return channels.map((BookingChannel channel) => channel.title).join(', ');
    }

    if (connected.isEmpty) {
      return 'Подключите площадки, чтобы брони попали в общий календарь.';
    }
    final String done = connected.length == 1
        ? '${names(connected)} уже подключён.'
        : '${names(connected)} уже подключены.';
    if (missing.isEmpty) {
      return done;
    }
    final String usage = missing.length == 1
        ? 'если используете площадку.'
        : 'если используете эти площадки.';
    return '$done Добавьте ${names(missing)}, $usage';
  }
}

/// The load failure with «Повторить».
final class _ReadyError extends StatelessWidget {
  const _ReadyError({required this.failure, required this.propertyId});

  final Failure failure;

  /// The requested property, for the retry.
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        AppEmptyState(
          title: 'Не удалось загрузить квартиру',
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

final class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: Divider(height: 1, thickness: 1, color: AppColors.border),
    );
  }
}

final class _StatusText extends StatelessWidget {
  const _StatusText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.success,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
      ),
    );
  }
}

/// A 56 px circle with the first letters of the first and last words of
/// [name]: `AF` for `Al-Farabi Residence`.
final class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    final String initials = switch (words.length) {
      0 => '',
      1 => words.first.characters.first,
      _ => '${words.first.characters.first}${words.last.characters.first}',
    }.toUpperCase();

    return ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: AppTypography.sectionTitle.copyWith(
            fontSize: 17,
            height: 22 / 17,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}

final class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.number,
    required this.title,
    required this.message,
  });

  final int number;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: AppTypography.caption.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.action.copyWith(
                      color: AppColors.text,
                      height: 18 / 14,
                    ),
                  ),
                  Text(
                    message,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryText,
                      height: 18 / 12,
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

final class _ChannelStatusRow extends StatelessWidget {
  const _ChannelStatusRow({
    required this.title,
    required this.isConnected,
    required this.onConnect,
  });

  final String title;
  final bool isConnected;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.action.copyWith(
                      color: AppColors.text,
                      height: 18 / 14,
                    ),
                  ),
                  Text(
                    isConnected
                        ? 'Импорт и экспорт занятости'
                        : 'Можно подключить позже',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryText,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            if (isConnected)
              const _StatusText(label: 'Подключён')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.touchTarget,
                ),
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Подключить $title',
                    excludeSemantics: true,
                    child: AppTextButton.underlined(
                      label: 'Подключить',
                      onPressed: onConnect,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _ReadySkeleton extends StatelessWidget {
  const _ReadySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        28,
        AppSizes.pageGutter,
        0,
      ),
      children: const <Widget>[
        Center(child: AppSkeleton(height: 52, width: 52)),
        SizedBox(height: 18),
        Center(child: AppSkeleton(height: 28, width: 240)),
        SizedBox(height: AppSpacing.medium),
        Center(child: AppSkeleton(height: 18, width: 260)),
        SizedBox(height: AppSpacing.xxLarge),
        AppSkeleton(height: 56, borderRadius: AppRadii.media),
        SizedBox(height: AppSpacing.xLarge),
        AppSkeleton(height: 160, borderRadius: AppRadii.media),
      ],
    );
  }
}
