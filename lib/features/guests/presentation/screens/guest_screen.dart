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
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/create_guest_contract_usecase.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_usecase.dart';
import 'package:easy_booking/features/guests/presentation/bloc/guest_detail_bloc/guest_detail_bloc.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_avatar.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_contract_row.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_document_row.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_labels.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_stay_row.dart';

/// Screen 25 «Гость»: contacts, the identity document, stays, and contracts
/// of one guest, with «Создать договор» prefilled from the guest's data.
///
/// Provides its own [GuestDetailBloc] through [wrappedRoute].
final class GuestScreen extends StatelessWidget implements GoRouterWrapper {
  const GuestScreen({required this.guestId, super.key});

  final String guestId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<GuestDetailBloc>(
      create: (_) => GuestDetailBloc(
        getGuest: dependencies.getDep<GetGuestUsecase>(),
        createContract: dependencies.getDep<CreateGuestContractUsecase>(),
      )..add(GuestDetailRequested(guestId)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GuestDetailBloc, GuestDetailState>(
      listenWhen: (GuestDetailState previous, GuestDetailState current) =>
          previous.createContractStatus != current.createContractStatus,
      listener: _onContractCreationChanged,
      // The scaffold depends only on whether the guest has loaded; the body
      // and the footer select their own state.
      child: BlocSelector<GuestDetailBloc, GuestDetailState, bool>(
        selector: (GuestDetailState state) => state.guest != null,
        builder: (BuildContext context, bool hasGuest) {
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _GuestHeader(hasGuest: hasGuest),
                  const Expanded(child: _GuestBody()),
                ],
              ),
            ),
            bottomNavigationBar: hasGuest
                ? const _CreateContractFooter()
                : null,
          );
        },
      ),
    );
  }

  void _onContractCreationChanged(
    BuildContext context,
    GuestDetailState state,
  ) {
    final String? contractId = state.createdContractId;
    if (state.createContractStatus.isSuccess && contractId != null) {
      context.pushNamed(
        AppRoutes.contract.name,
        pathParameters: <String, String>{AppRoutes.contractIdParam: contractId},
      );
      return;
    }
    final Failure? failure = state.createContractFailure;
    if (state.createContractStatus.isFailure && failure != null) {
      context.showAppSnackbar(failure.userMessage);
    }
  }
}

/// The title row; «Ещё» appears once the guest has loaded.
final class _GuestHeader extends StatelessWidget {
  const _GuestHeader({required this.hasGuest});

  final bool hasGuest;

  @override
  Widget build(BuildContext context) {
    return AppDetailHeader(
      title: 'Гость',
      backSemanticLabel: 'Назад',
      showDivider: false,
      onBack: () => context.pop(),
      action: hasGuest
          ? AppIconButton(
              semanticLabel: 'Ещё',
              onPressed: () => context.showAppSnackbar(guestsComingSoonMessage),
              icon: SvgPicture.asset(
                AppAssets.icons.moreHorizontal,
                width: AppSizes.iconAction,
                height: AppSizes.iconAction,
                colorFilter: const ColorFilter.mode(
                  AppColors.secondaryText,
                  BlendMode.srcIn,
                ),
              ),
            )
          : null,
    );
  }
}

/// The guest once loaded, otherwise the load failure or the skeleton.
final class _GuestBody extends StatelessWidget {
  const _GuestBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuestDetailBloc, GuestDetailState>(
      buildWhen: (GuestDetailState previous, GuestDetailState current) =>
          previous.guest != current.guest ||
          previous.loadFailure != current.loadFailure ||
          previous.guestId != current.guestId,
      builder: (BuildContext context, GuestDetailState state) {
        final GuestEntity? guest = state.guest;
        if (guest != null) {
          return _GuestDetails(guest: guest);
        }
        final Failure? failure = state.loadFailure;
        if (failure == null) {
          return const _GuestSkeleton();
        }
        return _GuestLoadError(failure: failure, guestId: state.guestId);
      },
    );
  }
}

/// «Гость не найден» for a 404, otherwise the message and «Повторить».
final class _GuestLoadError extends StatelessWidget {
  const _GuestLoadError({required this.failure, required this.guestId});

  final Failure failure;
  final String guestId;

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
            title: 'Гость не найден',
            message: 'Возможно, его удалили или ссылка устарела',
            icon: SvgPicture.asset(AppAssets.icons.user),
          )
        else
          AppEmptyState(
            title: 'Не удалось загрузить гостя',
            message: failure.userMessage,
            icon: SvgPicture.asset(AppAssets.icons.alertCircle),
            actionLabel: 'Повторить',
            onAction: () => context.read<GuestDetailBloc>().add(
              GuestDetailRequested(guestId),
            ),
          ),
      ],
    );
  }
}

/// Contacts, the document, stays, and contracts of the loaded guest.
final class _GuestDetails extends StatelessWidget {
  const _GuestDetails({required this.guest});

