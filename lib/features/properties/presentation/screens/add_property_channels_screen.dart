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
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_channels_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_add_property_draft_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/publish_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_channels_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_details_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/add_property_bloc/add_property_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/add_property_channel_row.dart';
import 'package:easy_booking/features/properties/presentation/widgets/add_property_step_layout.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_info_note.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_management_labels.dart';

/// Screen 14 «Подключите площадки», step 2 of 3: the channels whose
/// calendars the property joins. None is allowed; «Продолжить» saves the
/// choice and opens step 3.
///
/// Provides its own [AddPropertyBloc] through [wrappedRoute].
final class AddPropertyChannelsScreen extends StatefulWidget
    implements GoRouterWrapper {
  const AddPropertyChannelsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<AddPropertyBloc>(
      create: (_) => AddPropertyBloc(
        getDraft: dependencies.getDep<GetAddPropertyDraftUsecase>(),
        saveDetails: dependencies.getDep<SaveAddPropertyDetailsUsecase>(),
        saveChannels: dependencies.getDep<SaveAddPropertyChannelsUsecase>(),
        publish: dependencies.getDep<PublishPropertyUsecase>(),
      )..add(const AddPropertyStarted()),
      child: this,
    );
  }

  @override
  State<AddPropertyChannelsScreen> createState() =>
      _AddPropertyChannelsScreenState();
}

final class _AddPropertyChannelsScreenState
    extends State<AddPropertyChannelsScreen> {
  /// The connected channels in the order they were connected. Listened to
  /// by the channel rows only, so a toggle does not rebuild the screen.
  late final ValueNotifier<List<BookingChannel>> _channels;

  /// Whether [_channels] was taken from the draft; only done once.
  late bool _isPrefilled;

  @override
  void initState() {
    super.initState();
    _channels = ValueNotifier<List<BookingChannel>>(const <BookingChannel>[]);
    _isPrefilled = false;
  }

  @override
  void dispose() {
    _channels.dispose();
    super.dispose();
  }

  void _prefill(AddPropertyDraftEntity draft) {
    if (_isPrefilled) {
      return;
    }
    _isPrefilled = true;
    _channels.value = List<BookingChannel>.unmodifiable(draft.channels);
  }

  void _toggle(BookingChannel channel) {
    final List<BookingChannel> channels = _channels.value;
    _channels.value = List<BookingChannel>.unmodifiable(
      channels.contains(channel)
          ? channels.where((BookingChannel item) => item != channel)
          : <BookingChannel>[...channels, channel],
    );
  }

  void _submit() {
    context.read<AddPropertyBloc>().add(
      AddPropertyChannelsSubmitted(
        SaveAddPropertyChannelsParamsEntity(channels: _channels.value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<AddPropertyBloc, AddPropertyState>>[
        BlocListener<AddPropertyBloc, AddPropertyState>(
          listenWhen: (AddPropertyState previous, AddPropertyState current) =>
              previous.draftStatus != current.draftStatus &&
              current.draftStatus.isSuccess,
          listener: (BuildContext context, AddPropertyState state) {
            final AddPropertyDraftEntity? draft = state.draft;
            if (draft != null) {
              _prefill(draft);
            }
          },
        ),
        BlocListener<AddPropertyBloc, AddPropertyState>(
          listenWhen: (AddPropertyState previous, AddPropertyState current) =>
              previous.submitStatus != current.submitStatus &&
              (current.submitStatus.isSuccess || current.submitFailure != null),
          listener: (BuildContext context, AddPropertyState state) {
            if (state.submitStatus.isSuccess) {
              context.pushNamed(AppRoutes.addPropertyTerms.name);
              return;
            }
            context.showAppSnackbar(state.submitFailure!.propertyMessage);
          },
        ),
      ],
      child: BlocBuilder<AddPropertyBloc, AddPropertyState>(
        buildWhen: (AddPropertyState previous, AddPropertyState current) =>
            previous.draftStatus != current.draftStatus ||
            previous.draftFailure != current.draftFailure ||
            previous.draft != current.draft ||
            previous.submitStatus != current.submitStatus,
        builder: (BuildContext context, AddPropertyState state) {
          final bool isSubmitting = state.submitStatus.isLoading;
          final AddPropertyDraftEntity? draft = state.draft;
          return AddPropertyStepLayout(
            step: 2,
            title: 'Подключите площадки',
            subtitle: 'Брони появятся в общем календаре.',
            draftStatus: state.draftStatus,
            draftErrorMessage: state.draftFailure?.userMessage,
            onRetry: () => context.read<AddPropertyBloc>().add(
              const AddPropertyStarted(),
            ),
            onBack: () => context.pop(),
            footerMessage: 'Можно подключить площадки позже',
            primaryLabel: 'Продолжить',
            isSubmitting: isSubmitting,
            onPrimaryPressed: isSubmitting ? null : _submit,
            children: <Widget>[
              if (draft != null) _DraftCard(draft: draft),
              const SizedBox(height: AppSpacing.small),
              for (final BookingChannel channel in BookingChannel.values)
                _ChannelToggleRow(
                  channel: channel,
                  channels: _channels,
                  onPressed: isSubmitting ? null : () => _toggle(channel),
                ),
              const SizedBox(height: AppSpacing.large),
              const PropertyInfoNote(
                message:
                    'Возможности зависят от площадки. Если экспорта календаря '
                    'нет, добавляйте брони вручную.',
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The row of [channel]; follows the local selection in [channels].
final class _ChannelToggleRow extends StatelessWidget {
  const _ChannelToggleRow({
    required this.channel,
    required this.channels,
    required this.onPressed,
  });

  final BookingChannel channel;
  final ValueListenable<List<BookingChannel>> channels;

  /// `null` while saving.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BookingChannel>>(
      valueListenable: channels,
      builder:
          (BuildContext context, List<BookingChannel> connected, Widget? _) {
            return AddPropertyChannelRow(
              title: channel.title,
              description: channel.connectDescription,
              actionLabel: channel.connectActionLabel,
              isConnected: connected.contains(channel),
              onPressed: onPressed,
            );
          },
    );
  }
}

/// The property being added: a photo placeholder, the name, and the address
/// from step 1.
final class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});

  final AddPropertyDraftEntity draft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ExcludeSemantics(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.media)),
            ),
            child: SvgPicture.asset(AppAssets.icons.building),
          ),
        ),
        const SizedBox(width: AppSpacing.large),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xSmall,
            children: <Widget>[
              Text(
                draft.title,
                style: AppTypography.primaryText.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                draft.address,
                style: AppTypography.compactBody.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
