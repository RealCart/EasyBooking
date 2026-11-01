import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_time_picker.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/publish_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_add_property_draft_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/publish_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_channels_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_details_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/add_property_bloc/add_property_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/add_property_step_layout.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_management_labels.dart';

/// Screen 15 «Условия проживания», step 3 of 3: the default terms. «Добавить
/// квартиру» publishes the draft and opens «Квартира добавлена».
///
/// Provides its own [AddPropertyBloc] through [wrappedRoute].
final class AddPropertyTermsScreen extends StatefulWidget
    implements GoRouterWrapper {
  const AddPropertyTermsScreen({super.key});

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
  State<AddPropertyTermsScreen> createState() => _AddPropertyTermsScreenState();
}

final class _AddPropertyTermsScreenState extends State<AddPropertyTermsScreen> {
  late final GlobalKey<FormState> _formKey;

  late final TextEditingController _priceController;
  late final TextEditingController _depositController;
  late final TextEditingController _checkInController;
  late final TextEditingController _checkOutController;
  late final TextEditingController _minNightsController;
  late final TextEditingController _cleaningFeeController;

  late final FocusNode _priceFocusNode;
  late final FocusNode _depositFocusNode;
  late final FocusNode _checkInFocusNode;
  late final FocusNode _checkOutFocusNode;
  late final FocusNode _minNightsFocusNode;
  late final FocusNode _cleaningFeeFocusNode;

  /// Chosen with the time picker; `null` until prefilled or chosen. Only
  /// read on submit; the fields show them through their controllers, so
  /// choosing a time does not rebuild the screen.
  late Duration? _checkInTime;
  late Duration? _checkOutTime;

  /// Whether the fields were filled from the draft; only done once.
  late bool _isPrefilled;

  late final String? Function(String?) _minNightsValidator;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _priceController = TextEditingController();
    _depositController = TextEditingController();
    _checkInController = TextEditingController();
    _checkOutController = TextEditingController();
    _minNightsController = TextEditingController();
    _cleaningFeeController = TextEditingController();
    _priceFocusNode = FocusNode();
    _depositFocusNode = FocusNode();
    _checkInFocusNode = FocusNode();
    _checkOutFocusNode = FocusNode();
    _minNightsFocusNode = FocusNode();
    _cleaningFeeFocusNode = FocusNode();
    _checkInTime = null;
    _checkOutTime = null;
    _isPrefilled = false;
    _minNightsValidator = FormValidators.wholeNumberInRange(
      min: PropertyLimits.minNights,
      max: PropertyLimits.maxMinNights,
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _depositController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _minNightsController.dispose();
    _cleaningFeeController.dispose();
    _priceFocusNode.dispose();
    _depositFocusNode.dispose();
    _checkInFocusNode.dispose();
    _checkOutFocusNode.dispose();
    _minNightsFocusNode.dispose();
    _cleaningFeeFocusNode.dispose();
    super.dispose();
  }

  void _prefill(AddPropertyDraftEntity draft) {
    if (_isPrefilled) {
      return;
    }
    final PropertyTermsEntity terms = draft.terms;
    _isPrefilled = true;
    _priceController.text = MoneyFormatter.group(terms.pricePerNight);
    _depositController.text = MoneyFormatter.group(terms.deposit);
    _cleaningFeeController.text = MoneyFormatter.group(terms.cleaningFee);
    _minNightsController.text = '${terms.minNights}';
    _checkInTime = terms.checkInTime;
    _checkInController.text = timeOfDayLabel(terms.checkInTime);
    _checkOutTime = terms.checkOutTime;
    _checkOutController.text = timeOfDayLabel(terms.checkOutTime);
  }

  void _onFieldEdited(String field) {
    context.read<AddPropertyBloc>().add(AddPropertyFieldEdited(field));
  }