  final GuestEntity guest;

  @override
  Widget build(BuildContext context) {
    void showComingSoon() => context.showAppSnackbar(guestsComingSoonMessage);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
      children: <Widget>[
        _GuestIdentity(guest: guest, onChat: showComingSoon),
        const _SectionDivider(),
        const _SectionTitle(title: 'Документы'),
        GuestDocumentRow(document: guest.document, onOpen: showComingSoon),
        const _SectionDivider(),
        const _SectionTitle(title: 'Проживания'),
        if (guest.stays.isEmpty)
          const _EmptyNote(text: 'Проживаний пока нет')
        else
          for (final GuestStayEntity stay in guest.stays)
            GuestStayRow(
              stay: stay,
              onTap: () => context.pushNamed(
                AppRoutes.booking.name,
                pathParameters: <String, String>{
                  AppRoutes.bookingIdParam: stay.bookingId,
                },
              ),
            ),
        const _SectionDivider(),
        const _SectionTitle(title: 'Договоры', top: 20, bottom: 6),
        if (guest.contracts.isEmpty)
          const _EmptyNote(text: 'Договоров пока нет')
        else
          for (final GuestContractEntity contract in guest.contracts)
            GuestContractRow(
              contract: contract,
              details: contract.statusDetails,
              onTap: () => context.pushNamed(
                AppRoutes.contract.name,
                pathParameters: <String, String>{
                  AppRoutes.contractIdParam: contract.id,
                },
              ),
            ),
      ],
    );
  }
}

/// «Создать договор»; rebuilds only when the creation starts or ends.
final class _CreateContractFooter extends StatelessWidget {
  const _CreateContractFooter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GuestDetailBloc, GuestDetailState, bool>(
      selector: (GuestDetailState state) =>
          state.createContractStatus.isLoading,
      builder: (BuildContext context, bool isCreating) {
        return AppFlowFooter(
          message: 'Данные гостя будут подставлены автоматически.',
          messageStyle: AppTypography.caption.copyWith(
            height: 18 / 12,
            color: AppColors.secondaryText,
          ),
          primaryLabel: 'Создать договор',
          primaryLoading: isCreating,
          onPrimaryPressed: () => context.read<GuestDetailBloc>().add(
            const GuestContractCreationRequested(),
          ),
        );
      },
    );
  }
}

/// Initials, name, phone, and the chat button.
final class _GuestIdentity extends StatelessWidget {
  const _GuestIdentity({required this.guest, required this.onChat});

  final GuestEntity guest;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        18,
        AppSizes.pageGutter,
        22,
      ),
      child: Row(
        children: <Widget>[
          GuestAvatar.large(initials: guest.initials),
          const SizedBox(width: AppSpacing.large),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  guest.fullName,
                  style: AppTypography.largeTitle.copyWith(
                    letterSpacing: -0.44,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  guest.phone,
                  style: AppTypography.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          _ChatButton(onPressed: onChat),
        ],
      ),
    );
  }
}

/// A 42 px outlined circle inside a 44 px touch target.
final class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.onPressed});

  static const double _size = 42;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: 'Написать гостю',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: AppSizes.touchTarget,
          child: Center(
            child: Container(
              width: _size,
              height: _size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.text),
              ),
              child: ExcludeSemantics(
                child: SvgPicture.asset(
                  AppAssets.icons.message,
                  width: 19,
                  height: 19,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.top = 22,
    this.bottom = AppSpacing.small,
  });

  final String title;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        top,
        AppSizes.pageGutter,
        bottom,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: AppTypography.sectionTitle.copyWith(
            height: 22 / 18,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}

final class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: AppSizes.pageGutter,
      endIndent: AppSizes.pageGutter,
      color: AppColors.border,
    );
  }
}

final class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        AppSpacing.xSmall,
        AppSizes.pageGutter,
        AppSpacing.large,
      ),
      child: Text(
        text,
        style: AppTypography.compactBody.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}

final class _GuestSkeleton extends StatelessWidget {
  const _GuestSkeleton();

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
        const Row(
          children: <Widget>[
            AppSkeleton(height: 64, width: 64),
            SizedBox(width: AppSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSkeleton(height: 22, width: 200),
                  SizedBox(height: AppSpacing.small),
                  AppSkeleton(height: 14, width: 130),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxLarge),
        for (int index = 0; index < 3; index++) ...<Widget>[
          const AppSkeleton(height: 20, width: 120),
          const SizedBox(height: AppSpacing.large),
          const Row(
            children: <Widget>[
              AppSkeleton(
                height: 44,
                width: 42,
                borderRadius: AppRadii.field,
              ),
              SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppSkeleton(height: 14, width: 170),
                    SizedBox(height: AppSpacing.small),
                    AppSkeleton(height: 12, width: 120),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxLarge),
        ],
      ],
    );
  }
}
