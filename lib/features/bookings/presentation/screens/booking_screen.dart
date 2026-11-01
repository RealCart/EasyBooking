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
import 'package:easy_booking/core/presentation/widgets/actions/app_status_badge.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_key_value_list.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_contract_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_usecase.dart';
import 'package:easy_booking/features/bookings/presentation/bloc/booking_detail_bloc/booking_detail_bloc.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_apartment_row.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_failure_message.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_labels.dart';

/// Screen 18 «Бронирование»: the guest, apartment, payment, and contract
/// of one booking. The «•••» menu cancels it.
///
/// Provides its own [BookingDetailBloc] through [wrappedRoute].
final class BookingScreen extends StatelessWidget implements GoRouterWrapper {
  const BookingScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<BookingDetailBloc>(
      create: (_) => BookingDetailBloc(
        getBooking: dependencies.getDep<GetBookingUsecase>(),
        cancelBooking: dependencies.getDep<CancelBookingUsecase>(),
      )..add(BookingDetailRequested(bookingId)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Built once: the selector below rebuilds only the Scaffold to add or
    // remove the footer slot, passing these same instances back.
    final Widget body = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _BookingHeader(
            onBack: () => _close(context),
            onActionsPressed: () => _showActions(context),
          ),
          const Expanded(child: _BookingContent()),
        ],
      ),
    );
    const Widget footer = _BookingFooter();

    return MultiBlocListener(
      listeners: <BlocListener<BookingDetailBloc, BookingDetailState>>[
        BlocListener<BookingDetailBloc, BookingDetailState>(
          listenWhen:
              (BookingDetailState previous, BookingDetailState current) =>
                  previous.cancelStatus != current.cancelStatus &&
                  current.cancelStatus.isSuccess,
          listener: (BuildContext context, _) =>
              context.showAppSnackbar('Бронь отменена'),
        ),
        BlocListener<BookingDetailBloc, BookingDetailState>(
          listenWhen:
              (BookingDetailState previous, BookingDetailState current) =>
                  previous.cancelFailure != current.cancelFailure &&
                  current.cancelFailure != null,
          listener: (BuildContext context, BookingDetailState state) {
            final Failure? failure = state.cancelFailure;
            if (failure != null && failure is! CancelledFailure) {
              context.showAppSnackbar(failure.bookingMessage);
            }
          },
        ),
      ],
      // A null `bottomNavigationBar` keeps the Scaffold's bottom padding
      // handling of the loading and error states unchanged.
      child: BlocSelector<BookingDetailBloc, BookingDetailState, bool>(
        selector: (BookingDetailState state) => state.booking != null,
        builder: (BuildContext context, bool hasBooking) {
          return Scaffold(
            body: body,
            bottomNavigationBar: hasBooking ? footer : null,
          );
        },
      ),
    );
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.today.name);
    }
  }

  Future<void> _showActions(BuildContext context) async {
    final BookingDetailBloc bloc = context.read<BookingDetailBloc>();
    final bool? isCancelPicked = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext sheetContext) => _BookingActionsSheet(
        onCancelPicked: () => Navigator.of(sheetContext).pop(true),
      ),
    );
    if (!context.mounted || isCancelPicked != true) {
      return;
    }
    final bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppConfirmationDialog(
          title: 'Отменить бронь?',
          message:
              'Даты освободятся во всех каналах. Это действие нельзя '
              'отменить.',
          cancelLabel: 'Не отменять',
          confirmLabel: 'Отменить бронь',
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    if (isConfirmed ?? false) {
      bloc.add(const BookingDetailCancelRequested());
    }
  }
}

/// «Бронирование» with the «•••» actions while the booking can be
/// cancelled.
final class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.onBack, required this.onActionsPressed});

  final VoidCallback onBack;
  final VoidCallback onActionsPressed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingDetailBloc,
      BookingDetailState,
      ({bool showActions, bool canCancel})
    >(
      selector: (BookingDetailState state) => (
        showActions: state.booking?.status.isCancellable ?? false,
        canCancel: state.canCancel,
      ),
      builder:
          (
            BuildContext context,
            ({bool showActions, bool canCancel}) value,
          ) {
            return AppDetailHeader(
              title: 'Бронирование',
              backSemanticLabel: 'Назад',
              showDivider: false,
              onBack: onBack,
              action: value.showActions
                  ? AppIconButton(
                      icon: SvgPicture.asset(
                        AppAssets.icons.moreHorizontal,
                        width: AppSizes.iconAction,
                        height: AppSizes.iconAction,
                      ),
                      semanticLabel: 'Действия с бронью',
                      onPressed: value.canCancel ? onActionsPressed : null,
                    )
                  : null,
            );
          },
    );
  }
}

/// The booking, or its skeleton or load error while there is none.
final class _BookingContent extends StatelessWidget {
  const _BookingContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingDetailBloc, BookingDetailState>(
      buildWhen: (BookingDetailState previous, BookingDetailState current) =>
          previous.booking != current.booking ||
          previous.loadFailure != current.loadFailure ||
          previous.bookingId != current.bookingId,
      builder: (BuildContext context, BookingDetailState state) {
        final BookingEntity? booking = state.booking;
        if (booking == null) {
          return _BookingPlaceholder(
            failure: state.loadFailure,
            bookingId: state.bookingId,
          );
        }
        return _BookingDetails(booking: booking);
      },
    );
  }
}

