import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/field_error_message.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_picker_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/core/utils/error/auth_failure_message.dart';
import 'package:easy_booking/features/auth/presentation/bloc/account_setup_bloc/account_setup_bloc.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:easy_booking/features/auth/presentation/widgets/city_labels.dart';

/// Screen 13 «Ваш аккаунт»: creates the account of a new user. After
/// creation, or after leaving (which signs out), the router redirect moves
/// the user on.
///
/// Provides its own [AccountSetupBloc] through [wrappedRoute].
final class AccountSetupScreen extends StatefulWidget
    implements GoRouterWrapper {
  const AccountSetupScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<AccountSetupBloc>(
      create: (_) => AccountSetupBloc(
        createAccount: dependencies.getDep<CreateAccountUsecase>(),
        signOut: dependencies.getDep<SignOutUsecase>(),
      ),
      child: this,
    );
  }

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

final class _AccountSetupScreenState extends State<AccountSetupScreen> {
  static const AppPickerSheetTexts _citySheetTexts = AppPickerSheetTexts(
    title: 'Город',
    subtitle: 'Часовой пояс подставим по городу',
    searchHint: 'Найти город',
    searchExample: 'Например, Шымкент',
    emptyTitle: 'Город не найден',
    emptyMessage:
        'Проверьте написание. Пока доступны только города Казахстана.',
  );

  late final GlobalKey<FormState> _formKey;
  late final GlobalKey<FormFieldState<CityEntity>> _cityFieldKey;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _teamNameController;

