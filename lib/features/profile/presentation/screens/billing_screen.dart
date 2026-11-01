import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/invoice_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/payment_card_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/change_subscription_plan_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_billing_overview_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/billing_bloc/billing_bloc.dart';
import 'package:easy_booking/features/profile/presentation/widgets/billing_labels.dart';
import 'package:easy_booking/features/profile/presentation/widgets/plan_usage_bar.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_accent_block.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_detail_layout.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_failure_message.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_labels.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_section_label.dart';

/// Screen 34 «Тариф и оплата»: the plan, its limits and features, the
/// payment card, and the latest invoice. «Управлять тарифом» opens a plan
/// choice.
///
/// Provides its own [BillingBloc] through [wrappedRoute].
final class BillingScreen extends StatelessWidget implements GoRouterWrapper {
  const BillingScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<BillingBloc>(
      create: (_) => BillingBloc(
        getBillingOverview: dependencies.getDep<GetBillingOverviewUsecase>(),
        changeSubscriptionPlan: dependencies
            .getDep<ChangeSubscriptionPlanUsecase>(),
      )..add(const BillingRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<BillingBloc, BillingState>>[
        BlocListener<BillingBloc, BillingState>(
          listenWhen: (BillingState previous, BillingState current) =>
              previous.changePlanStatus != current.changePlanStatus &&
              (current.changePlanStatus.isSuccess ||
                  current.changePlanStatus.isFailure),
          listener: (BuildContext context, BillingState state) {
            final Failure? failure = state.changePlanFailure;
            context.showAppSnackbar(
              failure == null ? 'Тариф изменён' : failure.profileMessage,
            );
          },
        ),
        // Only a failed refresh: the first failure replaces the overview.
        BlocListener<BillingBloc, BillingState>(
          listenWhen: (BillingState previous, BillingState current) =>
              previous.loadStatus != current.loadStatus &&
              current.loadStatus.isFailure &&
              current.overview != null,
          listener: (BuildContext context, BillingState state) {
            context.showAppSnackbar(state.loadFailure!.profileMessage);
          },
        ),
      ],
      child: const ProfileDetailLayout(
        title: 'Тариф и оплата',
        body: _BillingBody(),
        footer: _ManagePlanFooter(),
      ),
    );
  }
}

/// «Управлять тарифом»: enabled once the overview is loaded, busy while the
/// plan changes.
final class _ManagePlanFooter extends StatelessWidget {
  const _ManagePlanFooter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BillingBloc, BillingState, (SubscriptionPlan?, bool)>(
      selector: (BillingState state) =>
          (state.overview?.plan, state.changePlanStatus.isLoading),
      builder: (BuildContext context, (SubscriptionPlan?, bool) planState) {
        final (SubscriptionPlan? plan, bool isChanging) = planState;
        return AppFlowFooter(
          message: 'Отмена доступна до следующего расчётного периода.',
          messageStyle: AppTypography.caption.copyWith(
            height: 18 / 12,
            color: AppColors.secondaryText,
          ),
          primaryLabel: 'Управлять тарифом',
          primaryLoading: isChanging,
          onPrimaryPressed: plan == null || isChanging
              ? null
              : () => _choosePlan(context, plan),
        );
      },
    );
  }

  Future<void> _choosePlan(
    BuildContext context,
    SubscriptionPlan currentPlan,
  ) async {
    final BillingBloc bloc = context.read<BillingBloc>();
    final SubscriptionPlan? plan = await showModalBottomSheet<SubscriptionPlan>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => _PlanChoiceSheet(currentPlan: currentPlan),
    );
    if (plan != null && plan != currentPlan) {
      bloc.add(BillingPlanChangeRequested(plan));
    }
  }
}

/// «Выберите тариф»: pops with the chosen plan.
final class _PlanChoiceSheet extends StatelessWidget {
  const _PlanChoiceSheet({required this.currentPlan});