/// The skeleton while loading, or the load error with a retry.
final class _BookingPlaceholder extends StatelessWidget {
  const _BookingPlaceholder({required this.bookingId, this.failure});

  final Failure? failure;

  /// The requested booking, for the retry.
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    if (failure == null) {
      return const _BookingSkeleton();
    }
    final bool isMissing =
        failure is ServerFailure && failure.statusCode == 404;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        if (isMissing)
          AppEmptyState(
            title: 'Бронь не найдена',
            message: 'Возможно, её удалили или ссылка устарела',
            icon: SvgPicture.asset(AppAssets.icons.calendar),
          )
        else
          AppEmptyState(
            title: 'Не удалось загрузить бронь',
            message: failure.bookingMessage,
            icon: SvgPicture.asset(AppAssets.icons.alertCircle),
            actionLabel: 'Повторить',
            onAction: () => context.read<BookingDetailBloc>().add(
              BookingDetailRequested(bookingId),
            ),
          ),
      ],
    );
  }
}

/// The guest, apartment, payment, and contract of [booking].
final class _BookingDetails extends StatelessWidget {
  const _BookingDetails({required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final BookingContractEntity? contract = booking.contract;
    final String? contractId = contract?.id;
    final String? comment = booking.comment?.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        18,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: <Widget>[
        Row(
          spacing: AppSpacing.small,
          children: <Widget>[
            AppStatusBadge(
              label: booking.status.label,
              variant: booking.status.badgeVariant,
            ),
            Flexible(
              child: Text(
                booking.sourceDetails,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          booking.guest.fullName,
          style: AppTypography.compactScreenTitle.copyWith(
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          booking.stayDetails,
          style: AppTypography.body.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 18),
        BookingApartmentRow(
          title: booking.apartmentTitle,
          subtitle: booking.checkTimes,
          initials: booking.apartmentInitials,
          onTap: () => context.pushNamed(
            AppRoutes.property.name,
            pathParameters: <String, String>{
              AppRoutes.propertyIdParam: booking.propertyId,
            },
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: Text(
            'Оплата и условия',
            style: AppTypography.sectionTitle.copyWith(color: AppColors.text),
          ),
        ),
        AppKeyValueList(
          rows: <AppKeyValueRow>[
            AppKeyValueRow(label: 'Проживание', value: booking.priceDetails),
            AppKeyValueRow(label: 'Депозит', value: booking.depositDetails),
            AppKeyValueRow(
              label: 'Телефон',
              value: PhoneNumber.format(booking.guest.phone),
            ),
            if (comment != null && comment.isNotEmpty)
              AppKeyValueRow(label: 'Комментарий', value: comment),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        AppCallout(
          title: contract.title,
          message: contract.details(now: booking.receivedAt),
          tone: contract.tone,
          // A contract without an id is not available in the app yet.
          actionLabel: contractId == null ? null : 'Открыть',
          onAction: contractId == null
              ? null
              : () => context.pushNamed(
                  AppRoutes.contract.name,
                  pathParameters: <String, String>{
                    AppRoutes.contractIdParam: contractId,
                  },
                ),
        ),
      ],
    );
  }
}

/// «Изменить» and «Связаться» of a loaded booking.
final class _BookingFooter extends StatelessWidget {
  const _BookingFooter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BookingDetailBloc, BookingDetailState, String?>(
      selector: (BookingDetailState state) => state.booking?.guest.phone,
      builder: (BuildContext context, String? phone) {
        // The screen adds the footer only once a booking has loaded.
        if (phone == null) {
          return const SizedBox.shrink();
        }
        return AppFlowFooter(
          message: 'Изменения синхронизируются с календарями.',
          messageStyle: AppTypography.caption.copyWith(
            height: 18 / 12,
            color: AppColors.secondaryText,
          ),
          secondaryLabel: 'Изменить',
          onSecondaryPressed: () =>
              context.showAppSnackbar(bookingsComingSoonMessage),
          primaryLabel: 'Связаться',
          onPrimaryPressed: () => context.showAppSnackbar(
            'Телефон гостя: ${PhoneNumber.format(phone)}',
          ),
        );
      },
    );
  }
}

/// The «•••» sheet: «Отменить бронь».
final class _BookingActionsSheet extends StatelessWidget {
  const _BookingActionsSheet({required this.onCancelPicked});

  final VoidCallback onCancelPicked;

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
              title: 'Отменить бронь',
              subtitle: 'Даты освободятся во всех каналах',
              showDivider: false,
              trailing: const SizedBox.shrink(),
              onTap: onCancelPicked,
            ),
          ],
        ),
      ),
    );
  }
}

final class _BookingSkeleton extends StatelessWidget {
  const _BookingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        18,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: const <Widget>[
        AppSkeleton(height: 28, width: 200),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 30, width: 260),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 18, width: 220),
        SizedBox(height: AppSpacing.xLarge),
        AppSkeleton(height: 64, borderRadius: AppRadii.media),
        SizedBox(height: AppSpacing.xLarge),
        AppSkeleton(height: 120, borderRadius: AppRadii.media),
      ],
    );
  }
}
