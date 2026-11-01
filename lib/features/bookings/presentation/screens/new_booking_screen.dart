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
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_picker_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_search_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_time_picker.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_progress_app_bar.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/save_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/search_booking_guests_usecase.dart';
import 'package:easy_booking/features/bookings/presentation/bloc/booking_draft_bloc/booking_draft_bloc.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_date_time_field.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_failure_message.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_form_layout.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_guest_suggestions.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_labels.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';

/// Screen 17 «Новая бронь · 1 из 2», «Когда и где»: the apartment, the
/// dates, and the guest of a booking added by hand. Saves them as a draft
/// and opens step 2.
///
/// Provides its own [BookingDraftBloc] through [wrappedRoute].
final class NewBookingScreen extends StatefulWidget implements GoRouterWrapper {
  const NewBookingScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<BookingDraftBloc>(
      create: (_) => BookingDraftBloc(
        getProperties: dependencies.getDep<GetPropertiesUsecase>(),
        getDraft: dependencies.getDep<GetBookingDraftUsecase>(),
        searchGuests: dependencies.getDep<SearchBookingGuestsUsecase>(),
        saveDraft: dependencies.getDep<SaveBookingDraftUsecase>(),
      )..add(const BookingDraftStarted()),
      child: this,
    );
  }

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

final class _NewBookingScreenState extends State<NewBookingScreen> {
  static const int _checkInHour = 14;
  static const int _checkOutHour = 12;

  /// How far ahead a booking can be added.
  static const int _bookingHorizonDays = 730;

  late final GlobalKey<FormState> _formKey;
  late final GlobalKey<FormFieldState<PropertyEntity>> _propertyFieldKey;

  late final TextEditingController _guestSearchController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;

  late final FocusNode _firstNameFocusNode;
  late final FocusNode _lastNameFocusNode;
  late final FocusNode _phoneFocusNode;

  /// The chosen dates: notifiers, so picking one rebuilds only its field.
  /// `null` until the load sets them from the draft or the source's today;
  /// the form shows only after that.
  late final ValueNotifier<DateTime?> _checkIn;
  late final ValueNotifier<DateTime?> _checkOut;

