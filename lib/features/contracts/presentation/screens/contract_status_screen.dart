import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_history_entry_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_status_bloc/contract_status_bloc.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_file_cards.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_labels.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_load_placeholders.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_text_action.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_timeline.dart';

/// Screen 26 «Договор · статус»: the signing progress of a contract, its
/// file and link, and «Отправить повторно» while the guest has not signed.
///
/// Provides its own [ContractStatusBloc] through [wrappedRoute].
final class ContractStatusScreen extends StatelessWidget
    implements GoRouterWrapper {
  const ContractStatusScreen({required this.contractId, super.key});

  final String contractId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<ContractStatusBloc>(
      create: (_) => ContractStatusBloc(
        getContract: dependencies.getDep<GetContractUsecase>(),
        sendContract: dependencies.getDep<SendContractUsecase>(),
      )..add(ContractStatusRequested(contractId)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<ContractStatusBloc, ContractStatusState>>[
        BlocListener<ContractStatusBloc, ContractStatusState>(
          listenWhen:
              (ContractStatusState previous, ContractStatusState current) =>
                  previous.resendStatus != current.resendStatus &&
                  (current.resendStatus.isSuccess ||
                      current.resendStatus.isFailure),
          listener: (BuildContext context, ContractStatusState state) {
            final Failure? failure = state.resendFailure;
            context.showAppSnackbar(
              failure == null
                  ? 'Ссылка отправлена повторно'
                  : failure.contractMessage,
            );
          },
        ),
        // A failed refresh keeps the shown contract and reports the error.
        BlocListener<ContractStatusBloc, ContractStatusState>(
          listenWhen:
              (ContractStatusState previous, ContractStatusState current) =>
                  previous.loadFailure != current.loadFailure &&
                  current.loadFailure != null &&
                  current.contract != null,
          listener: (BuildContext context, ContractStatusState state) {
            context.showAppSnackbar(state.loadFailure!.contractMessage);
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _StatusHeader(
                onBack: () => _close(context),
                onDownload: () => _showComingSoon(context),
              ),
              Expanded(
                child: _StatusBody(
                  contractId: contractId,
                  onRetry: () => context.read<ContractStatusBloc>().add(
                    ContractStatusRequested(contractId),
                  ),
                  onRefresh: () => _refresh(context),
                  onShowComingSoon: () => _showComingSoon(context),
                  onCopyLink: (String url) => _copyLink(context, url),
                ),
              ),
            ],
          ),
        ),
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

  void _showComingSoon(BuildContext context) {
    context.showAppSnackbar(contractsComingSoonMessage);
  }

  /// Completes when the reload has finished, so the indicator hides then.
  Future<void> _refresh(BuildContext context) async {
    final ContractStatusBloc bloc = context.read<ContractStatusBloc>();
    bloc.add(ContractStatusRequested(contractId));
    await bloc.stream.firstWhere(
      (ContractStatusState state) => !state.loadStatus.isLoading,
      orElse: () => bloc.state,
    );
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) {
      return;
    }
    context.showAppSnackbar('Ссылка скопирована');
  }
}

/// «Договор» with «PDF» once the contract is loaded.
final class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.onBack, required this.onDownload});

  final VoidCallback onBack;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ContractStatusBloc, ContractStatusState, bool>(
      selector: (ContractStatusState state) => state.contract != null,
      builder: (BuildContext context, bool hasContract) {
        return AppDetailHeader(
          title: 'Договор',
          backSemanticLabel: 'Назад',
          showDivider: false,
          onBack: onBack,
          action: hasContract
              ? ContractTextAction(
                  label: 'PDF',
                  semanticLabel: 'Скачать PDF',
                  isMuted: true,
                  onPressed: onDownload,
                )
              : null,
        );
      },
    );
  }
}

/// The skeleton or load error until the contract arrives, then the
/// refreshable status and, while unsigned, its footer.
final class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.contractId,
    required this.onRetry,
    required this.onRefresh,
    required this.onShowComingSoon,
    required this.onCopyLink,
  });

  final String contractId;
  final VoidCallback onRetry;
  final RefreshCallback onRefresh;
  final VoidCallback onShowComingSoon;
  final ValueChanged<String> onCopyLink;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ContractStatusBloc,
      ContractStatusState,
      ContractEntity?
    >(
      selector: (ContractStatusState state) => state.contract,
      builder: (BuildContext context, ContractEntity? contract) {
        if (contract == null) {
          return _StatusPlaceholder(onRetry: onRetry);
        }
        final ContractStatus status = contract.status;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                onRefresh: onRefresh,
                child: _StatusContent(
                  contract: contract,
                  onShowComingSoon: onShowComingSoon,
                  onCopyLink: onCopyLink,
                ),
              ),
            ),
            if (status == ContractStatus.draft)
              _DraftFooter(contractId: contractId)
            else if (!status.isSigned)
              const _ResendFooter(),
          ],
        );
      },
    );
  }
}

