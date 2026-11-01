import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_key_value_list.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_progress_app_bar.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_stay_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_send_bloc/contract_send_bloc.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_file_cards.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_labels.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_load_placeholders.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_recipient_sheet.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_stay_card.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_text_action.dart';

/// Screen 08 «Новый договор · 2 из 2 · Условия и подпись»: the stay terms,
/// the contract file, and where the signing link goes. After sending it
/// opens the contract status in place of the flow.
///
/// Provides its own [ContractSendBloc] through [wrappedRoute].
final class ContractSendScreen extends StatefulWidget
    implements GoRouterWrapper {
  const ContractSendScreen({required this.contractId, super.key});

  final String contractId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<ContractSendBloc>(
      create: (_) => ContractSendBloc(
        getContract: dependencies.getDep<GetContractUsecase>(),
        sendContract: dependencies.getDep<SendContractUsecase>(),
      )..add(ContractSendRequested(contractId)),
      child: this,
    );
  }

  @override
  State<ContractSendScreen> createState() => _ContractSendScreenState();
}

final class _ContractSendScreenState extends State<ContractSendScreen> {
  /// The recipient chosen in «Изменить»; `null` keeps the contract's own.
  /// A notifier, so a new choice rebuilds only the recipient lines.
  late final ValueNotifier<ContractRecipientEntity?> _chosenRecipient;

  @override
  void initState() {
    super.initState();
    _chosenRecipient = ValueNotifier<ContractRecipientEntity?>(null);
  }

  @override
  void dispose() {
    _chosenRecipient.dispose();
    super.dispose();
  }

