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
import 'package:easy_booking/core/presentation/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_progress_app_bar.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_availability_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/presentation/bloc/booking_create_bloc/booking_create_bloc.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_failure_message.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_form_layout.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_labels.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_toggle_row.dart';

/// Screen 19 «Новая бронь · 2 из 2», «Цена и источник»: the price, the
/// deposit, and the source of the draft saved on step 1, and whether to
/// create a contract. Creates the booking and opens it.
///
/// Provides its own [BookingCreateBloc] through [wrappedRoute].
final class NewBookingPriceScreen extends StatefulWidget
    implements GoRouterWrapper {
  const NewBookingPriceScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<BookingCreateBloc>(
      create: (_) => BookingCreateBloc(
        getDraft: dependencies.getDep<GetBookingDraftUsecase>(),
        createBooking: dependencies.getDep<CreateBookingUsecase>(),
      )..add(const BookingCreateStarted()),
      child: this,
    );
  }

  @override
  State<NewBookingPriceScreen> createState() => _NewBookingPriceScreenState();
}

final class _NewBookingPriceScreenState extends State<NewBookingPriceScreen> {
  late final GlobalKey<FormState> _formKey;

  late final TextEditingController _totalPriceController;
  late final TextEditingController _depositController;
  late final TextEditingController _commentController;

  late final FocusNode _totalPriceFocusNode;
  late final FocusNode _depositFocusNode;
  late final FocusNode _commentFocusNode;

  /// Local choices: notifiers, so changing one rebuilds only its control.
  late final ValueNotifier<BookingSource> _source;
  late final ValueNotifier<bool> _createContract;