  /// Whether the form was filled from the loaded draft; it happens once.
  late bool _isPrefilled;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _propertyFieldKey = GlobalKey<FormFieldState<PropertyEntity>>();
    _guestSearchController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _checkIn = ValueNotifier<DateTime?>(null);
    _checkOut = ValueNotifier<DateTime?>(null);
    _isPrefilled = false;
  }

  @override
  void dispose() {
    _guestSearchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _checkIn.dispose();
    _checkOut.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.today.name);
    }
  }

  void _onFieldEdited(String field) {
    context.read<BookingDraftBloc>().add(BookingDraftFieldEdited(field));
  }

  /// Fills the form from the saved draft, once, when it has loaded. The
  /// apartment picker reads its initial value from the same draft. Without
  /// a draft, the stay defaults to tomorrow 14:00 until the day after 12:00,
  /// counted from the source's today.
  void _prefill(BookingDraftState state) {
    if (_isPrefilled) {
      return;
    }
    _isPrefilled = true;
    final BookingDraftEntity? draft = state.draft;
    if (draft != null) {
      _checkIn.value = draft.checkIn;
      _checkOut.value = draft.checkOut;
      _fillGuest(draft.guest);
      return;
    }
    // A successful load always carries today.
    final DateTime? today = state.today;
    if (today == null) {
      return;
    }
    final DateTime tomorrow = today.addDays(1);
    _checkIn.value = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      _checkInHour,
    );
    _checkOut.value = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day + 1,
      _checkOutHour,
    );
  }

  void _fillGuest(BookingGuestEntity guest) {
    _firstNameController.text = guest.firstName;
    _lastNameController.text = guest.lastName;
    _phoneController.text = PhoneNumber.format(guest.phone);
  }

  void _onGuestSelected(BookingGuestEntity guest) {
    context.hideKeyboard();
    _fillGuest(guest);
    _guestSearchController.clear();
    context.read<BookingDraftBloc>().add(const BookingDraftGuestSearched(''));
    _onFieldEdited(BookingFields.firstName);
    _onFieldEdited(BookingFields.lastName);
    _onFieldEdited(BookingFields.phone);
  }

  Future<void> _pickCheckIn() async {
    final DateTime? today = context.read<BookingDraftBloc>().state.today;
    final DateTime? checkIn = _checkIn.value;
    // Both are set by the load, before the form shows.
    if (today == null || checkIn == null) {
      return;
    }
    final DateTime? picked = await _pickDateTime(
      initial: checkIn,
      firstDate: checkIn.isBefore(today) ? checkIn.dateOnly : today,
      helpText: 'Дата заезда',
    );
    if (picked == null || !mounted) {
      return;
    }
    _checkIn.value = picked;
    // Keeps at least one night, moving check-out on with its time.
    final DateTime? checkOut = _checkOut.value;
    if (checkOut != null && picked.nightsUntil(checkOut) < 1) {
      _checkOut.value = DateTime(
        picked.year,
        picked.month,
        picked.day + 1,
        checkOut.hour,
        checkOut.minute,
      );
    }
    _onFieldEdited(BookingFields.checkIn);
    _onFieldEdited(BookingFields.checkOut);
  }

  Future<void> _pickCheckOut() async {
    final DateTime? checkIn = _checkIn.value;
    final DateTime? checkOut = _checkOut.value;
    // Both are set by the load, before the form shows.
    if (checkIn == null || checkOut == null) {
      return;
    }
    final DateTime? picked = await _pickDateTime(
      initial: checkOut,
      firstDate: checkIn.dateOnly.addDays(1),
      helpText: 'Дата выезда',
    );
    if (picked == null || !mounted) {
      return;
    }
    _checkOut.value = picked;
    _onFieldEdited(BookingFields.checkOut);
  }

  /// Asks for a date, then a time; a dismissed time keeps the time of
  /// [initial]. Returns `null` when the date is dismissed.
  Future<DateTime?> _pickDateTime({
    required DateTime initial,
    required DateTime firstDate,
    required String helpText,
  }) async {
    context.hideKeyboard();
    final DateTime initialDate = initial.dateOnly.isBefore(firstDate)
        ? firstDate
        : initial.dateOnly;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: firstDate.addDays(_bookingHorizonDays),
      helpText: helpText,
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (date == null || !mounted) {
      return null;
    }
    final TimeOfDay? time = await showAppTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Время',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    final TimeOfDay pickedTime = time ?? TimeOfDay.fromDateTime(initial);
    return DateTime(
      date.year,
      date.month,
      date.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  void _submit() {
    context.hideKeyboard();
    final bool isValid = _formKey.currentState?.validate() ?? false;
    // The property validator guarantees a value once the form is valid,
    // and the load set both dates before the form showed.
    final PropertyEntity? property = _propertyFieldKey.currentState?.value;
    final DateTime? checkIn = _checkIn.value;
    final DateTime? checkOut = _checkOut.value;
    if (!isValid || property == null || checkIn == null || checkOut == null) {
      return;
    }
    context.read<BookingDraftBloc>().add(
      BookingDraftSubmitted(
        SaveBookingDraftParamsEntity(
          propertyId: property.id,
          checkIn: checkIn,
          checkOut: checkOut,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
        ),
      ),
    );
  }

  // Nothing here reads the BLoC state: every piece selects its own slice, so
  // this screen builds once and typing or picking never rebuilds it.
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<BookingDraftBloc, BookingDraftState>>[
        BlocListener<BookingDraftBloc, BookingDraftState>(
          listenWhen: (BookingDraftState previous, BookingDraftState current) =>
              previous.loadStatus != current.loadStatus &&
              current.loadStatus.isSuccess,
          listener: (_, BookingDraftState state) => _prefill(state),
        ),
        BlocListener<BookingDraftBloc, BookingDraftState>(
          listenWhen: (BookingDraftState previous, BookingDraftState current) =>
              previous.submitStatus != current.submitStatus &&
              current.submitStatus.isSuccess,
          listener: (BuildContext context, _) =>
              context.pushNamed(AppRoutes.newBookingGuest.name),
        ),
        BlocListener<BookingDraftBloc, BookingDraftState>(
          listenWhen: (BookingDraftState previous, BookingDraftState current) =>
              previous.submitFailure != current.submitFailure &&
              current.submitFailure != null,
          listener: (BuildContext context, BookingDraftState state) {
            final Failure? failure = state.submitFailure;
            if (failure != null && failure is! CancelledFailure) {
              context.showAppSnackbar(failure.bookingMessage);
            }
          },
        ),
      ],
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: BookingFormLayout(
          header: AppProgressAppBar(
            title: 'Новая бронь',
            currentStep: 1,
            totalSteps: 2,
            backSemanticLabel: 'Назад',
            showDivider: false,
            onBack: _close,
          ),
          title: 'Когда и где',
          subtitle: 'Добавьте бронь, полученную напрямую или через Krisha.',
          body: _NewBookingBody(
            form: _DraftForm(
              propertyFieldKey: _propertyFieldKey,
              checkIn: _checkIn,
              checkOut: _checkOut,
              guestSearchController: _guestSearchController,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              phoneController: _phoneController,
              firstNameFocusNode: _firstNameFocusNode,
              lastNameFocusNode: _lastNameFocusNode,
              phoneFocusNode: _phoneFocusNode,
              onFieldEdited: _onFieldEdited,
              onCheckInPressed: _pickCheckIn,
              onCheckOutPressed: _pickCheckOut,
              onGuestSelected: _onGuestSelected,
              onSubmit: _submit,
            ),
          ),
          footer: _NewBookingFooter(onSubmit: _submit),
        ),
      ),
    );
  }
}