  ContractRecipientEntity _recipientOf(ContractEntity contract) {
    return _chosenRecipient.value ?? contract.recipient;
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.today.name);
    }
  }

  void _openStatus() {
    context.goNamed(
      AppRoutes.contractStatus.name,
      pathParameters: <String, String>{
        AppRoutes.contractIdParam: widget.contractId,
      },
    );
  }

  void _openBooking(ContractStayEntity stay) {
    context.pushNamed(
      AppRoutes.booking.name,
      pathParameters: <String, String>{
        AppRoutes.bookingIdParam: stay.bookingId,
      },
    );
  }

  void _retry() {
    context.read<ContractSendBloc>().add(
      ContractSendRequested(widget.contractId),
    );
  }

  Future<void> _editRecipient(ContractEntity contract) async {
    final ContractRecipientEntity? recipient =
        await showModalBottomSheet<ContractRecipientEntity>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: AppColors.background,
          builder: (_) => ContractRecipientSheet(
            initialRecipient: _recipientOf(contract),
            guestPhone: contract.guest.phone,
          ),
        );
    if (!mounted || recipient == null) {
      return;
    }
    _chosenRecipient.value = recipient;
  }

  void _send(ContractEntity contract) {
    final ContractRecipientEntity recipient = _recipientOf(contract);
    context.read<ContractSendBloc>().add(
      ContractSendSubmitted(
        SendContractParamsEntity(
          contractId: widget.contractId,
          channel: recipient.channel,
          address: recipient.address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<ContractSendBloc, ContractSendState>>[
        BlocListener<ContractSendBloc, ContractSendState>(
          listenWhen: (ContractSendState previous, ContractSendState current) =>
              previous.sendStatus != current.sendStatus &&
              current.sendStatus.isSuccess,
          listener: (BuildContext context, ContractSendState state) {
            _openStatus();
          },
        ),
        BlocListener<ContractSendBloc, ContractSendState>(
          listenWhen: (ContractSendState previous, ContractSendState current) =>
              previous.sendFailure != current.sendFailure &&
              current.sendFailure != null,
          listener: (BuildContext context, ContractSendState state) {
            context.showAppSnackbar(state.sendFailure!.contractMessage);
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppProgressAppBar(
                title: 'Новый договор',
                currentStep: 2,
                totalSteps: 2,
                backSemanticLabel: 'Назад',
                showDivider: false,
                onBack: _close,
              ),
              Expanded(
                child: _SendBody(
                  chosenRecipient: _chosenRecipient,
                  onRetry: _retry,
                  onOpenBooking: _openBooking,
                  onEditRecipient: _editRecipient,
                  onSend: _send,
                  onOpenStatus: _openStatus,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The skeleton or load error until the contract arrives, then the terms
/// and their footer.
final class _SendBody extends StatelessWidget {
  const _SendBody({
    required this.chosenRecipient,
    required this.onRetry,
    required this.onOpenBooking,
    required this.onEditRecipient,
    required this.onSend,
    required this.onOpenStatus,
  });

  final ValueListenable<ContractRecipientEntity?> chosenRecipient;
  final VoidCallback onRetry;
  final ValueChanged<ContractStayEntity> onOpenBooking;
  final ValueChanged<ContractEntity> onEditRecipient;
  final ValueChanged<ContractEntity> onSend;
  final VoidCallback onOpenStatus;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ContractSendBloc, ContractSendState, ContractEntity?>(
      selector: (ContractSendState state) => state.contract,
      builder: (BuildContext context, ContractEntity? contract) {
        if (contract == null) {
          return _SendPlaceholder(onRetry: onRetry);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _SendContent(
                contract: contract,
                chosenRecipient: chosenRecipient,
                onOpenBooking: onOpenBooking,
                onEditRecipient: onEditRecipient,
              ),
            ),
            if (contract.status.canSend)
              _SendFooter(onSend: () => onSend(contract))
            else
              _SignedFooter(onOpenStatus: onOpenStatus),
          ],
        );
      },
    );
  }
}

/// [ContractSkeleton] while loading, [ContractLoadError] after a failure.
final class _SendPlaceholder extends StatelessWidget {
  const _SendPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ContractSendBloc, ContractSendState, Failure?>(
      selector: (ContractSendState state) => state.loadFailure,
      builder: (BuildContext context, Failure? failure) {
        if (failure == null) {
          return const ContractSkeleton();
        }
        return ContractLoadError(failure: failure, onRetry: onRetry);
      },
    );
  }
}

/// «Договор уже подписан» with a link to the status.
final class _SignedFooter extends StatelessWidget {
  const _SignedFooter({required this.onOpenStatus});

  final VoidCallback onOpenStatus;

  @override
  Widget build(BuildContext context) {
    return AppFlowFooter(
      message: 'Договор уже подписан',
      messageStyle: AppTypography.caption.copyWith(
        color: AppColors.secondaryText,
      ),
      primaryLabel: 'Статус договора',
      onPrimaryPressed: onOpenStatus,
    );
  }
}

/// «Отправить на подпись», busy while sending.
final class _SendFooter extends StatelessWidget {
  const _SendFooter({required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    // Stays busy after success until the status screen replaces this one.
    return BlocSelector<ContractSendBloc, ContractSendState, bool>(
      selector: (ContractSendState state) =>
          state.sendStatus.isLoading || state.sendStatus.isSuccess,
      builder: (BuildContext context, bool isBusy) {
        return AppFlowFooter(
          message: 'Статус подписи появится в карточке брони',
          messageStyle: AppTypography.caption.copyWith(
            color: AppColors.secondaryText,
          ),
          primaryLabel: 'Отправить на подпись',
          onPrimaryPressed: isBusy ? null : onSend,
          primaryLoading: isBusy,
        );
      },
    );
  }
}

/// The stay, the price, the contract file, and who receives the link.
final class _SendContent extends StatelessWidget {
  const _SendContent({
    required this.contract,
    required this.chosenRecipient,
    required this.onOpenBooking,
    required this.onEditRecipient,
  });

  final ContractEntity contract;
  final ValueListenable<ContractRecipientEntity?> chosenRecipient;
  final ValueChanged<ContractStayEntity> onOpenBooking;
  final ValueChanged<ContractEntity> onEditRecipient;

  @override
  Widget build(BuildContext context) {
    final ContractStayEntity stay = contract.stay;
    final String nightsLabel = Plural.format(
      stay.nights,
      one: 'ночь',
      few: 'ночи',
      many: 'ночей',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        20,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: <Widget>[
        Text(
          'Условия и подпись',
          style: AppTypography.compactScreenTitle.copyWith(
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'Договор № ${contract.number} · ${contract.status.shortLabel}',
          style: AppTypography.body.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: AppSpacing.xLarge),
        ContractStayCard(
          imagePath: stay.imageUrl,
          title: stay.propertyTitle,
          dates: stay.datesAndNights,
          guestName: contract.guest.fullName,
          onTap: () => onOpenBooking(stay),
        ),
        const SizedBox(height: AppSpacing.xLarge),
        AppKeyValueList(
          rows: <AppKeyValueRow>[
            AppKeyValueRow(
              label:
                  'Аренда · ${MoneyFormatter.tenge(stay.pricePerNight)} × '
                  '$nightsLabel',
              value: MoneyFormatter.tenge(stay.rentTotal),
            ),
            AppKeyValueRow(
              label: 'Возвратный депозит',
              value: MoneyFormatter.tenge(stay.deposit),
            ),
            AppKeyValueRow(
              label: 'Заезд / выезд',
              value: stay.checkInOutTimes,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xLarge),
        ContractDocumentPreview(
          title: contract.document.name,
          details: contract.document.pagesAndLanguage,
          onOpen: () => context.showAppSnackbar(contractsComingSoonMessage),
        ),
        const SizedBox(height: AppSpacing.xLarge),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Кому отправить',
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.text,
                ),
              ),
            ),
            if (contract.status.canSend)
              ContractTextAction(
                label: 'Изменить',
                semanticLabel: 'Изменить получателя',
                onPressed: () => onEditRecipient(contract),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        ValueListenableBuilder<ContractRecipientEntity?>(
          valueListenable: chosenRecipient,
          builder:
              (
                BuildContext context,
                ContractRecipientEntity? chosen,
                Widget? child,
              ) {
                return _RecipientDetails(
                  guestFirstName: contract.guest.firstName,
                  recipient: chosen ?? contract.recipient,
                );
              },
        ),
      ],
    );
  }
}

/// «Алия · +7 700 ••• 45 21» and how the signing link is delivered.
final class _RecipientDetails extends StatelessWidget {
  const _RecipientDetails({
    required this.guestFirstName,
    required this.recipient,
  });

  final String guestFirstName;
  final ContractRecipientEntity recipient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$guestFirstName · ${recipient.maskedAddress}',
          style: AppTypography.body.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          recipient.channel.linkDescription,
          style: AppTypography.compactBody.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
