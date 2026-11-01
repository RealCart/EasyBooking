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
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_bookings_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_bookings_bloc/property_bookings_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_booking_row.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_group_label.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_labels.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_management_labels.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_section_tabs.dart';

/// Screen 28 «Объект · бронирования»: the upcoming or past bookings of one
/// property, grouped by the check-in month.
///
/// Provides its own [PropertyBookingsBloc] through [wrappedRoute].
final class PropertyBookingsScreen extends StatelessWidget
    implements GoRouterWrapper {
  const PropertyBookingsScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<PropertyBookingsBloc>(
      create: (_) => PropertyBookingsBloc(
        getBookings: dependencies.getDep<GetPropertyBookingsUsecase>(),
      )..add(PropertyBookingsRequested(propertyId)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertyBookingsBloc, PropertyBookingsState>(
      // A failed refresh while bookings are shown; the first load failure is
      // shown in place of the list.
      listenWhen:
          (PropertyBookingsState previous, PropertyBookingsState current) =>
              previous.loadStatus != current.loadStatus &&
              current.loadStatus.isFailure &&
              current.bookings != null,
      listener: (BuildContext context, PropertyBookingsState state) {
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          context.showAppSnackbar(failure.userMessage);
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _BookingsHeader(),
              PropertySectionTabs(
                selected: PropertySection.bookings,
                onSelected: (PropertySection section) => openPropertySection(
                  context,
                  propertyId: propertyId,
                  from: PropertySection.bookings,
                  to: section,
                ),
              ),
              Expanded(child: _BookingsBody(propertyId: propertyId)),
            ],
          ),
        ),
        bottomNavigationBar: AppFlowFooter(
          primaryLabel: 'Добавить бронь',
          onPrimaryPressed: () => context.pushNamed(AppRoutes.newBooking.name),
        ),
      ),
    );
  }
}

/// Reloads on return, so a booking changed there shows here.
Future<void> _openBooking(
  BuildContext context, {
  required String propertyId,
  required String bookingId,
}) async {
  final PropertyBookingsBloc bloc = context.read<PropertyBookingsBloc>();
  await context.pushNamed<void>(
    AppRoutes.booking.name,
    pathParameters: <String, String>{AppRoutes.bookingIdParam: bookingId},
  );
  if (!bloc.isClosed) {
    bloc.add(PropertyBookingsRequested(propertyId));
  }
}

/// The header; follows the property title only.
final class _BookingsHeader extends StatelessWidget {
  const _BookingsHeader();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PropertyBookingsBloc, PropertyBookingsState, String?>(
      selector: (PropertyBookingsState state) =>
          state.bookings?.property.shortTitle,
      builder: (BuildContext context, String? title) {
        return AppDetailHeader(
          title: title ?? 'Бронирования',
          backSemanticLabel: 'Назад',
          showDivider: false,
          onBack: () => context.pop(),
        );
      },
    );
  }
}

/// The skeleton, the load failure, or the grouped bookings of the period.
final class _BookingsBody extends StatelessWidget {
  const _BookingsBody({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyBookingsBloc, PropertyBookingsState>(
      buildWhen:
          (PropertyBookingsState previous, PropertyBookingsState current) =>
              previous.bookings != current.bookings ||
              previous.loadFailure != current.loadFailure ||
              previous.propertyId != current.propertyId ||
              previous.period != current.period,
      builder: (BuildContext context, PropertyBookingsState state) {
        final PropertyBookingsEntity? bookings = state.bookings;
        if (bookings != null) {
          return _BookingsList(
            bookings: bookings,
            visible: state.visibleBookings,
            period: state.period,
            propertyId: propertyId,
          );
        }
        final Failure? failure = state.loadFailure;
        if (failure == null) {
          return const _BookingsSkeleton();
        }
        return _BookingsLoadError(
          failure: failure,
          propertyId: state.propertyId,
        );
      },
    );
  }
}

/// The first load failure with «Повторить».
final class _BookingsLoadError extends StatelessWidget {
  const _BookingsLoadError({required this.failure, required this.propertyId});

  final Failure failure;

  /// The requested property, for the retry.
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        AppEmptyState(
          title: 'Не удалось загрузить брони',
          message: failure.userMessage,
          icon: SvgPicture.asset(AppAssets.icons.alertCircle),
          actionLabel: 'Повторить',
          onAction: () => context.read<PropertyBookingsBloc>().add(
            PropertyBookingsRequested(propertyId),
          ),
        ),
      ],
    );
  }
}