/// Switches between the skeleton, the load error, and [form] by the load
/// status.
final class _NewBookingBody extends StatelessWidget {
  const _NewBookingBody({required this.form});

  /// Built once by the screen and reused across load states.
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingDraftBloc, BookingDraftState>(
      buildWhen: (BookingDraftState previous, BookingDraftState current) =>
          previous.loadStatus != current.loadStatus ||
          previous.loadFailure != current.loadFailure,
      builder: (BuildContext context, BookingDraftState state) {
        return switch (state.loadStatus) {
          RequestStatus.success => form,
          RequestStatus.failure => _PropertiesLoadFailure(
            message: state.loadFailure?.bookingMessage ?? 'Попробуйте ещё раз',
          ),
          RequestStatus.initial ||
          RequestStatus.loading => const _NewBookingSkeleton(),
        };
      },
    );
  }
}

final class _PropertiesLoadFailure extends StatelessWidget {
  const _PropertiesLoadFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Не удалось загрузить квартиры',
      message: message,
      icon: SvgPicture.asset(AppAssets.icons.alertCircle),
      actionLabel: 'Повторить',
      onAction: () =>
          context.read<BookingDraftBloc>().add(const BookingDraftStarted()),
    );
  }
}

/// «Продолжить»: shown once the apartments have loaded, busy while saving.
final class _NewBookingFooter extends StatelessWidget {
  const _NewBookingFooter({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingDraftBloc,
      BookingDraftState,
      ({bool isLoaded, bool isSaving})
    >(
      selector: (BookingDraftState state) => (
        isLoaded: state.loadStatus.isSuccess,
        isSaving: state.submitStatus.isLoading,
      ),
      builder: (BuildContext context, ({bool isLoaded, bool isSaving}) value) {
        if (!value.isLoaded) {
          return const SizedBox.shrink();
        }
        return AppFlowFooter(
          message: 'На следующем шаге проверим цену и занятость.',
          messageStyle: AppTypography.caption.copyWith(
            height: 18 / 12,
            color: AppColors.secondaryText,
          ),
          primaryLabel: 'Продолжить',
          onPrimaryPressed: value.isSaving ? null : onSubmit,
          primaryLoading: value.isSaving,
        );
      },
    );
  }
}

/// The «Когда и где» form. Holds no state of its own; each field selects
/// the slice of the BLoC state it shows.
final class _DraftForm extends StatelessWidget {
  const _DraftForm({
    required this.propertyFieldKey,
    required this.checkIn,
    required this.checkOut,
    required this.guestSearchController,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.firstNameFocusNode,
    required this.lastNameFocusNode,
    required this.phoneFocusNode,
    required this.onFieldEdited,
    required this.onCheckInPressed,
    required this.onCheckOutPressed,
    required this.onGuestSelected,
    required this.onSubmit,
  });

  final GlobalKey<FormFieldState<PropertyEntity>> propertyFieldKey;
  final ValueListenable<DateTime?> checkIn;
  final ValueListenable<DateTime?> checkOut;
  final TextEditingController guestSearchController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final FocusNode firstNameFocusNode;
  final FocusNode lastNameFocusNode;
  final FocusNode phoneFocusNode;