  final SubscriptionPlan currentPlan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pageGutter,
          AppSpacing.xLarge,
          AppSizes.pageGutter,
          AppSpacing.small,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ProfileSectionTitle(title: 'Выберите тариф'),
            const SizedBox(height: AppSpacing.small),
            for (final SubscriptionPlan option in SubscriptionPlan.values)
              Semantics(
                selected: option == currentPlan,
                child: AppProfileMenuItem(
                  title: option.label,
                  subtitle: option.description,
                  showDivider: option != SubscriptionPlan.values.last,
                  trailing: option == currentPlan
                      ? SvgPicture.asset(
                          AppAssets.icons.checkSuccess,
                          width: AppSizes.iconAction,
                          height: AppSizes.iconAction,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The skeleton or the load error until the overview is loaded, then the
/// overview.
final class _BillingBody extends StatelessWidget {
  const _BillingBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingBloc, BillingState>(
      buildWhen: (BillingState previous, BillingState current) =>
          previous.overview != current.overview ||
          (current.overview == null &&
              previous.loadFailure != current.loadFailure),
      builder: (BuildContext context, BillingState state) {
        final BillingOverviewEntity? overview = state.overview;
        if (overview != null) {
          return _BillingOverviewList(overview: overview);
        }
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          return ProfileLoadError(
            title: 'Не удалось загрузить тариф',
            failure: failure,
            onRetry: () =>
                context.read<BillingBloc>().add(const BillingRequested()),
          );
        }
        return const ProfileListSkeleton(rowCount: 4);
      },
    );
  }
}

/// The plan, usage, features, and payment, with pull-to-refresh.
final class _BillingOverviewList extends StatelessWidget {
  const _BillingOverviewList({required this.overview});

  final BillingOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final PaymentCardEntity? card = overview.paymentCard;
    final InvoiceEntity? invoice = overview.latestInvoice;

    return RefreshIndicator.adaptive(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pageGutter,
          14,
          AppSizes.pageGutter,
          AppSpacing.xLarge,
        ),
        children: <Widget>[
          _PlanSummary(overview: overview),
          const SizedBox(height: AppSpacing.xLarge),
          const ProfileSectionTitle(title: 'Использование'),
          const SizedBox(height: AppSpacing.large),
          PlanUsageBar(
            label: 'Объекты',
            valueLabel: overview.propertyUsage.label,
            fraction: overview.propertyUsage.fraction,
            isAtLimit: overview.propertyUsage.isAtLimit,
          ),
          const SizedBox(height: 14),
          PlanUsageBar(
            label: 'Участники команды',
            valueLabel: overview.memberUsage.label,
            fraction: overview.memberUsage.fraction,
            isAtLimit: overview.memberUsage.isAtLimit,
          ),
          if (overview.includedFeatures.isNotEmpty) ...<Widget>[
            const SizedBox(height: 26),
            const ProfileSectionTitle(title: 'Включено в тариф'),
            const SizedBox(height: 9),
            for (final String feature in overview.includedFeatures)
              _IncludedFeatureRow(feature: feature),
          ],
          const SizedBox(height: AppSpacing.xLarge),
          const ProfileSectionTitle(title: 'Оплата'),
          _PaymentCardRow(card: card, onChange: context.showComingSoon),
          if (invoice != null)
            _InvoiceRow(invoice: invoice, onOpen: context.showComingSoon),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context) {
    final BillingBloc bloc = context.read<BillingBloc>();
    bloc.add(const BillingRequested());
    return bloc.stream.firstWhere(
      (BillingState state) => !state.loadStatus.isLoading,
    );
  }
}

/// The plan name with its state, price, and next charge.
final class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.overview});

  final BillingOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final String? nextCharge = overview.nextChargeLabel;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 22),
        child: ProfileAccentBlock(
          color: AppColors.accent,
          gap: AppSpacing.large,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      overview.plan.label,
                      style: AppTypography.smallScreenTitle.copyWith(
                        letterSpacing: -0.48,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Text(
                    overview.isActive ? 'Активен' : 'Не активен',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 16 / 12,
                      color: overview.isActive
                          ? AppColors.success
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              Text(
                overview.priceLabel,
                style: AppTypography.body.copyWith(
                  height: 18 / 14,
                  color: AppColors.text,
                ),
              ),
              if (nextCharge != null)
                Text(
                  nextCharge,
                  style: AppTypography.caption.copyWith(
                    height: 16 / 12,
                    color: AppColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _IncludedFeatureRow extends StatelessWidget {
  const _IncludedFeatureRow({required this.feature});

  static const double _badgeSize = 20;

  final String feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: Container(
              width: _badgeSize,
              height: _badgeSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.successSurface,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                AppAssets.icons.checkSuccess,
                width: AppSpacing.medium,
                height: AppSpacing.medium,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: AppTypography.compactBody.copyWith(
                height: 19 / 13,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The card the plan is charged to, or a prompt to add one.
final class _PaymentCardRow extends StatelessWidget {
  const _PaymentCardRow({required this.card, required this.onChange});

  final PaymentCardEntity? card;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final PaymentCardEntity? card = this.card;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            if (card != null) ...<Widget>[
              Container(
                width: 46,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadii.field),
                  ),
                ),
                child: Text(
                  card.brandLabel,
                  textScaler: TextScaler.noScaling,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 14 / 11,
                    color: AppColors.info,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
            ],
            Expanded(
              child: Text(
                card?.maskedNumber ?? 'Карта не привязана',
                style: AppTypography.body.copyWith(
                  height: 18 / 14,
                  color: card == null
                      ? AppColors.secondaryText
                      : AppColors.text,
                ),
              ),
            ),
            AppTextButton.underlined(
              label: card == null ? 'Добавить' : 'Изменить',
              onPressed: onChange,
            ),
          ],
        ),
      ),
    );
  }
}

/// «Счёт за октябрь», its amount, and the PDF link.
final class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.onOpen});

  final InvoiceEntity invoice;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.compactBody.copyWith(height: 16 / 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              invoice.title,
              style: style.copyWith(color: AppColors.text),
            ),
          ),
          Text(
            invoice.amountLabel,
            style: style.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(width: AppSpacing.large),
          AppTextButton.underlined(label: 'PDF', onPressed: onOpen),
        ],
      ),
    );
  }
}