/// The period chips, then month headers and their bookings.
final class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.bookings,
    required this.visible,
    required this.period,
    required this.propertyId,
  });

  final PropertyBookingsEntity bookings;

  /// The bookings of [period].
  final List<PropertyBookingEntity> visible;
  final PropertyBookingsPeriod period;
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final DateTime now = bookings.receivedAt;
    final List<_BookingListItem> items = _group(visible, now: now);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
      itemCount: items.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _PeriodHeader(
            upcomingCount: bookings.upcoming.length,
            period: period,
            isEmpty: visible.isEmpty,
          );
        }
        final _BookingListItem item = items[index - 1];
        final PropertyBookingEntity? booking = item.booking;
        if (booking == null) {
          return PropertyGroupLabel(
            label: item.monthLabel!,
            topPadding: index == 1 ? AppSpacing.small : 22,
          );
        }
        return _BookingItem(
          booking: booking,
          now: now,
          showDivider: !item.isLastInGroup,
          onTap: () => _openBooking(
            context,
            propertyId: propertyId,
            bookingId: booking.id,
          ),
        );
      },
    );
  }

  /// Month headers followed by their bookings, in the given order.
  static List<_BookingListItem> _group(
    List<PropertyBookingEntity> bookings, {
    required DateTime now,
  }) {
    final List<_BookingListItem> items = <_BookingListItem>[];
    for (int index = 0; index < bookings.length; index++) {
      final PropertyBookingEntity booking = bookings[index];
      final PropertyBookingEntity? previous = index == 0
          ? null
          : bookings[index - 1];
      final PropertyBookingEntity? next = index == bookings.length - 1
          ? null
          : bookings[index + 1];
      if (previous == null || !_isSameMonth(previous, booking)) {
        items.add(
          _BookingListItem.month(bookingMonthLabel(booking.checkIn, now: now)),
        );
      }
      items.add(
        _BookingListItem.booking(
          booking,
          isLastInGroup: next != null && !_isSameMonth(booking, next),
        ),
      );
    }
    return items;
  }

  static bool _isSameMonth(PropertyBookingEntity a, PropertyBookingEntity b) {
    return a.checkIn.year == b.checkIn.year &&
        a.checkIn.month == b.checkIn.month;
  }
}

/// «Предстоящие · N» / «Прошедшие», and the empty state of the period.
final class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({
    required this.upcomingCount,
    required this.period,
    required this.isEmpty,
  });

  final int upcomingCount;
  final PropertyBookingsPeriod period;

  /// Whether [period] has no bookings.
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 12),
          child: AppScopeFilter(
            labels: <String>['Предстоящие · $upcomingCount', 'Прошедшие'],
            selectedIndex: period.index,
            onSelected: (int index) => context.read<PropertyBookingsBloc>().add(
              PropertyBookingsPeriodSelected(
                PropertyBookingsPeriod.values[index],
              ),
            ),
          ),
        ),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pageGutter,
            ),
            child: AppEmptyState(
              title: period == PropertyBookingsPeriod.upcoming
                  ? 'Предстоящих броней нет'
                  : 'Прошедших броней нет',
              message: 'Новые брони появятся здесь',
              icon: SvgPicture.asset(AppAssets.icons.calendar),
            ),
          ),
      ],
    );
  }
}

/// One booking: the check-in day, the guest, the status, and the price or
/// the missing-contract warning.
final class _BookingItem extends StatelessWidget {
  const _BookingItem({
    required this.booking,
    required this.now,
    required this.showDivider,
    required this.onTap,
  });

  final PropertyBookingEntity booking;

  /// The source's current time, which tells whether check-in is today.
  final DateTime now;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isToday = DateUtils.isSameDay(booking.checkIn, now);
    return PropertyBookingRow(
      dayLabel: isToday
          ? 'СЕГ'
          : DateFormatter.weekdayShort(booking.checkIn).toUpperCase(),
      day: booking.checkIn.day.toString().padLeft(2, '0'),
      accentColor: booking.accentColor,
      guestName: booking.guestName,
      statusLabel: booking.statusLabel,
      statusColor: booking.statusColor,
      details: booking.datesLabel,
      footnote: booking.isDirect && !booking.hasContract
          ? 'Договор не создан'
          : booking.priceLabel,
      isFootnoteWarning: booking.isDirect && !booking.hasContract,
      showDivider: showDivider,
      onTap: onTap,
    );
  }
}

/// A month header ([monthLabel]) or a [booking] of the grouped list.
final class _BookingListItem {
  const _BookingListItem.month(String this.monthLabel)
    : booking = null,
      isLastInGroup = false;

  const _BookingListItem.booking(
    PropertyBookingEntity this.booking, {
    required this.isLastInGroup,
  }) : monthLabel = null;

  final String? monthLabel;
  final PropertyBookingEntity? booking;

  /// The last booking before the next month header: drawn without a divider.
  final bool isLastInGroup;
}

final class _BookingsSkeleton extends StatelessWidget {
  const _BookingsSkeleton();

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
      children: const <Widget>[
        Row(
          children: <Widget>[
            AppSkeleton(height: 32, width: 140),
            SizedBox(width: AppSpacing.small),
            AppSkeleton(height: 32, width: 104),
          ],
        ),
        SizedBox(height: AppSpacing.xLarge),
        AppSkeleton(height: 14, width: 72),
        SizedBox(height: AppSpacing.large),
        AppSkeleton(height: 64, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.large),
        AppSkeleton(height: 64, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.large),
        AppSkeleton(height: 64, borderRadius: AppRadii.field),
      ],
    );
  }
}
