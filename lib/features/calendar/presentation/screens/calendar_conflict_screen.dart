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
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/conflict_booking_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/resolve_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/calendar_conflict_bloc/calendar_conflict_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/calendar_conflict_labels.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/calendar_decision_footer.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/conflict_booking_tile.dart';

/// Screen 21 «Конфликт календарей»: two bookings of one property that
/// overlap, and keeping one of them.
///
/// Provides its own [CalendarConflictBloc] through [wrappedRoute].
final class CalendarConflictScreen extends StatelessWidget
    implements GoRouterWrapper {
  const CalendarConflictScreen({required this.conflictId, super.key});

  final String conflictId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<CalendarConflictBloc>(
      create: (_) => CalendarConflictBloc(
        getConflict: dependencies.getDep<GetCalendarConflictUsecase>(),
        resolveConflict: dependencies.getDep<ResolveCalendarConflictUsecase>(),
      )..add(CalendarConflictRequested(conflictId)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Widget body = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ConflictHeader(),
          Expanded(child: _ConflictBody()),
        ],
      ),
    );
    return BlocListener<CalendarConflictBloc, CalendarConflictState>(
      listenWhen: (
        CalendarConflictState previous,
        CalendarConflictState current,
      ) => previous.resolveStatus != current.resolveStatus,
      listener: (BuildContext context, CalendarConflictState state) {
        if (state.resolveStatus.isSuccess) {
          context.showAppSnackbar('Конфликт решён');
        } else if (state.resolveFailure case final Failure failure) {
          context.showAppSnackbar(failure.userMessage);
        }
      },
      // Only whether the footer exists rebuilds the scaffold.
      child: BlocSelector<CalendarConflictBloc, CalendarConflictState, bool>(
        selector: (CalendarConflictState state) {
          final CalendarConflictEntity? conflict = state.conflict;
          return conflict != null && conflict.bookings.isNotEmpty;
        },
        builder: (BuildContext context, bool hasFooter) {
          return Scaffold(
            body: body,
            bottomNavigationBar: hasFooter ? const _ConflictFooter() : null,
          );
        },
      ),
    );
  }
}

/// «Конфликт календарей» with the conflict's position, for example «1 из 2».
final class _ConflictHeader extends StatelessWidget {
  const _ConflictHeader();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CalendarConflictBloc, CalendarConflictState, String?>(
      selector: (CalendarConflictState state) => state.conflict?.positionLabel,
      builder: (BuildContext context, String? positionLabel) {
        return AppDetailHeader(
          title: 'Конфликт календарей',
          backSemanticLabel: 'Назад',
          showDivider: false,
          onBack: () => context.pop(),
          action: positionLabel == null
              ? null
              : _PositionLabel(label: positionLabel),
        );
      },
    );
  }
}

final class _PositionLabel extends StatelessWidget {
  const _PositionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.touchTarget,
      child: Text(
        label,
        textAlign: TextAlign.right,
        maxLines: 1,
        style: AppTypography.caption.copyWith(color: AppColors.secondaryText),
      ),
    );
  }
}

/// The conflict, or before it arrives its skeleton or the error.
final class _ConflictBody extends StatelessWidget {
  const _ConflictBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarConflictBloc, CalendarConflictState>(
      buildWhen:
          (CalendarConflictState previous, CalendarConflictState current) =>
              previous.conflict != current.conflict ||
              previous.loadFailure != current.loadFailure ||
              previous.conflictId != current.conflictId,
      builder: (BuildContext context, CalendarConflictState state) {
        final CalendarConflictEntity? conflict = state.conflict;
        if (conflict == null) {
          return _ConflictPlaceholder(
            failure: state.loadFailure,
            conflictId: state.conflictId,
          );
        }
        return _ConflictDetails(conflict: conflict);
      },
    );
  }
}

final class _ConflictPlaceholder extends StatelessWidget {
  const _ConflictPlaceholder({required this.failure, required this.conflictId});

  final Failure? failure;

  /// The requested conflict, for retrying.
  final String conflictId;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    if (failure == null) {
      return const _ConflictSkeleton();
    }
    final bool isMissing =
        failure is ServerFailure && failure.statusCode == 404;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        if (isMissing)
          AppEmptyState(
            title: 'Конфликт не найден',
            message: 'Возможно, его уже решили или ссылка устарела',
            icon: SvgPicture.asset(AppAssets.icons.calendarGrid),
          )
        else
          AppEmptyState(
            title: 'Не удалось загрузить конфликт',
            message: failure.userMessage,
            icon: SvgPicture.asset(AppAssets.icons.alertCircle),
            actionLabel: 'Повторить',
            onAction: () => context.read<CalendarConflictBloc>().add(
              CalendarConflictRequested(conflictId),
            ),
          ),
      ],
    );
  }
}

final class _ConflictDetails extends StatelessWidget {
  const _ConflictDetails({required this.conflict});

  final CalendarConflictEntity conflict;

