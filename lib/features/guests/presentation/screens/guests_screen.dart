import 'package:flutter/foundation.dart';
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
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_directory_usecase.dart';
import 'package:easy_booking/features/guests/presentation/bloc/guests_bloc/guests_bloc.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_contract_row.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_labels.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_row.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guests_search_field.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guests_segmented_control.dart';

/// Screen 24 «Гости и договоры»: recent guests or search results, and the
/// contracts, switched by a segmented control. The search runs in
/// [GuestsBloc]; the tab is local to the screen.
///
/// Provides its own [GuestsBloc] through [wrappedRoute].
final class GuestsScreen extends StatefulWidget implements GoRouterWrapper {
  const GuestsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<GuestsBloc>(
      create: (_) => GuestsBloc(
        getDirectory: dependencies.getDep<GetGuestDirectoryUsecase>(),
      )..add(const GuestsRequested()),
      child: this,
    );
  }

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

enum _GuestsTab {
  guests('Гости'),
  contracts('Договоры');

  const _GuestsTab(this.label);

  final String label;
}

final class _GuestsScreenState extends State<GuestsScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ValueNotifier<_GuestsTab> _tab;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode(debugLabel: 'GuestsSearch');
    _tab = ValueNotifier<_GuestsTab>(_GuestsTab.guests);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // Only a failed refresh or search: the first failure replaces the
        // list.
        child: BlocListener<GuestsBloc, GuestsState>(
          listenWhen: (GuestsState previous, GuestsState current) =>
              previous.loadStatus != current.loadStatus &&
              current.loadStatus.isFailure &&
              current.hasLoaded,
          listener: (BuildContext context, GuestsState state) {
            context.showAppSnackbar(state.loadFailure!.userMessage);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _GuestsHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pageGutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ValueListenableBuilder<_GuestsTab>(
                      valueListenable: _tab,
                      builder: (BuildContext context, _GuestsTab tab, _) {
                        return GuestsSegmentedControl(
                          labels: <String>[
                            for (final _GuestsTab tab in _GuestsTab.values)
                              tab.label,
                          ],
                          selectedIndex: tab.index,
                          onSelected: (int index) =>
                              _tab.value = _GuestsTab.values[index],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.small),
                    GuestsSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (String query) => context
                          .read<GuestsBloc>()
                          .add(GuestsQueryChanged(query)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _GuestsBody(
                  tab: _tab,
                  onGuestTap: _openGuest,
                  onContractTap: _openContract,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGuest(String guestId) {
    _open(AppRoutes.guest, <String, String>{AppRoutes.guestIdParam: guestId});
  }

  void _openContract(String contractId) {
    _open(AppRoutes.contract, <String, String>{
      AppRoutes.contractIdParam: contractId,
    });
  }

  /// Reloads on return: a contract may have been signed or created there.
  Future<void> _open(AppRoutes route, Map<String, String> parameters) async {
    final GuestsBloc bloc = context.read<GuestsBloc>();
    context.hideKeyboard();
    await context.pushNamed(route.name, pathParameters: parameters);
    if (!mounted) {
      return;
    }
    bloc.add(const GuestsRequested());
  }
}

/// The title row with back and «Добавить гостя»; reads no state.
final class _GuestsHeader extends StatelessWidget {
  const _GuestsHeader();

  @override
  Widget build(BuildContext context) {
    return AppDetailHeader(
      title: 'Гости и договоры',
      backSemanticLabel: 'Назад',
      showDivider: false,
      onBack: () => context.pop(),
      action: AppIconButton(
        semanticLabel: 'Добавить гостя',
        onPressed: () => context.showAppSnackbar(guestsComingSoonMessage),
        icon: SvgPicture.asset(
          AppAssets.icons.plus,
          width: AppSizes.iconAction,
          height: AppSizes.iconAction,
          colorFilter: const ColorFilter.mode(
            AppColors.secondaryText,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

/// The list area: the directory once loaded, otherwise the first-load
/// failure or the skeleton. Rebuilds only when what it shows changes.
final class _GuestsBody extends StatelessWidget {
  const _GuestsBody({
    required this.tab,
    required this.onGuestTap,
    required this.onContractTap,
  });

  final ValueListenable<_GuestsTab> tab;
  final ValueChanged<String> onGuestTap;
  final ValueChanged<String> onContractTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuestsBloc, GuestsState>(
      buildWhen: (GuestsState previous, GuestsState current) =>
          previous.directory != current.directory ||
          previous.loadFailure != current.loadFailure ||
          previous.query != current.query,
      builder: (BuildContext context, GuestsState state) {
        final GuestDirectoryEntity? directory = state.directory;
        if (directory != null) {
          return _GuestsDirectory(
            directory: directory,
            isSearching: state.isSearching,
            tab: tab,
            onGuestTap: onGuestTap,
            onContractTap: onContractTap,
          );
        }
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          return _GuestsLoadError(failure: failure);
        }
        return const _GuestsSkeleton();
      },
    );
  }
}

/// The first load failed: the message and «Повторить».
final class _GuestsLoadError extends StatelessWidget {
  const _GuestsLoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        AppEmptyState(
          title: 'Не удалось загрузить гостей',
          message: failure.userMessage,
          icon: SvgPicture.asset(AppAssets.icons.alertCircle),
          actionLabel: 'Повторить',
          onAction: () =>
              context.read<GuestsBloc>().add(const GuestsRequested()),
        ),
      ],
    );
  }
}

/// The pull-to-refresh list of the selected tab.
final class _GuestsDirectory extends StatelessWidget {
  const _GuestsDirectory({
    required this.directory,
    required this.isSearching,
    required this.tab,
    required this.onGuestTap,
    required this.onContractTap,
  });

  final GuestDirectoryEntity directory;
  final bool isSearching;
  final ValueListenable<_GuestsTab> tab;
  final ValueChanged<String> onGuestTap;
  final ValueChanged<String> onContractTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: () {
        final GuestsBloc bloc = context.read<GuestsBloc>();
        bloc.add(const GuestsRequested());
        return bloc.stream.firstWhere(
          (GuestsState state) => !state.loadStatus.isLoading,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: <Widget>[
          ValueListenableBuilder<_GuestsTab>(
            valueListenable: tab,
            builder: (BuildContext context, _GuestsTab tab, _) {
              return switch (tab) {
                _GuestsTab.guests => _GuestsList(
                  directory: directory,
                  isSearching: isSearching,
                  onGuestTap: onGuestTap,
                ),
                _GuestsTab.contracts => _ContractsList(
                  contracts: directory.contracts,
                  isSearching: isSearching,
                  onContractTap: onContractTap,
                ),
              };
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xLarge),
          ),
        ],
      ),
    );
  }
}

/// The «Гости» tab as a sliver: the header, then the guests or an empty
/// state.
final class _GuestsList extends StatelessWidget {
  const _GuestsList({
    required this.directory,
    required this.isSearching,
    required this.onGuestTap,
  });

  final GuestDirectoryEntity directory;
  final bool isSearching;
  final ValueChanged<String> onGuestTap;

  @override
  Widget build(BuildContext context) {
    final List<GuestSummaryEntity> guests = directory.guests;
    final _ListHeader header = _ListHeader(
      title: isSearching ? 'Результаты поиска' : 'Недавние гости',
      count: GuestCountLabels.guests(
        isSearching ? guests.length : directory.totalGuestCount,
      ),
    );
    if (guests.isEmpty) {
      return SliverList.list(
        children: <Widget>[
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pageGutter,
              AppSpacing.small,
              AppSizes.pageGutter,
              0,
            ),
            child: isSearching
                ? const AppEmptyState(
                    title: 'Никого не нашли',
                    message: 'Проверьте имя, телефон или название объекта',
                  )
                : AppEmptyState(
                    title: 'Гостей пока нет',
                    message: 'Здесь появятся гости ваших бронирований',
                    icon: SvgPicture.asset(AppAssets.icons.users),
                  ),
          ),
        ],
      );
    }
    return SliverList.builder(
      itemCount: guests.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return header;
        }
        final GuestSummaryEntity guest = guests[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
          child: GuestRow(
            guest: guest,
            now: directory.receivedAt,
            showBottomDivider: index == guests.length,
            onTap: () => onGuestTap(guest.id),
          ),
        );
      },
    );
  }
}

/// The «Договоры» tab as a sliver: the header, then the contracts or an
/// empty state.
final class _ContractsList extends StatelessWidget {
  const _ContractsList({
    required this.contracts,
    required this.isSearching,
    required this.onContractTap,
  });

  final List<GuestContractEntity> contracts;
  final bool isSearching;
  final ValueChanged<String> onContractTap;

  @override
  Widget build(BuildContext context) {
    final _ListHeader header = _ListHeader(
      title: isSearching ? 'Результаты поиска' : 'Все договоры',
      count: GuestCountLabels.contracts(contracts.length),
    );
    if (contracts.isEmpty) {
      return SliverList.list(
        children: <Widget>[
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pageGutter,
              AppSpacing.small,
              AppSizes.pageGutter,
              0,
            ),
            child: isSearching
                ? const AppEmptyState(
                    title: 'Договоров не нашли',
                    message: 'Проверьте номер договора, имя гостя или объект',
                  )
                : AppEmptyState(
                    title: 'Договоров пока нет',
                    message: 'Создайте договор на странице гостя',
                    icon: SvgPicture.asset(AppAssets.icons.fileText),
                  ),
          ),
        ],
      );
    }
    return SliverList.builder(
      itemCount: contracts.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return header;
        }
        final GuestContractEntity contract = contracts[index - 1];
        return GuestContractRow(
          contract: contract,
          details: contract.guestDetails,
          onTap: () => onContractTap(contract.id),
        );
      },
    );
  }
}

/// «Недавние гости» with the guest count on the right.
final class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title, required this.count});

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        18,
        AppSizes.pageGutter,
        AppSpacing.small,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle.copyWith(
                  height: 22 / 18,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Text(
            count,
            style: AppTypography.caption.copyWith(
              height: 16 / 12,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

final class _GuestsSkeleton extends StatelessWidget {
  const _GuestsSkeleton();

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
            AppSkeleton(height: 22, width: 150),
            Spacer(),
            AppSkeleton(height: 14, width: 60),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        for (int index = 0; index < 4; index++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: <Widget>[
                AppSkeleton(height: 44, width: 44),
                SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppSkeleton(height: 14, width: 150),
                      SizedBox(height: AppSpacing.small),
                      AppSkeleton(
                        height: 12,
                        width: 190,
                        borderRadius: AppRadii.field,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.medium),
                AppSkeleton(height: 12, width: 64),
              ],
            ),
          ),
      ],
    );
  }
}