  /// Whether the amounts were filled from the draft's quote; it happens
  /// once.
  late bool _isPrefilled;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _totalPriceController = TextEditingController();
    _depositController = TextEditingController();
    _commentController = TextEditingController();
    _totalPriceFocusNode = FocusNode();
    _depositFocusNode = FocusNode();
    _commentFocusNode = FocusNode();
    _source = ValueNotifier<BookingSource>(BookingSource.direct);
    _createContract = ValueNotifier<bool>(true);
    _isPrefilled = false;
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _depositController.dispose();
    _commentController.dispose();
    _totalPriceFocusNode.dispose();
    _depositFocusNode.dispose();
    _commentFocusNode.dispose();
    _source.dispose();
    _createContract.dispose();
    super.dispose();
  }

  /// Back to step 1, which keeps its form.
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.newBooking.name);
    }
  }

  void _onFieldEdited(String field) {
    context.read<BookingCreateBloc>().add(BookingCreateFieldEdited(field));
  }

  void _onLoaded(BuildContext context, BookingCreateState state) {
    final BookingDraftEntity? draft = state.draft;
    if (draft == null) {
      // Nothing to price: the draft was used or replaced. Start over.
      context.goNamed(AppRoutes.newBooking.name);
      return;
    }
    if (_isPrefilled) {
      return;
    }
    _isPrefilled = true;
    _totalPriceController.text = MoneyFormatter.group(
      draft.suggestedTotalPrice,
    );
    _depositController.text = MoneyFormatter.group(draft.suggestedDeposit);
  }

  void _onSourceSelected(BookingSource source) {
    if (source == _source.value) {
      return;
    }
    _source.value = source;
    _onFieldEdited(BookingFields.source);
  }

  void _onCreateContractChanged(bool value) {
    _createContract.value = value;
  }

  void _submit() {
    context.hideKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final BookingCreateBloc bloc = context.read<BookingCreateBloc>();
    final BookingDraftEntity? draft = bloc.state.draft;
    // The validators guarantee both amounts once the form is valid.
    final int? totalPrice = MoneyFormatter.tryParse(_totalPriceController.text);
    final int? deposit = MoneyFormatter.tryParse(_depositController.text);
    if (draft == null || totalPrice == null || deposit == null) {
      return;
    }
    final String comment = _commentController.text.trim();
    bloc.add(
      BookingCreateSubmitted(
        CreateBookingParamsEntity(
          draftId: draft.id,
          totalPrice: totalPrice,
          deposit: deposit,
          source: _source.value,
          createContract: _createContract.value,
          comment: comment.isEmpty ? null : comment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Built once: the subtitle selector below rebuilds only the layout and
    // passes these same instances back, so their subtrees are skipped.
    final PreferredSizeWidget header = AppProgressAppBar(
      title: 'Новая бронь',
      currentStep: 2,
      totalSteps: 2,
      backSemanticLabel: 'Назад',
      showDivider: false,
      onBack: _back,
    );
    final Widget body = _PriceBody(
      form: _PriceForm(
        totalPriceController: _totalPriceController,
        depositController: _depositController,
        commentController: _commentController,
        totalPriceFocusNode: _totalPriceFocusNode,
        depositFocusNode: _depositFocusNode,
        commentFocusNode: _commentFocusNode,
        source: _source,
        createContract: _createContract,
        onFieldEdited: _onFieldEdited,
        onSourceSelected: _onSourceSelected,
        onCreateContractChanged: _onCreateContractChanged,
        onChangeDates: _back,
      ),
    );
    final Widget footer = _PriceFooter(onBack: _back, onSubmit: _submit);

    return MultiBlocListener(
      listeners: <BlocListener<BookingCreateBloc, BookingCreateState>>[
        BlocListener<BookingCreateBloc, BookingCreateState>(
          listenWhen:
              (BookingCreateState previous, BookingCreateState current) =>
                  previous.loadStatus != current.loadStatus &&
                  current.loadStatus.isSuccess,
          listener: _onLoaded,
        ),
        BlocListener<BookingCreateBloc, BookingCreateState>(
          listenWhen:
              (BookingCreateState previous, BookingCreateState current) =>
                  previous.submitStatus != current.submitStatus &&
                  current.submitStatus.isSuccess &&
                  current.createdBookingId != null,
          listener: (BuildContext context, BookingCreateState state) {
            context.goNamed(
              AppRoutes.booking.name,
              pathParameters: <String, String>{
                AppRoutes.bookingIdParam: state.createdBookingId!,
              },
            );
          },
        ),
        BlocListener<BookingCreateBloc, BookingCreateState>(
          listenWhen:
              (BookingCreateState previous, BookingCreateState current) =>
                  previous.submitFailure != current.submitFailure &&
                  current.submitFailure != null,
          listener: (BuildContext context, BookingCreateState state) {
            final Failure? failure = state.submitFailure;
            if (failure == null || failure is CancelledFailure) {
              return;
            }
            context.showAppSnackbar(failure.bookingMessage);
            if (failure.isBookingDraftNotFound) {
              context.goNamed(AppRoutes.newBooking.name);
            }
          },
        ),
      ],
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: BlocSelector<BookingCreateBloc, BookingCreateState, String?>(
          selector: (BookingCreateState state) => state.draft?.summary,
          builder: (BuildContext context, String? subtitle) {
            return BookingFormLayout(
              header: header,
              title: 'Цена и источник',
              subtitle: subtitle,
              body: body,
              footer: footer,
            );
          },
        ),
      ),
    );
  }
}

extension _BookingCreateBusy on BookingCreateState {
  /// Busy after a success too, until the booking screen opens.
  bool get isBusy => submitStatus.isLoading || submitStatus.isSuccess;
}

/// Switches between the skeleton, the load error, and [form] by the load
/// status.
final class _PriceBody extends StatelessWidget {
  const _PriceBody({required this.form});

  /// Built once by the screen and reused across load states.
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingCreateBloc,
      BookingCreateState,
      ({RequestStatus status, bool hasDraft, Failure? failure})
    >(
      selector: (BookingCreateState state) => (
        status: state.loadStatus,
        hasDraft: state.draft != null,
        failure: state.loadFailure,
      ),
      builder:
          (
            BuildContext context,
            ({RequestStatus status, bool hasDraft, Failure? failure}) value,
          ) {
            return switch (value.status) {
              RequestStatus.success when value.hasDraft => form,
              RequestStatus.failure => _DraftLoadFailure(
                message: value.failure?.bookingMessage ?? 'Попробуйте ещё раз',
              ),
              // Also shown while a missing draft sends the user to step 1.
              _ => const _NewBookingPriceSkeleton(),
            };
          },
    );
  }
}

final class _DraftLoadFailure extends StatelessWidget {
  const _DraftLoadFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Не удалось загрузить бронь',
      message: message,
      icon: SvgPicture.asset(AppAssets.icons.alertCircle),
      actionLabel: 'Повторить',
      onAction: () =>
          context.read<BookingCreateBloc>().add(const BookingCreateStarted()),
    );
  }
}