  /// Opens the 24-hour time picker for check-in or check-out.
  Future<void> _pickTime({required bool isCheckIn}) async {
    context.hideKeyboard();
    final Duration current =
        (isCheckIn ? _checkInTime : _checkOutTime) ?? Duration.zero;
    final TimeOfDay? picked = await showAppTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.inHours.remainder(Duration.hoursPerDay),
        minute: current.inMinutes.remainder(Duration.minutesPerHour),
      ),
      helpText: isCheckIn ? 'Заезд после' : 'Выезд до',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (picked == null || !mounted) {
      return;
    }
    final Duration time = Duration(hours: picked.hour, minutes: picked.minute);
    if (isCheckIn) {
      _checkInTime = time;
      _checkInController.text = timeOfDayLabel(time);
    } else {
      _checkOutTime = time;
      _checkOutController.text = timeOfDayLabel(time);
    }
    _onFieldEdited(
      isCheckIn
          ? AddPropertyFields.checkInTime
          : AddPropertyFields.checkOutTime,
    );
  }

  void _submit() {
    context.hideKeyboard();
    final bool isValid = _formKey.currentState?.validate() ?? false;
    final Duration? checkInTime = _checkInTime;
    final Duration? checkOutTime = _checkOutTime;
    // The validators guarantee every value once the form is valid.
    final int? price = MoneyFormatter.tryParse(_priceController.text);
    final int? deposit = MoneyFormatter.tryParse(_depositController.text);
    final int? cleaningFee = MoneyFormatter.tryParse(
      _cleaningFeeController.text,
    );
    final int? minNights = int.tryParse(_minNightsController.text.trim());
    if (!isValid ||
        checkInTime == null ||
        checkOutTime == null ||
        price == null ||
        deposit == null ||
        cleaningFee == null ||
        minNights == null) {
      return;
    }
    context.read<AddPropertyBloc>().add(
      AddPropertyTermsSubmitted(
        PublishPropertyParamsEntity(
          terms: PropertyTermsEntity(
            pricePerNight: price,
            deposit: deposit,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            minNights: minNights,
            cleaningFee: cleaningFee,
          ),
        ),
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
            final String? propertyId = state.publishedPropertyId;
            if (state.submitStatus.isSuccess && propertyId != null) {
              // `go` removes the add-property flow from the stack.
              context.goNamed(
                AppRoutes.propertyReady.name,
                pathParameters: <String, String>{
                  AppRoutes.propertyIdParam: propertyId,
                },
              );
              return;
            }
            final String? message = state.submitFailure?.propertyMessage;
            if (message != null) {
              context.showAppSnackbar(message);
            }
          },
        ),
      ],
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        // The frame only follows the draft and the submit status; server
        // field errors are selected by each field, so typing never rebuilds
        // the step.
        child: BlocBuilder<AddPropertyBloc, AddPropertyState>(
          buildWhen: (AddPropertyState previous, AddPropertyState current) =>
              previous.draftStatus != current.draftStatus ||
              previous.draftFailure != current.draftFailure ||
              previous.submitStatus != current.submitStatus,
          builder: (BuildContext context, AddPropertyState state) {
            // Busy after success until the router leaves the screen.
            final bool isBusy =
                state.submitStatus.isLoading || state.submitStatus.isSuccess;
            return AddPropertyStepLayout(
              step: 3,
              title: 'Условия проживания',
              subtitle: 'Значения по умолчанию для новых броней.',
              draftStatus: state.draftStatus,
              draftErrorMessage: state.draftFailure?.userMessage,
              onRetry: () => context.read<AddPropertyBloc>().add(
                const AddPropertyStarted(),
              ),
              onBack: () => context.pop(),
              footerMessage:
                  'Проверьте условия — их можно изменить в настройках '
                  'объекта.',
              primaryLabel: 'Добавить квартиру',
              isSubmitting: isBusy,
              onPrimaryPressed: isBusy ? null : _submit,
              children: <Widget>[
                _FieldPair(
                  first: _AmountField(
                    field: AddPropertyFields.pricePerNight,
                    label: 'Цена за ночь',
                    controller: _priceController,
                    focusNode: _priceFocusNode,
                    validator: FormValidators.positiveAmount,
                    enabled: !isBusy,
                    onChanged: () =>
                        _onFieldEdited(AddPropertyFields.pricePerNight),
                    onSubmitted: _depositFocusNode.requestFocus,
                  ),
                  second: _AmountField(
                    field: AddPropertyFields.deposit,
                    label: 'Депозит',
                    controller: _depositController,
                    focusNode: _depositFocusNode,
                    validator: FormValidators.nonNegativeAmount,
                    enabled: !isBusy,
                    onChanged: () => _onFieldEdited(AddPropertyFields.deposit),
                    onSubmitted: _minNightsFocusNode.requestFocus,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                _FieldPair(
                  first: _TimeField(
                    field: AddPropertyFields.checkInTime,
                    label: 'Заезд после',
                    controller: _checkInController,
                    focusNode: _checkInFocusNode,
                    enabled: !isBusy,
                    onTap: () => _pickTime(isCheckIn: true),
                  ),
                  second: _TimeField(
                    field: AddPropertyFields.checkOutTime,
                    label: 'Выезд до',
                    controller: _checkOutController,
                    focusNode: _checkOutFocusNode,
                    enabled: !isBusy,
                    onTap: () => _pickTime(isCheckIn: false),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                _FieldPair(
                  first: _MinNightsField(
                    field: AddPropertyFields.minNights,
                    controller: _minNightsController,
                    focusNode: _minNightsFocusNode,
                    validator: _minNightsValidator,
                    enabled: !isBusy,
                    onChanged: () =>
                        _onFieldEdited(AddPropertyFields.minNights),
                    onSubmitted: _cleaningFeeFocusNode.requestFocus,
                  ),
                  second: _AmountField(
                    field: AddPropertyFields.cleaningFee,
                    label: 'Уборка',
                    controller: _cleaningFeeController,
                    focusNode: _cleaningFeeFocusNode,
                    validator: FormValidators.nonNegativeAmount,
                    enabled: !isBusy,
                    textInputAction: TextInputAction.done,
                    onChanged: () =>
                        _onFieldEdited(AddPropertyFields.cleaningFee),
                    onSubmitted: _submit,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Two fields side by side, stacked when the screen is too narrow.
final class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              first,
              const SizedBox(height: AppSpacing.large),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: first),
            const SizedBox(width: AppSpacing.large),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

/// A tenge amount: digits with the `₸` sign after them. Selects the server
/// error of [field] itself, so only this field rebuilds when it changes.
final class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.field,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
    this.textInputAction = TextInputAction.next,
  });

  /// The `AddPropertyFields` key of this field's server error.
  final String field;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddPropertyBloc, AddPropertyState, String?>(
      selector: (AddPropertyState state) => state.fieldErrors[field],
      builder: (BuildContext context, String? errorCode) {
        return AppTextField(
          label: label,
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          errorText: propertyFieldErrorMessage(errorCode),
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          trailing: Text(
            '₸',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.text),
          ),
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmitted(),
        );
      },
    );
  }
}

/// A read-only time field that opens the picker on tap; selects the server
/// error of [field] itself.
final class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.field,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onTap,
  });

  /// The `AddPropertyFields` key of this field's server error.
  final String field;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddPropertyBloc, AddPropertyState, String?>(
      selector: (AddPropertyState state) => state.fieldErrors[field],
      builder: (BuildContext context, String? errorCode) {
        return AppTextField(
          label: label,
          controller: controller,
          focusNode: focusNode,
          readOnly: true,
          validator: FormValidators.required,
          errorText: propertyFieldErrorMessage(errorCode),
          enabled: enabled,
          onTap: onTap,
        );
      },
    );
  }
}

/// «Минимум ночей»; selects the server error of [field] itself.
final class _MinNightsField extends StatelessWidget {
  const _MinNightsField({
    required this.field,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  /// The `AddPropertyFields` key of this field's server error.
  final String field;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddPropertyBloc, AddPropertyState, String?>(
      selector: (AddPropertyState state) => state.fieldErrors[field],
      builder: (BuildContext context, String? errorCode) {
        return AppTextField(
          label: 'Минимум ночей',
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          errorText: propertyFieldErrorMessage(errorCode),
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmitted(),
        );
      },
    );
  }
}
