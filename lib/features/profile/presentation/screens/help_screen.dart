import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_search_field.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_help_center_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/help_bloc/help_bloc.dart';
import 'package:easy_booking/features/profile/presentation/widgets/help_guide_card.dart';
import 'package:easy_booking/features/profile/presentation/widgets/help_labels.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_detail_layout.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_footnote.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_list_row.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_section_label.dart';

/// Screen 35 «Помощь»: search, the support chat, FAQ topics, and guides.
/// The search filters the loaded content on the screen.
///
/// Provides its own [HelpBloc] through [wrappedRoute].
final class HelpScreen extends StatefulWidget implements GoRouterWrapper {
  const HelpScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<HelpBloc>(
      create: (_) =>
          HelpBloc(getHelpCenter: dependencies.getDep<GetHelpCenterUsecase>())
            ..add(const HelpRequested()),
      child: this,
    );
  }

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

final class _HelpScreenState extends State<HelpScreen> {
  late final TextEditingController _searchController;

  /// The search text; only the results listen to it, so typing never
  /// rebuilds the screen.
  late final ValueNotifier<String> _query;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onQueryChanged);
    _query = ValueNotifier<String>('');
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _query.dispose();
    super.dispose();
  }

  /// [ValueNotifier] notifies only when the text changed, not on cursor
  /// moves.
  void _onQueryChanged() {
    _query.value = _searchController.text;
  }

  @override
  Widget build(BuildContext context) {
    return ProfileDetailLayout(
      title: 'Помощь',
      body: _HelpBody(searchController: _searchController, query: _query),
      footer: AppFlowFooter(
        primaryLabel: 'Написать в поддержку',
        onPrimaryPressed: context.showComingSoon,
      ),
    );
  }
}

/// The skeleton or the load error until the help center is loaded, then
/// its content.
final class _HelpBody extends StatelessWidget {
  const _HelpBody({required this.searchController, required this.query});

  final TextEditingController searchController;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelpBloc, HelpState>(
      buildWhen: (HelpState previous, HelpState current) =>
          previous.helpCenter != current.helpCenter ||
          (current.helpCenter == null &&
              previous.loadFailure != current.loadFailure),
      builder: (BuildContext context, HelpState state) {
        final HelpCenterEntity? helpCenter = state.helpCenter;
        if (helpCenter != null) {
          return _HelpContent(
            helpCenter: helpCenter,
            searchController: searchController,
            query: query,
          );
        }
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          return ProfileLoadError(
            title: 'Не удалось загрузить помощь',
            failure: failure,
            onRetry: () => context.read<HelpBloc>().add(const HelpRequested()),
          );
        }
        return const ProfileListSkeleton(rowCount: 4);
      },
    );
  }
}

/// The search, the support chat, the filtered results, and the contact
/// footnote.
final class _HelpContent extends StatelessWidget {
  const _HelpContent({
    required this.helpCenter,
    required this.searchController,
    required this.query,
  });

  /// The support brand mark in the avatar.
  static const String _supportInitials = 'EB';

  final HelpCenterEntity helpCenter;
  final TextEditingController searchController;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        10,
        AppSizes.pageGutter,
        AppSpacing.xLarge,
      ),
      children: <Widget>[
        AppSearchField(
          controller: searchController,
          hint: 'Найти ответ',
          clearSemanticLabel: 'Очистить поиск',
        ),
        // The search never filters the support contact.
        _SupportRow(
          support: helpCenter.support,
          initials: _supportInitials,
          onTap: context.showComingSoon,
        ),
        _HelpResults(helpCenter: helpCenter, query: query),
        const SizedBox(height: 22),
        ProfileFootnote(
          icon: SvgPicture.asset(
            AppAssets.icons.helpCircle,
            width: 19,
            height: 19,
          ),
          text: 'Не нашли ответ?',
          isEmphasized: true,
          actionLabel: 'Связаться',
          onAction: context.showComingSoon,
        ),
      ],
    );
  }
}

/// The FAQ topics and guides matching [query], or «Ничего не нашли».
final class _HelpResults extends StatelessWidget {
  const _HelpResults({required this.helpCenter, required this.query});

  final HelpCenterEntity helpCenter;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: query,
      builder: (BuildContext context, String query, _) {
        final HelpCenterEntity visible = helpCenter.matching(query);
        final bool hasResults =
            visible.topics.isNotEmpty || visible.guides.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!hasResults)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xLarge),
                child: AppEmptyState(
                  title: 'Ничего не нашли',
                  message: 'Попробуйте другие слова или напишите в поддержку',
                  icon: SvgPicture.asset(AppAssets.icons.searchLarge),
                ),
              ),
            if (visible.topics.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xLarge),
              const ProfileSectionTitle(title: 'Частые вопросы'),
              const SizedBox(height: AppSpacing.small),
              for (final HelpTopicEntity topic in visible.topics)
                ProfileListRow(
                  title: topic.title,
                  subtitle: topic.summary,
                  trailing: const ProfileChevron(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: context.showComingSoon,
                ),
            ],
            if (visible.guides.isNotEmpty) ...<Widget>[
              const SizedBox(height: 26),
              const ProfileSectionTitle(title: 'Быстрые инструкции'),
              const SizedBox(height: AppSpacing.medium),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: <Widget>[
                      for (final HelpGuideEntity guide in visible.guides)
                        HelpGuideCard(
                          title: guide.title,
                          readingTime: guide.readingTimeLabel,
                          onTap: context.showComingSoon,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// «Поддержка EasyBooking» with its response time and online state.
final class _SupportRow extends StatelessWidget {
  const _SupportRow({
    required this.support,
    required this.initials,
    required this.onTap,
  });

  static const double _dotSize = 8;

  final SupportContactEntity support;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        value: support.isOnline ? 'В сети' : 'Не в сети',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.only(top: 20, bottom: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: <Widget>[
                ProfileAvatar(
                  initials: initials,
                  size: 48,
                  backgroundColor: AppColors.successSurface,
                  foregroundColor: AppColors.success,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: <Widget>[
                      Text(
                        support.name,
                        style: AppTypography.rowTitle.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        support.responseTimeLabel,
                        style: AppTypography.caption.copyWith(
                          height: 18 / 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                SizedBox.square(
                  dimension: _dotSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: support.isOnline
                          ? AppColors.success
                          : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
