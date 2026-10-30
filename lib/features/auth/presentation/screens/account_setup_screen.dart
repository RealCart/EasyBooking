import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/presentation/auth_failure_message.dart';
import 'package:easy_booking/features/auth/presentation/bloc/account_setup_bloc/account_setup_bloc.dart';
import 'package:easy_booking/features/auth/presentation/widgets/account_city_field.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:easy_booking/features/auth/presentation/widgets/city_labels.dart';
import 'package:easy_booking/features/auth/presentation/widgets/city_picker_sheet.dart';

/// Screen 13 «Ваш аккаунт»: creates the account of a new user. After
/// creation, or after leaving (which signs out), the router redirect moves
/// the user on.
final class AccountSetupScreen extends StatelessWidget {
  const AccountSetupScreen({super.key});

  void _cancel(BuildContext context) {
    context.read<AccountSetupBloc>().add(const AccountSetupCancelled());
  }

  void _submit(BuildContext context) {
    context.hideKeyboard();
    context.read<AccountSetupBloc>().add(const AccountSetupSubmitted());
  }

  Future<void> _onCityPressed(BuildContext context) async {
    final AccountSetupBloc bloc = context.read<AccountSetupBloc>();
    context.hideKeyboard();
    final CityEntity? city = await showCityPickerSheet(
      context,
      selected: bloc.state.city,
    );
    if (city == null || bloc.isClosed) {
      return;
    }
    bloc.add(AccountCitySelected(city));
  }

  @override
  Widget build(BuildContext context) {
    final AccountSetupState initial = context.read<AccountSetupBloc>().state;

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
            _cancel(context);
          }
        },
        child: AuthFormLayout(
          header: BlocSelector<AccountSetupBloc, AccountSetupState, bool>(
            selector: (AccountSetupState state) => state.status.isLoading,
            builder: (BuildContext context, bool isCreating) {
              return AppDetailHeader(
                title: 'Ваш аккаунт',
                backSemanticLabel: 'Назад',
                showDivider: false,
                isBackEnabled: !isCreating,
                onBack: () => _cancel(context),
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
                onPrimaryPressed: isBusy ? null : () => _submit(context),
                primaryLoading: isBusy,
              );
            },
          ),
          children: <Widget>[
            _AccountTextField(
              field: AccountFields.firstName,
              label: 'Имя',
              initialValue: initial.firstName,
              autofillHints: const <String>[AutofillHints.givenName],
              onChanged: (String value) => context.read<AccountSetupBloc>().add(
                AccountFirstNameChanged(value),
              ),
            ),
            _AccountTextField(
              field: AccountFields.lastName,
              label: 'Фамилия',
              initialValue: initial.lastName,
              autofillHints: const <String>[AutofillHints.familyName],
              onChanged: (String value) => context.read<AccountSetupBloc>().add(
                AccountLastNameChanged(value),
              ),
            ),
            _AccountTextField(
              field: AccountFields.email,
              label: 'Email для документов',
              initialValue: initial.email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              autofillHints: const <String>[AutofillHints.email],
              onChanged: (String value) => context.read<AccountSetupBloc>().add(
                AccountEmailChanged(value),
              ),
            ),
            _AccountTextField(
              field: AccountFields.teamName,
              label: 'Название команды',
              initialValue: initial.teamName,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.organizationName],
              onChanged: (String value) => context.read<AccountSetupBloc>().add(
                AccountTeamNameChanged(value),
              ),
            ),
            BlocBuilder<AccountSetupBloc, AccountSetupState>(
              buildWhen:
                  (AccountSetupState previous, AccountSetupState current) =>
                      previous.city != current.city ||
                      previous.status.isLoading != current.status.isLoading ||
                      previous.fieldErrors[AccountFields.city] !=
                          current.fieldErrors[AccountFields.city],
              builder: (BuildContext context, AccountSetupState state) {
                return AccountCityField(
                  label: 'Город и часовой пояс',
                  hint: 'Выберите город',
                  value: state.city?.nameWithOffset,
                  errorText: authFieldErrorMessage(
                    state.fieldErrors[AccountFields.city],
                  ),
                  enabled: !state.status.isLoading,
                  onPressed: () => _onCityPressed(context),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A text field of the account form that shows its own field error.
final class _AccountTextField extends StatelessWidget {
  const _AccountTextField({
    required this.field,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autocorrect = true,
    this.autofillHints,
  });

  /// `AccountFields` key of this field.
  final String field;
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
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
              initialValue: initialValue,
              errorText: authFieldErrorMessage(value.error),
              enabled: !value.isCreating,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autocorrect: autocorrect,
              autofillHints: autofillHints,
              onChanged: onChanged,
            );
          },
    );
  }
}
