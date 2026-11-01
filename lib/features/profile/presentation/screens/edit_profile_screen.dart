import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_picker_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/extensions/string_extensions.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_details_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/edit_profile_bloc/edit_profile_bloc.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_detail_layout.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_failure_message.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_footnote.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_labels.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_section_label.dart';

/// Screen 30 «Редактировать профиль»: personal data and the workspace.
/// The phone is read-only. Leaves the screen after a successful save.
///
/// Provides its own [EditProfileBloc] through [wrappedRoute].
final class EditProfileScreen extends StatefulWidget
    implements GoRouterWrapper {
  const EditProfileScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<EditProfileBloc>(
      create: (_) => EditProfileBloc(
        getProfileDetails: dependencies.getDep<GetProfileDetailsUsecase>(),
        updateProfile: dependencies.getDep<UpdateProfileUsecase>(),
      )..add(const EditProfileStarted()),
      child: this,
    );
  }

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

final class _EditProfileScreenState extends State<EditProfileScreen> {
  late final GlobalKey<FormState> _formKey;
  late final GlobalKey<FormFieldState<CityEntity>> _cityFieldKey;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _teamNameController;

  /// Read-only: follows the picked city.
  late final TextEditingController _timeZoneController;

  late final FocusNode _firstNameFocusNode;
  late final FocusNode _lastNameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _teamNameFocusNode;

  /// Whether the controllers were filled from the loaded details. They are
  /// filled once, so a later state never overwrites what the user typed.
  late bool _isFilled;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _cityFieldKey = GlobalKey<FormFieldState<CityEntity>>();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _teamNameController = TextEditingController();
    _timeZoneController = TextEditingController();
    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _teamNameFocusNode = FocusNode();
    _isFilled = false;
    final ProfileDetailsEntity? details = context
        .read<EditProfileBloc>()
        .state
        .details;
    if (details != null) {
      _fill(details);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _teamNameController.dispose();
    _timeZoneController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _teamNameFocusNode.dispose();
    super.dispose();
  }

  void _fill(ProfileDetailsEntity details) {
    if (_isFilled) {
      return;
    }
    _isFilled = true;
    _firstNameController.text = details.firstName;
    _lastNameController.text = details.lastName;
    _emailController.text = details.email;
    _teamNameController.text = details.teamName;
    _timeZoneController.text = details.city.timeZoneLabel;
  }

  void _onFieldEdited(String field) {
    context.read<EditProfileBloc>().add(EditProfileFieldEdited(field));
  }

  void _onCityChanged(CityEntity city) {
    _timeZoneController.text = city.timeZoneLabel;
    _onFieldEdited(ProfileFields.city);
  }

  void _submit() {
    context.hideKeyboard();
    final bool isValid = _formKey.currentState?.validate() ?? false;
    // The city validator guarantees a value once the form is valid.
    final CityEntity? city = _cityFieldKey.currentState?.value;
    if (!isValid || city == null) {
      return;
    }
    context.read<EditProfileBloc>().add(
      EditProfileSubmitted(
        UpdateProfileParamsEntity(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          teamName: _teamNameController.text,
          city: city,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<EditProfileBloc, EditProfileState>>[
        BlocListener<EditProfileBloc, EditProfileState>(
          listenWhen: (EditProfileState previous, EditProfileState current) =>
              previous.details == null && current.details != null,
          listener: (BuildContext context, EditProfileState state) {
            _fill(state.details!);
          },
        ),
        BlocListener<EditProfileBloc, EditProfileState>(
          listenWhen: (EditProfileState previous, EditProfileState current) =>
              previous.saveStatus != current.saveStatus &&
              current.saveStatus.isSuccess,
          listener: (BuildContext context, EditProfileState state) {
            context.pop();
          },
        ),
        BlocListener<EditProfileBloc, EditProfileState>(
          listenWhen: (EditProfileState previous, EditProfileState current) =>
              previous.saveFailure != current.saveFailure &&
              current.saveFailure != null,
          listener: (BuildContext context, EditProfileState state) {
            context.showAppSnackbar(state.saveFailure!.profileMessage);
          },
        ),
      ],
      child: _EditProfileFrame(
        // Built here, outside the frame's selector, so a change of the saving
        // state does not rebuild the form.
        body: _EditProfileBody(
          formKey: _formKey,
          cityFieldKey: _cityFieldKey,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          emailController: _emailController,
          teamNameController: _teamNameController,
          timeZoneController: _timeZoneController,
          firstNameFocusNode: _firstNameFocusNode,
          lastNameFocusNode: _lastNameFocusNode,
          emailFocusNode: _emailFocusNode,
          teamNameFocusNode: _teamNameFocusNode,
          onFieldEdited: _onFieldEdited,
          onCityChanged: _onCityChanged,
        ),
        footer: _SaveFooter(onSave: _submit),
      ),
    );
  }
}

/// Busy after success too, until the screen is left.
bool _isSaving(EditProfileState state) {
  return state.saveStatus.isLoading || state.saveStatus.isSuccess;
}

/// The layout; only the back button follows the saving state.
final class _EditProfileFrame extends StatelessWidget {
  const _EditProfileFrame({required this.body, required this.footer});

  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EditProfileBloc, EditProfileState, bool>(
      selector: _isSaving,
      builder: (BuildContext context, bool isSaving) {
        return ProfileDetailLayout(
          title: 'Редактировать профиль',
          isBackEnabled: !isSaving,
          body: body,
          footer: footer,
        );
      },
    );
  }
}

/// «Сохранить»: enabled once the details are loaded, busy while saving.
final class _SaveFooter extends StatelessWidget {
  const _SaveFooter({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EditProfileBloc, EditProfileState, (bool, bool)>(
      selector: (EditProfileState state) =>
          (state.details != null, _isSaving(state)),
      builder: (BuildContext context, (bool, bool) saveState) {
        final (bool hasDetails, bool isSaving) = saveState;
        return AppFlowFooter(
          primaryLabel: 'Сохранить',
          onPrimaryPressed: hasDetails && !isSaving ? onSave : null,
          primaryLoading: isSaving,
        );
      },
    );
  }
}

/// The skeleton or the load error until the details are loaded, then the
/// form.
final class _EditProfileBody extends StatelessWidget {
  const _EditProfileBody({
    required this.formKey,
    required this.cityFieldKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.teamNameController,
    required this.timeZoneController,
    required this.firstNameFocusNode,
    required this.lastNameFocusNode,
    required this.emailFocusNode,
    required this.teamNameFocusNode,
    required this.onFieldEdited,
    required this.onCityChanged,
  });