/// «Назад» and «Создать бронь»: shown once the draft has loaded; creating
/// is blocked while busy or when the dates are taken.
final class _PriceFooter extends StatelessWidget {
  const _PriceFooter({required this.onBack, required this.onSubmit});

  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingCreateBloc,
      BookingCreateState,
      ({bool isVisible, bool isEnabled, bool isLoading})
    >(
      selector: (BookingCreateState state) {
        final BookingDraftEntity? draft = state.draft;
        return (
          isVisible: state.loadStatus.isSuccess && draft != null,
          isEnabled:
              !state.isBusy && (draft?.availability.isAvailable ?? false),
          isLoading: state.submitStatus.isLoading,
        );
      },
      builder:
          (
            BuildContext context,
            ({bool isVisible, bool isEnabled, bool isLoading}) value,
          ) {
            if (!value.isVisible) {
              return const SizedBox.shrink();
            }
            return AppFlowFooter(
              message: 'Бронь сразу заблокирует даты во всех каналах.',
              messageStyle: AppTypography.caption.copyWith(
                height: 18 / 12,
                color: AppColors.secondaryText,
              ),
              secondaryLabel: 'Назад',
              onSecondaryPressed: onBack,
              primaryLabel: 'Создать бронь',
              onPrimaryPressed: value.isEnabled ? onSubmit : null,
              primaryLoading: value.isLoading,
            );
          },
    );
  }
}

/// The «Цена и источник» form. Holds no state of its own; each control
/// selects the slice of the BLoC state it shows.
final class _PriceForm extends StatelessWidget {
  const _PriceForm({
    required this.totalPriceController,
    required this.depositController,
    required this.commentController,
    required this.totalPriceFocusNode,
    required this.depositFocusNode,
    required this.commentFocusNode,
    required this.source,
    required this.createContract,
    required this.onFieldEdited,
    required this.onSourceSelected,
    required this.onCreateContractChanged,
    required this.onChangeDates,
  });

  final TextEditingController totalPriceController;
  final TextEditingController depositController;
  final TextEditingController commentController;
  final FocusNode totalPriceFocusNode;
  final FocusNode depositFocusNode;
  final FocusNode commentFocusNode;
  final ValueListenable<BookingSource> source;
  final ValueListenable<bool> createContract;

  /// Called with a `BookingFields` key when that field is edited.
  final ValueChanged<String> onFieldEdited;
  final ValueChanged<BookingSource> onSourceSelected;
  final ValueChanged<bool> onCreateContractChanged;

  /// «Изменить даты» of unavailable dates: back to step 1.
  final VoidCallback onChangeDates;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.large,
          children: <Widget>[
            Expanded(
              child: _AmountField(
                field: BookingFields.totalPrice,
                label: 'Итого',
                controller: totalPriceController,
                focusNode: totalPriceFocusNode,
                validator: FormValidators.positiveAmount,
                onChanged: onFieldEdited,
                onSubmitted: depositFocusNode.requestFocus,
              ),
            ),
            Expanded(
              child: _AmountField(
                field: BookingFields.deposit,
                label: 'Депозит',
                controller: depositController,
                focusNode: depositFocusNode,
                validator: FormValidators.nonNegativeAmount,
                onChanged: onFieldEdited,
                onSubmitted: commentFocusNode.requestFocus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Источник брони',
          style: AppTypography.sectionTitle.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.medium),
        _SourceSection(selected: source, onSelected: onSourceSelected),
        const SizedBox(height: AppSpacing.medium),
        _CommentField(
          controller: commentController,
          focusNode: commentFocusNode,
        ),
        const SizedBox(height: AppSpacing.large),
        _AvailabilityCallout(onChangeDates: onChangeDates),
        _CreateContractToggle(
          value: createContract,
          onChanged: onCreateContractChanged,
        ),
      ],
    );
  }
}

/// «Итого» / «Депозит»: a whole tenge amount with its server error.
final class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.field,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.onChanged,
    required this.onSubmitted,
  });

  /// `BookingFields` key of this field.
  final String field;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;

  /// Called with [field] when the text changes.
  final ValueChanged<String> onChanged;

  /// Moves the focus on when the keyboard action is pressed.
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingCreateBloc,
      BookingCreateState,
      ({String? error, bool isBusy})
    >(
      selector: (BookingCreateState state) =>
          (error: state.fieldErrors[field], isBusy: state.isBusy),
      builder: (BuildContext context, ({String? error, bool isBusy}) value) {
        return AppTextField(
          label: label,
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          errorText: bookingFieldErrorMessage(value.error),
          enabled: !value.isBusy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          trailing: Text(
            '₸',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.text),
          ),
          onChanged: (_) => onChanged(field),
          onSubmitted: (_) => onSubmitted(),
        );
      },
    );
  }
}