  @override
  Widget build(BuildContext context) {
    final DateTime now = conflict.receivedAt;
    final List<ConflictBookingEntity> bookings = conflict.bookings;
    final ConflictBookingEntity? kept = conflict.keptBooking;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        22,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            const _ConflictMark(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                conflict.isResolved
                    ? 'Конфликт решён'
                    : 'Пересечение бронирований',
                style: AppTypography.smallScreenTitle.copyWith(
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          '${conflict.propertyLabel}\n${conflict.overlapLabel}',
          style: AppTypography.body.copyWith(
            height: 21 / 14,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: Text(
            'Брони в конфликте',
            style: AppTypography.sectionTitle.copyWith(color: AppColors.text),
          ),
        ),
        for (int index = 0; index < bookings.length; index++)
          ConflictBookingTile(
            title: bookings[index].title,
            statusLabel: kept == null
                ? bookings[index].statusLabel(now: now)
                : kept.bookingId == bookings[index].bookingId
                ? 'Сохранена'
                : 'Отменена',
            dates: bookings[index].datesLabel,
            details: bookings[index].detailsLabel,
            color: _colorOf(bookings[index], kept: kept),
            showBottomDivider: index == bookings.length - 1,
            onTap: () => context.pushNamed(
              AppRoutes.booking.name,
              pathParameters: <String, String>{
                AppRoutes.bookingIdParam: bookings[index].bookingId,
              },
            ),
          ),
        const SizedBox(height: AppSpacing.small),
        if (kept == null)
          const _WhatHappensNote()
        else
          AppCallout(
            title: 'Оставлена бронь ${kept.title}',
            message:
                'Вторая бронь отменена в EasyBooking. Отмену на площадке '
                'подтвердите отдельно.',
            tone: AppFeedbackTone.success,
          ),
      ],
    );
  }

  /// Unresolved: red for a confirmed booking, brown for one only created,
  /// as in the design. Resolved: green for the kept one, grey otherwise.
  static Color _colorOf(
    ConflictBookingEntity booking, {
    ConflictBookingEntity? kept,
  }) {
    if (kept != null) {
      return kept.bookingId == booking.bookingId
          ? AppColors.success
          : AppColors.secondaryText;
    }
    return booking.isConfirmed ? AppColors.error : AppColors.warning;
  }
}

/// «Готово» once resolved; otherwise one action per booking to keep it.
final class _ConflictFooter extends StatelessWidget {
  const _ConflictFooter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarConflictBloc, CalendarConflictState>(
      buildWhen:
          (CalendarConflictState previous, CalendarConflictState current) =>
              previous.conflict != current.conflict ||
              previous.resolveStatus != current.resolveStatus ||
              previous.keepingBookingId != current.keepingBookingId,
      builder: (BuildContext context, CalendarConflictState state) {
        final CalendarConflictEntity? conflict = state.conflict;
        // The scaffold only shows the footer for a conflict with bookings.
        if (conflict == null || conflict.bookings.isEmpty) {
          return const SizedBox.shrink();
        }
        if (conflict.isResolved) {
          return CalendarDecisionFooter.single(
            primaryLabel: 'Готово',
            onPrimaryPressed: () => context.pop(),
          );
        }
        final bool isResolving = state.resolveStatus.isLoading;
        // The channel's booking comes first and gets the filled action.
        final ConflictBookingEntity primary = conflict.bookings.first;
        final ConflictBookingEntity secondary = conflict.bookings.length > 1
            ? conflict.bookings[1]
            : primary;
        return CalendarDecisionFooter(
          message: 'Выберите бронь, которую хотите сохранить.',
          secondaryLabel: secondary.keepLabel,
          onSecondaryPressed: isResolving
              ? null
              : () => context.read<CalendarConflictBloc>().add(
                  CalendarConflictBookingKept(secondary.bookingId),
                ),
          isSecondaryLoading:
              isResolving && state.keepingBookingId == secondary.bookingId,
          primaryLabel: primary.keepLabel,
          onPrimaryPressed: isResolving
              ? null
              : () => context.read<CalendarConflictBloc>().add(
                  CalendarConflictBookingKept(primary.bookingId),
                ),
          isPrimaryLoading:
              isResolving && state.keepingBookingId == primary.bookingId,
        );
      },
    );
  }
}

/// The red «!» on a pale circle next to the title.
final class _ConflictMark extends StatelessWidget {
  const _ConflictMark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 34,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.errorSurface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '!',
              style: AppTypography.primaryText.copyWith(
                height: 20 / 16,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «Что произойдёт»: what keeping a booking does to the other one.
final class _WhatHappensNote extends StatelessWidget {
  const _WhatHappensNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.media)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Что произойдёт',
              style: AppTypography.action.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 10),
            Text(
              'Сохраните одну бронь. Вторая будет отменена только '
              'в EasyBooking — отмену на площадке нужно подтвердить '
              'отдельно.',
              style: AppTypography.compactBody.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ConflictSkeleton extends StatelessWidget {
  const _ConflictSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        22,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: const <Widget>[
        AppSkeleton(height: 30, width: 300),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 16, width: 220),
        SizedBox(height: AppSpacing.small),
        AppSkeleton(height: 16, width: 280),
        SizedBox(height: AppSpacing.xLarge),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 110, borderRadius: AppRadii.media),
      ],
    );
  }
}