  final GlobalKey<FormState> formKey;
  final GlobalKey<FormFieldState<CityEntity>> cityFieldKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController teamNameController;
  final TextEditingController timeZoneController;
  final FocusNode firstNameFocusNode;
  final FocusNode lastNameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode teamNameFocusNode;

  /// Called with the `ProfileFields` key of the edited field.
  final ValueChanged<String> onFieldEdited;
  final ValueChanged<CityEntity> onCityChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditProfileBloc, EditProfileState>(
      buildWhen: (EditProfileState previous, EditProfileState current) =>
          previous.details != current.details ||
          (current.details == null &&
              previous.loadFailure != current.loadFailure),
      builder: (BuildContext context, EditProfileState state) {
        final ProfileDetailsEntity? details = state.details;
        if (details != null) {
          return _EditProfileForm(
            details: details,
            formKey: formKey,
            cityFieldKey: cityFieldKey,
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            emailController: emailController,
            teamNameController: teamNameController,
            timeZoneController: timeZoneController,
            firstNameFocusNode: firstNameFocusNode,
            lastNameFocusNode: lastNameFocusNode,
            emailFocusNode: emailFocusNode,
            teamNameFocusNode: teamNameFocusNode,
            onFieldEdited: onFieldEdited,
            onCityChanged: onCityChanged,
          );
        }
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          return ProfileLoadError(
            title: 'Не удалось загрузить профиль',
            failure: failure,
            onRetry: () => context.read<EditProfileBloc>().add(
              const EditProfileStarted(),
            ),
          );
        }
        return const ProfileListSkeleton(rowCount: 4);
      },
    );
  }
}

/// The form for the loaded [details]. Each field selects its own server
/// error and the saving state.
final class _EditProfileForm extends StatelessWidget {
  const _EditProfileForm({
    required this.details,
    required this.formKey,
    required this.cityFieldKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.teamNameController,
    required this.timeZoneController,
    required this.firstNameFocusNode,
    required this.lastNameFocusNode,
    required this.emailFocusNode,
    required this.teamNameFocusNode,
    required this.onFieldEdited,
    required this.onCityChanged,
  });