  /// Called with a `BookingFields` key when that field is edited.
  final ValueChanged<String> onFieldEdited;
  final VoidCallback onCheckInPressed;
  final VoidCallback onCheckOutPressed;
  final ValueChanged<BookingGuestEntity> onGuestSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _PropertyField(
          fieldKey: propertyFieldKey,
          onChanged: () => onFieldEdited(BookingFields.property),
        ),
        const SizedBox(height: AppSpacing.large),
        _StayDatesRow(
          checkIn: checkIn,
          checkOut: checkOut,
          onCheckInPressed: onCheckInPressed,
          onCheckOutPressed: onCheckOutPressed,
        ),
        const SizedBox(height: 22),
        Text(
          'Гость',
          style: AppTypography.sectionTitle.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.medium),
        AppSearchField(
          controller: guestSearchController,
          hint: 'Найти существующего гостя',
          subtitle: 'По имени или телефону',
          clearSemanticLabel: 'Очистить поиск',
          onChanged: (String query) => context.read<BookingDraftBloc>().add(
            BookingDraftGuestSearched(query),
          ),
        ),
        _GuestResults(onSelected: onGuestSelected),
        const SizedBox(height: AppSpacing.medium),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.large,
          children: <Widget>[
            Expanded(
              child: _DraftTextField(
                field: BookingFields.firstName,
                label: 'Имя',
                controller: firstNameController,
                focusNode: firstNameFocusNode,
                validator: FormValidators.required,
                autofillHints: const <String>[AutofillHints.givenName],
                onChanged: onFieldEdited,
                onSubmitted: lastNameFocusNode.requestFocus,
              ),
            ),
            Expanded(
              child: _DraftTextField(
                field: BookingFields.lastName,
                label: 'Фамилия',
                controller: lastNameController,
                focusNode: lastNameFocusNode,
                autofillHints: const <String>[AutofillHints.familyName],
                onChanged: onFieldEdited,
                onSubmitted: phoneFocusNode.requestFocus,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        _DraftTextField(
          field: BookingFields.phone,
          label: 'Телефон',
          hint: '+7 700 000 00 00',
          controller: phoneController,
          focusNode: phoneFocusNode,
          validator: FormValidators.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          onChanged: onFieldEdited,
          onSubmitted: onSubmit,
        ),
      ],
    );
  }
}

/// «Квартира»: the apartment picker, prefilled with the draft's apartment.
final class _PropertyField extends StatelessWidget {
  const _PropertyField({required this.fieldKey, required this.onChanged});

  static const AppPickerSheetTexts _sheetTexts = AppPickerSheetTexts(
    title: 'Квартира',
    subtitle: 'Где будет жить гость',
    searchHint: 'Найти квартиру',
    searchExample: 'Например, Esentai City',
    emptyTitle: 'Квартира не найдена',
    emptyMessage: 'Проверьте название комплекса или номер квартиры.',
  );

  final GlobalKey<FormFieldState<PropertyEntity>> fieldKey;
  final VoidCallback onChanged;

  /// The draft's apartment. Read by the picker only when it is created,
  /// which happens once the draft has loaded.
  static PropertyEntity? _initialPropertyOf(BookingDraftState state) {
    final String? propertyId = state.draft?.propertyId;
    if (propertyId == null) {
      return null;
    }
    return state.properties
        .where((PropertyEntity property) => property.id == propertyId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingDraftBloc,
      BookingDraftState,
      ({
        List<PropertyEntity> properties,
        PropertyEntity? initialValue,
        String? error,
        bool isSaving,
      })
    >(
      selector: (BookingDraftState state) => (
        properties: state.properties,
        initialValue: _initialPropertyOf(state),
        error: state.fieldErrors[BookingFields.property],
        isSaving: state.submitStatus.isLoading,
      ),
      builder:
          (
            BuildContext context,
            ({
              List<PropertyEntity> properties,
              PropertyEntity? initialValue,
              String? error,
              bool isSaving,
            })
            value,
          ) {
            return AppPickerField<PropertyEntity>(
              key: fieldKey,
              label: 'Квартира',
              hint: 'Выберите квартиру',
              options: value.properties,
              initialValue: value.initialValue,
              titleOf: (PropertyEntity property) => property.bookingTitle,
              subtitleOf: (PropertyEntity property) => property.bookingSubtitle,
              sheetTexts: _sheetTexts,
              validator: FormValidators.selected,
              errorText: bookingFieldErrorMessage(value.error),
              enabled: !value.isSaving,
              onChanged: (_) => onChanged(),
            );
          },
    );
  }
}

/// «Заезд» and «Выезд» side by side with their server errors.
final class _StayDatesRow extends StatelessWidget {
  const _StayDatesRow({
    required this.checkIn,
    required this.checkOut,
    required this.onCheckInPressed,
    required this.onCheckOutPressed,
  });

