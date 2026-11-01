import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_stepper.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_upload_field.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_add_property_draft_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/publish_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_channels_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_details_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/add_property_bloc/add_property_bloc.dart';
import 'package:easy_booking/features/properties/presentation/widgets/add_property_step_layout.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_management_labels.dart';

/// Screen 09 «Добавить квартиру», step 1 of 3: name, address, type, and
/// rooms. Prefilled from the draft; «Продолжить» saves it and opens step 2.
///
/// Provides its own [AddPropertyBloc] through [wrappedRoute].
final class AddPropertyScreen extends StatefulWidget
    implements GoRouterWrapper {
  const AddPropertyScreen({super.key});

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
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

final class _AddPropertyScreenState extends State<AddPropertyScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _titleController;
  late final TextEditingController _addressController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _addressFocusNode;

  /// Local choices, listened to by the chips and the stepper only, so a tap
  /// does not rebuild the screen.
  late final ValueNotifier<PropertyType> _type;
  late final ValueNotifier<int> _rooms;

  /// Whether the fields were filled from the draft; only done once.
  late bool _isPrefilled;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _titleController = TextEditingController();
    _addressController = TextEditingController();
    _titleFocusNode = FocusNode();
    _addressFocusNode = FocusNode();
    _type = ValueNotifier<PropertyType>(PropertyType.apartment);
    _rooms = ValueNotifier<int>(PropertyLimits.minRooms);
    _isPrefilled = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _titleFocusNode.dispose();
    _addressFocusNode.dispose();
    _type.dispose();
    _rooms.dispose();
    super.dispose();
  }

  void _prefill(AddPropertyDraftEntity draft) {
    if (_isPrefilled) {
      return;
    }
    _isPrefilled = true;
    _titleController.text = draft.title;
    _addressController.text = draft.address;
    _type.value = draft.type;
    _rooms.value = draft.rooms.clamp(
      PropertyLimits.minRooms,
      PropertyLimits.maxRooms,
    );
  }

  void _onFieldEdited(String field) {
    context.read<AddPropertyBloc>().add(AddPropertyFieldEdited(field));
  }

  void _onRoomsChanged(int rooms) {
    _rooms.value = rooms;
    _onFieldEdited(AddPropertyFields.rooms);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.properties.name);
    }
  }

  void _submit() {
    context.hideKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<AddPropertyBloc>().add(
      AddPropertyDetailsSubmitted(
        SaveAddPropertyDetailsParamsEntity(
          title: _titleController.text,
          address: _addressController.text,
          type: _type.value,
          rooms: _rooms.value,
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
            if (state.submitStatus.isSuccess) {
              context.pushNamed(AppRoutes.addPropertyChannels.name);
              return;
            }
            context.showAppSnackbar(state.submitFailure!.propertyMessage);
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
            final bool isSubmitting = state.submitStatus.isLoading;
            return AddPropertyStepLayout(
              step: 1,
              title: 'Начнём с вашей квартиры',
              subtitle: 'Название и фото помогут быстро её узнавать.',
              draftStatus: state.draftStatus,
              draftErrorMessage: state.draftFailure?.userMessage,
              onRetry: () => context.read<AddPropertyBloc>().add(
                const AddPropertyStarted(),
              ),
              onBack: _close,
              footerMessage: 'Далее — подключение площадок и календарей',
              primaryLabel: 'Продолжить',
              isSubmitting: isSubmitting,
              onPrimaryPressed: isSubmitting ? null : _submit,
              children: <Widget>[
                AppUploadField(
                  title: 'Добавить фото',
                  description: 'Обложку можно изменить позже',
                  onPressed: () => context.showAppSnackbar('Скоро будет'),
                ),
                const SizedBox(height: AppSpacing.xLarge),
                BlocSelector<AddPropertyBloc, AddPropertyState, String?>(
                  selector: (AddPropertyState state) =>
                      state.fieldErrors[AddPropertyFields.title],
                  builder: (BuildContext context, String? errorCode) {
                    return AppTextField(
                      label: 'Название',
                      hint: 'Например, Esentai City · 84',
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      validator: FormValidators.required,
                      errorText: propertyFieldErrorMessage(errorCode),
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _onFieldEdited(AddPropertyFields.title),
                      onSubmitted: (_) => _addressFocusNode.requestFocus(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.large),
                BlocSelector<AddPropertyBloc, AddPropertyState, String?>(
                  selector: (AddPropertyState state) =>
                      state.fieldErrors[AddPropertyFields.address],
                  builder: (BuildContext context, String? errorCode) {
                    return AppTextField(
                      label: 'Адрес',
                      hint: 'Улица, дом, квартира',
                      controller: _addressController,
                      focusNode: _addressFocusNode,
                      validator: FormValidators.required,
                      errorText: propertyFieldErrorMessage(errorCode),
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.streetAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[
                        AutofillHints.fullStreetAddress,
                      ],
                      onChanged: (_) =>
                          _onFieldEdited(AddPropertyFields.address),
                      onSubmitted: (_) => _addressFocusNode.unfocus(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xLarge),
                const _TypeTitle(),
                const SizedBox(height: AppSpacing.medium),
                _PropertyTypeChips(type: _type, isEnabled: !isSubmitting),
                const SizedBox(height: AppSpacing.xLarge),
                _RoomsRow(
                  rooms: _rooms,
                  onChanged: isSubmitting ? null : _onRoomsChanged,
                ),
                const _RoomsError(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// «Тип жилья».
final class _TypeTitle extends StatelessWidget {
  const _TypeTitle();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        'Тип жилья',
        style: AppTypography.primaryText.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One chip per [PropertyType]; rebuilds only when [type] changes.
final class _PropertyTypeChips extends StatelessWidget {
  const _PropertyTypeChips({required this.type, required this.isEnabled});

  final ValueNotifier<PropertyType> type;

  /// Taps are ignored while saving.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PropertyType>(
      valueListenable: type,
      builder: (BuildContext context, PropertyType selected, Widget? child) {
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: <Widget>[
            for (final PropertyType option in PropertyType.values)
              Semantics(
                button: true,
                selected: option == selected,
                label: option.label,
                excludeSemantics: true,
                child: AppChoiceChip(
                  label: option.label,
                  isSelected: option == selected,
                  // The chip calls this on every tap, so it is never null;
                  // taps are ignored while saving.
                  onSelected: (_) {
                    if (isEnabled) {
                      type.value = option;
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// «Количество комнат» with the stepper; only the stepper follows [rooms].
final class _RoomsRow extends StatelessWidget {
  const _RoomsRow({required this.rooms, required this.onChanged});

  final ValueNotifier<int> rooms;

  /// `null` while saving.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Количество комнат',
            style: AppTypography.body.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: rooms,
          builder: (BuildContext context, int value, Widget? child) {
            return AppStepper(
              value: value,
              minimum: PropertyLimits.minRooms,
              maximum: PropertyLimits.maxRooms,
              decreaseLabel: 'Меньше комнат',
              increaseLabel: 'Больше комнат',
              onChanged: onChanged,
            );
          },
        ),
      ],
    );
  }
}

/// The server error of the rooms field, when there is one.
final class _RoomsError extends StatelessWidget {
  const _RoomsError();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddPropertyBloc, AddPropertyState, String?>(
      selector: (AddPropertyState state) =>
          propertyFieldErrorMessage(state.fieldErrors[AddPropertyFields.rooms]),
      builder: (BuildContext context, String? message) {
        if (message == null) {
          return const SizedBox.shrink();
        }
        return Text(
          message,
          style: AppTypography.caption.copyWith(color: AppColors.error),
        );
      },
    );
  }
}