  final ProfileDetailsEntity details;
  final GlobalKey<FormState> formKey;
  final GlobalKey<FormFieldState<CityEntity>> cityFieldKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController teamNameController;
  final TextEditingController timeZoneController;
  final FocusNode firstNameFocusNode;
  final FocusNode lastNameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode teamNameFocusNode;
  final ValueChanged<String> onFieldEdited;
  final ValueChanged<CityEntity> onCityChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pageGutter,
          AppSpacing.medium,
          AppSizes.pageGutter,
          AppSpacing.xLarge,
        ),
        children: <Widget>[
          _PhotoHeader(name: details.fullName),
          const SizedBox(height: AppSpacing.xLarge),
          const ProfileSectionTitle(title: 'Личные данные'),
          const SizedBox(height: 18),
          _FieldPair(
            first: _EditProfileTextField(
              field: ProfileFields.firstName,
              label: 'Имя',
              controller: firstNameController,
              focusNode: firstNameFocusNode,
              validator: FormValidators.required,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.givenName],
              onEdited: onFieldEdited,
              onSubmitted: (_) => lastNameFocusNode.requestFocus(),
            ),
            second: _EditProfileTextField(
              field: ProfileFields.lastName,
              label: 'Фамилия',
              controller: lastNameController,
              focusNode: lastNameFocusNode,
              validator: FormValidators.required,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.familyName],
              onEdited: onFieldEdited,
              onSubmitted: (_) => emailFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          // The sign-in number changes only through a verified flow.
          AppTextField(
            label: 'Телефон',
            initialValue: PhoneNumber.format(details.phone),
            readOnly: true,
          ),
          const SizedBox(height: AppSpacing.large),
          _EditProfileTextField(
            field: ProfileFields.email,
            label: 'Электронная почта',
            controller: emailController,
            focusNode: emailFocusNode,
            validator: FormValidators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            autofillHints: const <String>[AutofillHints.email],
            onEdited: onFieldEdited,
            onSubmitted: (_) => teamNameFocusNode.requestFocus(),
          ),
          const SizedBox(height: 30),
          const ProfileSectionTitle(title: 'Рабочее пространство'),
          const SizedBox(height: 18),
          _EditProfileTextField(
            field: ProfileFields.teamName,
            label: 'Название',
            controller: teamNameController,
            focusNode: teamNameFocusNode,
            validator: FormValidators.required,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.organizationName],
            onEdited: onFieldEdited,
            onSubmitted: (_) => teamNameFocusNode.unfocus(),
          ),
          const SizedBox(height: AppSpacing.large),
          _FieldPair(
            first: _CityPickerField(
              fieldKey: cityFieldKey,
              initialCity: details.city,
              onChanged: onCityChanged,
            ),
            second: AppTextField(
              label: 'Часовой пояс',
              controller: timeZoneController,
              readOnly: true,
            ),
          ),
          const SizedBox(height: 28),
          ProfileFootnote(
            icon: SvgPicture.asset(
              AppAssets.icons.alertCircle,
              width: AppSizes.iconInline,
              height: AppSizes.iconInline,
            ),
            text: 'Телефон используется для входа и важных уведомлений.',
          ),
        ],
      ),
    );
  }
}

/// An editable text field that rebuilds only for its own server error and
/// the saving state.
final class _EditProfileTextField extends StatelessWidget {
  const _EditProfileTextField({
    required this.field,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.textInputAction,
    required this.autofillHints,
    required this.onEdited,
    required this.onSubmitted,
    this.keyboardType,
    this.autocorrect = true,
  });

  /// The `ProfileFields` key of the field.
  final String field;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String> onEdited;
  final ValueChanged<String> onSubmitted;
  final TextInputType? keyboardType;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EditProfileBloc, EditProfileState, (bool, String?)>(
      selector: (EditProfileState state) =>
          (_isSaving(state), state.fieldErrors[field]),
      builder: (BuildContext context, (bool, String?) fieldState) {
        final (bool isSaving, String? errorCode) = fieldState;
        return AppTextField(
          label: label,
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          errorText: profileFieldErrorMessage(errorCode),
          enabled: !isSaving,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autocorrect: autocorrect,
          autofillHints: autofillHints,
          onChanged: (_) => onEdited(field),
          onSubmitted: onSubmitted,
        );
      },
    );
  }
}

/// «Город»: the picker keeps the chosen city itself; the screen reads it
/// through [fieldKey] on submit.
final class _CityPickerField extends StatelessWidget {
  const _CityPickerField({
    required this.fieldKey,
    required this.initialCity,
    required this.onChanged,
  });

  static const AppPickerSheetTexts _sheetTexts = AppPickerSheetTexts(
    title: 'Город',
    subtitle: 'Часовой пояс подставим по городу',
    searchHint: 'Найти город',
    searchExample: 'Например, Шымкент',
    emptyTitle: 'Город не найден',
    emptyMessage:
        'Проверьте написание. Пока доступны только города Казахстана.',
  );

  final GlobalKey<FormFieldState<CityEntity>> fieldKey;
  final CityEntity initialCity;
  final ValueChanged<CityEntity> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EditProfileBloc, EditProfileState, (bool, String?)>(
      selector: (EditProfileState state) =>
          (_isSaving(state), state.fieldErrors[ProfileFields.city]),
      builder: (BuildContext context, (bool, String?) fieldState) {
        final (bool isSaving, String? errorCode) = fieldState;
        return AppPickerField<CityEntity>(
          key: fieldKey,
          label: 'Город',
          hint: 'Выберите город',
          initialValue: initialCity,
          options: KazakhstanCities.all,
          titleOf: (CityEntity city) => city.name,
          subtitleOf: (CityEntity city) => city.timeZoneLabel,
          sheetTexts: _sheetTexts,
          validator: FormValidators.selected,
          errorText: profileFieldErrorMessage(errorCode),
          enabled: !isSaving,
          onChanged: onChanged,
        );
      },
    );
  }
}

/// The avatar, the name, and «Изменить фотографию».
final class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.small, bottom: 26),
        child: Row(
          children: <Widget>[
            ProfileAvatar(initials: name.initials, size: 72),
            const SizedBox(width: AppSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.primaryText.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 22 / 17,
                      color: AppColors.text,
                    ),
                  ),
                  AppTextButton.underlined(
                    label: 'Изменить фотографию',
                    onPressed: context.showComingSoon,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two fields side by side, stacked when the screen is too narrow.
final class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.first, required this.second});

  static const double _stackBelowWidth = 320;

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < _stackBelowWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.large,
            children: <Widget>[first, second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.large,
          children: <Widget>[
            Expanded(child: first),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