  final ValueListenable<DateTime?> checkIn;
  final ValueListenable<DateTime?> checkOut;
  final VoidCallback onCheckInPressed;
  final VoidCallback onCheckOutPressed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingDraftBloc,
      BookingDraftState,
      ({String? checkInError, String? checkOutError, bool isSaving})
    >(
      selector: (BookingDraftState state) => (
        checkInError: state.fieldErrors[BookingFields.checkIn],
        checkOutError: state.fieldErrors[BookingFields.checkOut],
        isSaving: state.submitStatus.isLoading,
      ),
      builder:
          (
            BuildContext context,
            ({String? checkInError, String? checkOutError, bool isSaving})
            value,
          ) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.large,
              children: <Widget>[
                Expanded(
                  child: _StayDateField(
                    label: 'Заезд',
                    value: checkIn,
                    errorText: bookingFieldErrorMessage(value.checkInError),
                    enabled: !value.isSaving,
                    onPressed: onCheckInPressed,
                  ),
                ),
                Expanded(
                  child: _StayDateField(
                    label: 'Выезд',
                    value: checkOut,
                    errorText: bookingFieldErrorMessage(value.checkOutError),
                    enabled: !value.isSaving,
                    onPressed: onCheckOutPressed,
                  ),
                ),
              ],
            );
          },
    );
  }
}

/// A [BookingDateTimeField] that follows its chosen date in [value].
final class _StayDateField extends StatelessWidget {
  const _StayDateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPressed,
    this.errorText,
  });

  final String label;
  final ValueListenable<DateTime?> value;
  final String? errorText;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: value,
      builder: (BuildContext context, DateTime? date, _) {
        // The load sets the date before the form shows.
        if (date == null) {
          return const SizedBox.shrink();
        }
        return BookingDateTimeField(
          label: label,
          value: date,
          errorText: errorText,
          enabled: enabled,
          onPressed: onPressed,
        );
      },
    );
  }
}

/// Results of «Найти существующего гостя»; nothing until a query is
/// searched.
final class _GuestResults extends StatelessWidget {
  const _GuestResults({required this.onSelected});

  final ValueChanged<BookingGuestEntity> onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingDraftBloc,
      BookingDraftState,
      ({
        RequestStatus status,
        List<BookingGuestEntity> guests,
        Failure? failure,
      })
    >(
      selector: (BookingDraftState state) => (
        status: state.guestSearchStatus,
        guests: state.guests,
        failure: state.guestSearchFailure,
      ),
      builder:
          (
            BuildContext context,
            ({
              RequestStatus status,
              List<BookingGuestEntity> guests,
              Failure? failure,
            })
            value,
          ) {
            if (value.status.isInitial) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.medium),
              child: BookingGuestSuggestions(
                status: value.status,
                guests: value.guests,
                failureMessage: value.failure?.bookingMessage,
                onSelected: onSelected,
              ),
            );
          },
    );
  }
}

/// A text field of the «Когда и где» form: validates itself in the `Form`
/// and shows the server error of its [field].
final class _DraftTextField extends StatelessWidget {
  const _DraftTextField({
    required this.field,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autocorrect = true,
    this.autofillHints,
  });

  /// `BookingFields` key of this field.
  final String field;
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String>? validator;

  /// Called with [field] when the text changes.
  final ValueChanged<String> onChanged;

  /// Runs when the keyboard action is pressed.
  final VoidCallback onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool autocorrect;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookingDraftBloc,
      BookingDraftState,
      ({String? error, bool isSaving})
    >(
      selector: (BookingDraftState state) => (
        error: state.fieldErrors[field],
        isSaving: state.submitStatus.isLoading,
      ),
      builder: (BuildContext context, ({String? error, bool isSaving}) value) {
        return AppTextField(
          label: label,
          hint: hint,
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          errorText: bookingFieldErrorMessage(value.error),
          enabled: !value.isSaving,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autocorrect: autocorrect,
          autofillHints: autofillHints,
          onChanged: (_) => onChanged(field),
          onSubmitted: (_) => onSubmitted(),
        );
      },
    );
  }
}

final class _NewBookingSkeleton extends StatelessWidget {
  const _NewBookingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.large,
      children: <Widget>[
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
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
        AppSkeleton(height: 24, width: 80),
        AppSkeleton(height: 66),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
      ],
    );
  }
}