  late final FocusNode _firstNameFocusNode;
  late final FocusNode _lastNameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _teamNameFocusNode;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _cityFieldKey = GlobalKey<FormFieldState<CityEntity>>();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _teamNameController = TextEditingController();
    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _teamNameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _teamNameController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _teamNameFocusNode.dispose();
    super.dispose();
  }

  void _cancel() {
    context.read<AccountSetupBloc>().add(const AccountSetupCancelled());
  }

  void _onFieldEdited(String field) {
    context.read<AccountSetupBloc>().add(AccountFieldEdited(field));
  }

  void _submit() {
    context.hideKeyboard();
    final bool isValid = _formKey.currentState?.validate() ?? false;
    // The city validator guarantees a value once the form is valid.
    final CityEntity? city = _cityFieldKey.currentState?.value;
    if (!isValid || city == null) {
      return;
    }
    context.read<AccountSetupBloc>().add(
      AccountSetupSubmitted(
        CreateAccountParamsEntity(
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
    return BlocListener<AccountSetupBloc, AccountSetupState>(
      listenWhen: (AccountSetupState previous, AccountSetupState current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (BuildContext context, AccountSetupState state) {
        final Failure? failure = state.failure;
        if (failure != null && failure is! CancelledFailure) {
          context.showAppSnackbar(failure.authMessage);
        }
      },
      child: PopScope(
        // System back leaves account setup the same way as the header, but
        // not while the account is being created.
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? _) {
          if (!didPop &&
              !context.read<AccountSetupBloc>().state.status.isLoading) {
            _cancel();
          }
        },
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          child: AuthFormLayout(
            header: BlocSelector<AccountSetupBloc, AccountSetupState, bool>(
              selector: (AccountSetupState state) => state.status.isLoading,
              builder: (BuildContext context, bool isCreating) {
                return AppDetailHeader(
                  title: 'Ваш аккаунт',
                  backSemanticLabel: 'Назад',
                  showDivider: false,
                  isBackEnabled: !isCreating,
                  onBack: _cancel,
                );
              },
            ),
            title: 'Как к вам обращаться?',
            subtitle: 'Эти данные увидят гости в документах.',
            footer: BlocSelector<AccountSetupBloc, AccountSetupState, bool>(
              // Stays busy after success until the router leaves the screen.
              selector: (AccountSetupState state) =>
                  state.status.isLoading || state.status.isSuccess,
              builder: (BuildContext context, bool isBusy) {
                return AppFlowFooter(
                  message: 'Реквизиты для договоров добавите в настройках',
                  messageStyle: AppTypography.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  primaryLabel: 'Создать аккаунт',
                  onPrimaryPressed: isBusy ? null : _submit,
                  primaryLoading: isBusy,
                );
              },
            ),
            children: <Widget>[
              _AccountTextField(
                field: AccountFields.firstName,
                label: 'Имя',
                controller: _firstNameController,
                focusNode: _firstNameFocusNode,
                validator: FormValidators.required,
                autofillHints: const <String>[AutofillHints.givenName],
                onChanged: _onFieldEdited,
                onSubmitted: _lastNameFocusNode.requestFocus,
              ),
              _AccountTextField(
                field: AccountFields.lastName,
                label: 'Фамилия',
                controller: _lastNameController,
                focusNode: _lastNameFocusNode,
                validator: FormValidators.required,
                autofillHints: const <String>[AutofillHints.familyName],
                onChanged: _onFieldEdited,
                onSubmitted: _emailFocusNode.requestFocus,
              ),
              _AccountTextField(
                field: AccountFields.email,
                label: 'Email для документов',
                controller: _emailController,
                focusNode: _emailFocusNode,
                validator: FormValidators.email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.email],
                onChanged: _onFieldEdited,
                onSubmitted: _teamNameFocusNode.requestFocus,
              ),
              _AccountTextField(
                field: AccountFields.teamName,
                label: 'Название команды',
                controller: _teamNameController,
                focusNode: _teamNameFocusNode,
                validator: FormValidators.required,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.organizationName],
                onChanged: _onFieldEdited,
                onSubmitted: _teamNameFocusNode.unfocus,
              ),
              BlocBuilder<AccountSetupBloc, AccountSetupState>(
                buildWhen:
                    (AccountSetupState previous, AccountSetupState current) =>
                        previous.status.isLoading != current.status.isLoading ||
                        previous.fieldErrors[AccountFields.city] !=
                            current.fieldErrors[AccountFields.city],
                builder: (BuildContext context, AccountSetupState state) {
                  return AppPickerField<CityEntity>(
                    key: _cityFieldKey,
                    label: 'Город и часовой пояс',
                    hint: 'Выберите город',
                    options: KazakhstanCities.all,
                    titleOf: (CityEntity city) => city.name,
                    subtitleOf: (CityEntity city) => city.utcOffsetLabel,
                    valueLabelOf: (CityEntity city) => city.nameWithOffset,
                    sheetTexts: _citySheetTexts,
                    validator: FormValidators.selected,
                    errorText: fieldErrorMessage(
                      state.fieldErrors[AccountFields.city],
                    ),
                    enabled: !state.status.isLoading,
                    onChanged: (_) => _onFieldEdited(AccountFields.city),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A text field of the account form: validates itself in the `Form` and
/// shows the server error of its [field].
final class _AccountTextField extends StatelessWidget {
  const _AccountTextField({
    required this.field,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.onChanged,
    required this.onSubmitted,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autocorrect = true,
    this.autofillHints,
  });

  /// `AccountFields` key of this field.
  final String field;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;

  /// Called with [field] when the text changes.
  final ValueChanged<String> onChanged;

  /// Moves the focus on when the keyboard action is pressed.
  final VoidCallback onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool autocorrect;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AccountSetupBloc,
      AccountSetupState,
      ({String? error, bool isCreating})
    >(
      selector: (AccountSetupState state) => (
        error: state.fieldErrors[field],
        isCreating: state.status.isLoading,
      ),
      builder:
          (BuildContext context, ({String? error, bool isCreating}) value) {
            return AppTextField(
              label: label,
              controller: controller,
              focusNode: focusNode,
              validator: validator,
              errorText: fieldErrorMessage(value.error),
              enabled: !value.isCreating,
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