/// The source chips with the server error of `BookingFields.source`.
final class _SourceSection extends StatelessWidget {
  const _SourceSection({required this.selected, required this.onSelected});

  final ValueListenable<BookingSource> selected;
  final ValueChanged<BookingSource> onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingCreateBloc,
      BookingCreateState,
      ({String? error, bool isBusy})
    >(
      selector: (BookingCreateState state) => (
        error: state.fieldErrors[BookingFields.source],
        isBusy: state.isBusy,
      ),
      builder: (BuildContext context, ({String? error, bool isBusy}) value) {
        final String? errorText = bookingFieldErrorMessage(value.error);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ValueListenableBuilder<BookingSource>(
              valueListenable: selected,
              builder: (BuildContext context, BookingSource source, _) {
                return _SourceChips(
                  selected: source,
                  enabled: !value.isBusy,
                  onSelected: onSelected,
                );
              },
            ),
            if (errorText != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                errorText,
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// «Комментарий для команды».
final class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BookingCreateBloc, BookingCreateState, bool>(
      selector: (BookingCreateState state) => state.isBusy,
      builder: (BuildContext context, bool isBusy) {
        return AppTextField(
          label: 'Комментарий для команды',
          hint: 'Например, поздний заезд',
          controller: controller,
          focusNode: focusNode,
          enabled: !isBusy,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 1,
          maxLines: 4,
        );
      },
    );
  }
}

/// Whether the draft's dates are free; unavailable dates offer to change
/// them.
final class _AvailabilityCallout extends StatelessWidget {
  const _AvailabilityCallout({required this.onChangeDates});

  final VoidCallback onChangeDates;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingCreateBloc,
      BookingCreateState,
      BookingAvailabilityEntity?
    >(
      selector: (BookingCreateState state) => state.draft?.availability,
      builder: (BuildContext context, BookingAvailabilityEntity? availability) {
        // The form is shown only with a loaded draft.
        if (availability == null) {
          return const SizedBox.shrink();
        }
        return AppCallout(
          title: availability.title,
          message: availability.details,
          tone: availability.isAvailable
              ? AppFeedbackTone.success
              : AppFeedbackTone.error,
          actionLabel: availability.isAvailable ? null : 'Изменить даты',
          onAction: availability.isAvailable ? null : onChangeDates,
        );
      },
    );
  }
}

/// «Создать договор после брони».
final class _CreateContractToggle extends StatelessWidget {
  const _CreateContractToggle({required this.value, required this.onChanged});

  final ValueListenable<bool> value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BookingCreateBloc, BookingCreateState, bool>(
      selector: (BookingCreateState state) => state.isBusy,
      builder: (BuildContext context, bool isBusy) {
        return ValueListenableBuilder<bool>(
          valueListenable: value,
          builder: (BuildContext context, bool createContract, _) {
            return BookingToggleRow(
              title: 'Создать договор после брони',
              subtitle: 'Данные гостя можно дополнить позже',
              value: createContract,
              enabled: !isBusy,
              onChanged: onChanged,
            );
          },
        );
      },
    );
  }
}

/// «Напрямую», «Krisha», «Другое»: the sources of a booking added by hand.
final class _SourceChips extends StatelessWidget {
  const _SourceChips({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final BookingSource selected;
  final bool enabled;
  final ValueChanged<BookingSource> onSelected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: <Widget>[
          for (final BookingSource source in BookingSource.manual)
            Semantics(
              button: true,
              selected: source == selected,
              enabled: enabled,
              label: source.label,
              onTap: enabled ? () => onSelected(source) : null,
              excludeSemantics: true,
              child: IgnorePointer(
                ignoring: !enabled,
                child: AppChoiceChip(
                  label: source.label,
                  isSelected: source == selected,
                  onSelected: (_) => onSelected(source),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _NewBookingPriceSkeleton extends StatelessWidget {
  const _NewBookingPriceSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.large,
      children: <Widget>[
        Row(
          spacing: AppSpacing.large,
          children: <Widget>[
            Expanded(
              child: AppSkeleton(height: 72, borderRadius: AppRadii.field),
            ),
            Expanded(
              child: AppSkeleton(height: 72, borderRadius: AppRadii.field),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.small),
        AppSkeleton(height: 24, width: 160),
        AppSkeleton(height: 36, width: 260),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
        AppSkeleton(height: 72, borderRadius: AppRadii.media),
      ],
    );
  }
}