/// [ContractSkeleton] while loading, [ContractLoadError] after a failure.
final class _StatusPlaceholder extends StatelessWidget {
  const _StatusPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ContractStatusBloc, ContractStatusState, Failure?>(
      selector: (ContractStatusState state) => state.loadFailure,
      builder: (BuildContext context, Failure? failure) {
        if (failure == null) {
          return const ContractSkeleton();
        }
        return ContractLoadError(failure: failure, onRetry: onRetry);
      },
    );
  }
}

/// «Отправить на подпись» for a draft: opens the send step.
final class _DraftFooter extends StatelessWidget {
  const _DraftFooter({required this.contractId});

  final String contractId;

  @override
  Widget build(BuildContext context) {
    return AppFlowFooter(
      primaryLabel: 'Отправить на подпись',
      onPrimaryPressed: () => context.pushNamed(
        AppRoutes.contractSend.name,
        pathParameters: <String, String>{
          AppRoutes.contractIdParam: contractId,
        },
      ),
    );
  }
}

/// «Отправить повторно» while the guest has not signed.
final class _ResendFooter extends StatelessWidget {
  const _ResendFooter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ContractStatusBloc,
      ContractStatusState,
      ({bool canResend, bool isResending})
    >(
      selector: (ContractStatusState state) => (
        canResend: state.canResend,
        isResending: state.resendStatus.isLoading,
      ),
      builder:
          (
            BuildContext context,
            ({bool canResend, bool isResending}) value,
          ) {
            return AppFlowFooter(
              message: 'Гость получит новую безопасную ссылку.',
              messageStyle: AppTypography.caption.copyWith(
                color: AppColors.secondaryText,
              ),
              primaryLabel: 'Отправить повторно',
              onPrimaryPressed: value.canResend
                  ? () => context.read<ContractStatusBloc>().add(
                      const ContractResendRequested(),
                    )
                  : null,
              primaryLoading: value.isResending,
            );
          },
    );
  }
}

/// The status line, the contract file, the history, and its actions.
final class _StatusContent extends StatelessWidget {
  const _StatusContent({
    required this.contract,
    required this.onShowComingSoon,
    required this.onCopyLink,
  });

  final ContractEntity contract;
  final VoidCallback onShowComingSoon;
  final ValueChanged<String> onCopyLink;

  @override
  Widget build(BuildContext context) {
    final String? signingUrl = contract.signingUrl;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        18,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: <Widget>[
        _StatusLine(status: contract.status),
        const SizedBox(height: 14),
        Text(
          'Договор № ${contract.number}',
          style: AppTypography.compactScreenTitle.copyWith(
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${contract.guest.fullName} · ${contract.stay.propertyName}\n'
          '${contract.stay.datesAndNights}',
          style: AppTypography.body.copyWith(
            color: AppColors.secondaryText,
            height: 21 / 14,
          ),
        ),
        const SizedBox(height: AppSpacing.xLarge),
        ContractPdfRow(
          title: contract.document.name,
          details: contract.document.pagesAndSize,
          onOpen: onShowComingSoon,
        ),
        const SizedBox(height: AppSpacing.xLarge),
        Semantics(
          header: true,
          child: Text(
            'История',
            style: AppTypography.sectionTitle.copyWith(color: AppColors.text),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        ContractTimeline(steps: _timelineSteps()),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xSmall),
            child: Wrap(
              spacing: 20,
              children: <Widget>[
                ContractTextAction(
                  label: 'Скачать PDF',
                  onPressed: onShowComingSoon,
                ),
                if (signingUrl != null)
                  ContractTextAction(
                    label: 'Скопировать ссылку',
                    semanticLabel: 'Скопировать ссылку на подпись',
                    onPressed: () => onCopyLink(signingUrl),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The completed steps, oldest first, and the step the contract waits
  /// for.
  List<ContractTimelineStep> _timelineSteps() {
    final DateTime now = contract.receivedAt;
    final ContractTimelineStep? pending = switch (contract.status) {
      ContractStatus.draft => const ContractTimelineStep(
        title: 'Ожидаем отправку',
        subtitle: 'Отправьте договор гостю на подпись',
        isPending: true,
      ),
      ContractStatus.sent || ContractStatus.opened => ContractTimelineStep(
        title: 'Ожидаем подпись',
        subtitle:
            ContractTimeLabels.reminder(
              remindAt: contract.remindAt,
              now: now,
            ) ??
            'Гость ещё не подписал',
        isPending: true,
      ),
      ContractStatus.signed => null,
    };
    return <ContractTimelineStep>[
      for (final ContractHistoryEntryEntity entry in contract.history)
        ContractTimelineStep(
          title: entry.title,
          subtitle: entry.subtitle(now: now),
        ),
      ?pending,
    ];
  }
}

/// «● Ожидает подписи гостя»
final class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});

  final ContractStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = status.color;
    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: AppSpacing.small),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            status.label,
            style: AppTypography.compactBody.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
