import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_progress_app_bar.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_file_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_fields.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/update_contract_guest_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_guest_bloc/contract_guest_bloc.dart';
import 'package:easy_booking/features/contracts/presentation/controllers/masked_text_editing_controller.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_file_cards.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_labels.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_load_placeholders.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_text_action.dart';

/// Screen 07 «Новый договор · 1 из 2 · Проверим данные гостя»: the host
/// checks the guest data recognized from the identity document. A signed
/// contract is shown read-only with a link to its status.
///
/// Provides its own [ContractGuestBloc] through [wrappedRoute].
final class ContractScreen extends StatefulWidget implements GoRouterWrapper {
  const ContractScreen({required this.contractId, super.key});

  final String contractId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<ContractGuestBloc>(
      create: (_) => ContractGuestBloc(
        getContract: dependencies.getDep<GetContractUsecase>(),
        updateGuest: dependencies.getDep<UpdateContractGuestUsecase>(),
      )..add(ContractGuestRequested(contractId)),
      child: this,
    );
  }

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

final class _ContractScreenState extends State<ContractScreen> {
  late final GlobalKey<FormState> _formKey;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _patronymicController;
  late final MaskedTextEditingController _iinController;
  late final MaskedTextEditingController _idNumberController;

  late final FocusNode _firstNameFocusNode;
  late final FocusNode _lastNameFocusNode;
  late final FocusNode _patronymicFocusNode;
  late final FocusNode _iinFocusNode;
  late final FocusNode _idNumberFocusNode;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _patronymicController = TextEditingController();
    _iinController = MaskedTextEditingController(visibleTail: 3);
    _idNumberController = MaskedTextEditingController(visibleTail: 4);
    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _patronymicFocusNode = FocusNode();
    _iinFocusNode = FocusNode();
    _idNumberFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _iinController.dispose();
    _idNumberController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _patronymicFocusNode.dispose();
    _iinFocusNode.dispose();
    _idNumberFocusNode.dispose();
    super.dispose();
  }

  /// Fills the form once, when the contract is loaded for the first time.
  void _fill(ContractGuestEntity guest) {
    _firstNameController.text = guest.firstName;
    _lastNameController.text = guest.lastName;
    _patronymicController.text = guest.patronymic ?? '';
    _iinController.text = guest.iin;
    _idNumberController.text = guest.idNumber;
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.today.name);
    }
  }

  void _onFieldEdited(String field) {
    context.read<ContractGuestBloc>().add(ContractGuestFieldEdited(field));
  }

  void _openRoute(AppRoutes route) {
    context.pushNamed(
      route.name,
      pathParameters: <String, String>{
        AppRoutes.contractIdParam: widget.contractId,
      },
    );
  }

  void _openStatus() {
    _openRoute(AppRoutes.contractStatus);
  }

  void _retry() {
    context.read<ContractGuestBloc>().add(
      ContractGuestRequested(widget.contractId),
    );
  }

  void _submit() {
    context.hideKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<ContractGuestBloc>().add(
      ContractGuestSubmitted(
        UpdateContractGuestParamsEntity(
          contractId: widget.contractId,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          patronymic: _patronymicController.text,
          iin: _iinController.text,
          idNumber: _idNumberController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<ContractGuestBloc, ContractGuestState>>[
        BlocListener<ContractGuestBloc, ContractGuestState>(
          listenWhen: (
            ContractGuestState previous,
            ContractGuestState current,
          ) => previous.contract == null && current.contract != null,
          listener: (BuildContext context, ContractGuestState state) {
            _fill(state.contract!.guest);
          },
        ),
        BlocListener<ContractGuestBloc, ContractGuestState>(
          listenWhen:
              (ContractGuestState previous, ContractGuestState current) =>
                  previous.submitStatus != current.submitStatus &&
                  current.submitStatus.isSuccess,
          listener: (BuildContext context, ContractGuestState state) {
            _openRoute(AppRoutes.contractSend);
          },
        ),
        BlocListener<ContractGuestBloc, ContractGuestState>(
          listenWhen:
              (ContractGuestState previous, ContractGuestState current) =>
                  previous.submitFailure != current.submitFailure &&
                  current.submitFailure != null,
          listener: (BuildContext context, ContractGuestState state) {
            final Failure? failure = state.submitFailure;
            // A cancelled submit was left by the user: nothing to report.
            if (failure != null && failure is! CancelledFailure) {
              context.showAppSnackbar(failure.contractMessage);
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _GuestHeader(onBack: _close),
              Expanded(
                child: _GuestBody(
                  formKey: _formKey,
                  // Built once here, so a rebuild of the body above it
                  // keeps the fields; they select their own state.
                  fields: _GuestFields(
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    patronymicController: _patronymicController,
                    iinController: _iinController,
                    idNumberController: _idNumberController,
                    firstNameFocusNode: _firstNameFocusNode,
                    lastNameFocusNode: _lastNameFocusNode,
                    patronymicFocusNode: _patronymicFocusNode,
                    iinFocusNode: _iinFocusNode,
                    idNumberFocusNode: _idNumberFocusNode,
                    onEdited: _onFieldEdited,
                  ),
                  onRetry: _retry,
                  onSubmit: _submit,
                  onOpenStatus: _openStatus,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Договор» for a signed contract, otherwise the «1 из 2» flow bar.
final class _GuestHeader extends StatelessWidget {
  const _GuestHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ContractGuestBloc, ContractGuestState, bool>(
      selector: (ContractGuestState state) =>
          state.contract?.status.isSigned ?? false,
      builder: (BuildContext context, bool isSigned) {
        if (isSigned) {
          return AppDetailHeader(
            title: 'Договор',
            backSemanticLabel: 'Назад',
            showDivider: false,
            onBack: onBack,
          );
        }
        return AppProgressAppBar(
          title: 'Новый договор',
          currentStep: 1,
          totalSteps: 2,
          backSemanticLabel: 'Назад',
          showDivider: false,
          onBack: onBack,
        );
      },
    );
  }
}

/// The skeleton or load error until the contract arrives, then the form
/// and its footer.
final class _GuestBody extends StatelessWidget {
  const _GuestBody({
    required this.formKey,
    required this.fields,
    required this.onRetry,
    required this.onSubmit,
    required this.onOpenStatus,
  });

  final GlobalKey<FormState> formKey;
  final Widget fields;
  final VoidCallback onRetry;
  final VoidCallback onSubmit;
  final VoidCallback onOpenStatus;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ContractGuestBloc, ContractGuestState, ContractEntity?>(
      selector: (ContractGuestState state) => state.contract,
      builder: (BuildContext context, ContractEntity? contract) {
        if (contract == null) {
          return _GuestPlaceholder(onRetry: onRetry);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _GuestForm(
                formKey: formKey,
                contract: contract,
                fields: fields,
              ),
            ),
            _GuestFooter(
              isSigned: contract.status.isSigned,
              onSubmit: onSubmit,
              onOpenStatus: onOpenStatus,
            ),
          ],
        );
      },
    );
  }
}

/// [ContractSkeleton] while loading, [ContractLoadError] after a failure.
final class _GuestPlaceholder extends StatelessWidget {
  const _GuestPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ContractGuestBloc, ContractGuestState, Failure?>(
      selector: (ContractGuestState state) => state.loadFailure,
      builder: (BuildContext context, Failure? failure) {
        if (failure == null) {
          return const ContractSkeleton();
        }
        return ContractLoadError(failure: failure, onRetry: onRetry);
      },
    );
  }
}

/// «Статус договора» for a signed contract, otherwise «Перейти к условиям»
/// that loads while the guest data is saved.
final class _GuestFooter extends StatelessWidget {
  const _GuestFooter({
    required this.isSigned,
    required this.onSubmit,
    required this.onOpenStatus,
  });

  final bool isSigned;
  final VoidCallback onSubmit;
  final VoidCallback onOpenStatus;

  @override
  Widget build(BuildContext context) {
    if (isSigned) {
      return AppFlowFooter(
        primaryLabel: 'Статус договора',
        onPrimaryPressed: onOpenStatus,
      );
    }
    return BlocSelector<ContractGuestBloc, ContractGuestState, bool>(
      selector: (ContractGuestState state) => state.submitStatus.isLoading,
      builder: (BuildContext context, bool isSubmitting) {
        return AppFlowFooter(
          message: 'Проверьте имя и номер документа перед продолжением',
          messageStyle: AppTypography.caption.copyWith(
            color: AppColors.secondaryText,
          ),
          primaryLabel: 'Перейти к условиям',
          onPrimaryPressed: isSubmitting ? null : onSubmit,
          primaryLoading: isSubmitting,
        );
      },
    );
  }
}

/// The scrollable form: title, identity document, [fields], and the
/// signing contact.
final class _GuestForm extends StatelessWidget {
  const _GuestForm({
    required this.formKey,
    required this.contract,
    required this.fields,
  });

  final GlobalKey<FormState> formKey;
  final ContractEntity contract;
  final Widget fields;

  @override
  Widget build(BuildContext context) {
    final bool isSigned = contract.status.isSigned;
    final ContractFileEntity? identityDocument = contract.identityDocument;

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pageGutter,
          20,
          AppSizes.pageGutter,
          AppSpacing.xLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Проверим данные гостя',
              style: AppTypography.compactScreenTitle.copyWith(
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              '${contract.guest.fullName} · ${contract.stay.propertyName}',
              style: AppTypography.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.xLarge),
            if (isSigned) ...const <Widget>[
              AppCallout(
                title: 'Договор подписан',
                message: 'Данные гостя нельзя изменить после подписи',
                tone: AppFeedbackTone.success,
              ),
              SizedBox(height: AppSpacing.xLarge),
            ],
            if (identityDocument != null) ...<Widget>[
              ContractIdentityDocumentCard(
                fileName: identityDocument.name,
                details: identityDocument.pagesAndSize,
                onReplace: isSigned
                    ? null
                    : () => context.showAppSnackbar(contractsComingSoonMessage),
              ),
              if (contract.isGuestDataRecognized)
                const _RecognizedNote()
              else
                const SizedBox(height: AppSpacing.xLarge),
            ],
            fields,
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              'Контакт для подписи',
              style: AppTypography.primaryText.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ContractMask.phone(contract.guest.phone),
              style: AppTypography.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The guest name, IIN, and ID number fields; read-only once signed.
final class _GuestFields extends StatelessWidget {
  const _GuestFields({
    required this.firstNameController,
    required this.lastNameController,
    required this.patronymicController,
    required this.iinController,
    required this.idNumberController,
    required this.firstNameFocusNode,
    required this.lastNameFocusNode,
    required this.patronymicFocusNode,
    required this.iinFocusNode,
    required this.idNumberFocusNode,
    required this.onEdited,
  });

  // IIN: twelve digits, ID card: nine; the masks keep the last 3 and 4.
  static const int _iinLength = 12;
  static const int _idNumberLength = 9;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController patronymicController;
  final MaskedTextEditingController iinController;
  final MaskedTextEditingController idNumberController;
  final FocusNode firstNameFocusNode;
  final FocusNode lastNameFocusNode;
  final FocusNode patronymicFocusNode;
  final FocusNode iinFocusNode;
  final FocusNode idNumberFocusNode;

  /// Called with the `ContractGuestFields` key of the edited field.
  final ValueChanged<String> onEdited;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ContractGuestBloc, ContractGuestState, bool>(
      selector: (ContractGuestState state) =>
          state.contract?.status.isSigned ?? false,
      builder: (BuildContext context, bool isReadOnly) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.large,
          children: <Widget>[
            _NameFields(
              firstName: _GuestTextField(
                field: ContractGuestFields.firstName,
                label: 'Имя',
                controller: firstNameController,
                focusNode: firstNameFocusNode,
                validator: FormValidators.required,
                isReadOnly: isReadOnly,
                autofillHints: const <String>[AutofillHints.givenName],
                onEdited: onEdited,
                onSubmitted: lastNameFocusNode.requestFocus,
              ),
              lastName: _GuestTextField(
                field: ContractGuestFields.lastName,
                label: 'Фамилия',
                controller: lastNameController,
                focusNode: lastNameFocusNode,
                validator: FormValidators.required,
                isReadOnly: isReadOnly,
                autofillHints: const <String>[AutofillHints.familyName],
                onEdited: onEdited,
                onSubmitted: patronymicFocusNode.requestFocus,
              ),
            ),
            _GuestTextField(
              field: ContractGuestFields.patronymic,
              label: 'Отчество',
              controller: patronymicController,
              focusNode: patronymicFocusNode,
              isReadOnly: isReadOnly,
              autofillHints: const <String>[AutofillHints.middleName],
              onEdited: onEdited,
              onSubmitted: iinFocusNode.requestFocus,
            ),
            _GuestTextField(
              field: ContractGuestFields.iin,
              label: 'ИИН',
              controller: iinController,
              focusNode: iinFocusNode,
              validator: FormValidators.iin,
              isReadOnly: isReadOnly,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_iinLength),
              ],
              trailing: _RevealAction(
                controller: iinController,
                valueName: 'ИИН',
              ),
              onEdited: onEdited,
              onSubmitted: idNumberFocusNode.requestFocus,
            ),
            _GuestTextField(
              field: ContractGuestFields.idNumber,
              label: 'Номер удостоверения',
              controller: idNumberController,
              focusNode: idNumberFocusNode,
              validator: FormValidators.idNumber,
              isReadOnly: isReadOnly,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_idNumberLength),
              ],
              trailing: _RevealAction(
                controller: idNumberController,
                valueName: 'номер удостоверения',
              ),
              onEdited: onEdited,
              onSubmitted: idNumberFocusNode.unfocus,
            ),
          ],
        );
      },
    );
  }
}

/// «Имя» and «Фамилия» side by side, stacked on narrow screens.
final class _NameFields extends StatelessWidget {
  const _NameFields({required this.firstName, required this.lastName});

  final Widget firstName;
  final Widget lastName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Two 16 px-padded fields need about 160 px each.
        if (constraints.maxWidth < 336) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.large,
            children: <Widget>[firstName, lastName],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.large,
          children: <Widget>[
            Expanded(child: firstName),
            Expanded(child: lastName),
          ],
        );
      },
    );
  }
}

/// A guest form field: validates itself in the `Form` and shows the server
/// error of its [field].
final class _GuestTextField extends StatelessWidget {
  const _GuestTextField({
    required this.field,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isReadOnly,
    required this.onEdited,
    required this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.autofillHints,
    this.trailing,
  });

  /// `ContractGuestFields` key of this field.
  final String field;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isReadOnly;

  /// Called with [field] when the text changes.
  final ValueChanged<String> onEdited;

  /// Moves the focus on when the keyboard action is pressed.
  final VoidCallback onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ContractGuestBloc,
      ContractGuestState,
      ({String? error, bool isSubmitting})
    >(
      selector: (ContractGuestState state) => (
        error: state.fieldErrors[field],
        isSubmitting: state.submitStatus.isLoading,
      ),
      builder:
          (BuildContext context, ({String? error, bool isSubmitting}) value) {
            return AppTextField(
              label: label,
              controller: controller,
              focusNode: focusNode,
              validator: isReadOnly ? null : validator,
              errorText: contractFieldErrorMessage(value.error),
              enabled: !value.isSubmitting,
              readOnly: isReadOnly,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              autocorrect: false,
              autofillHints: isReadOnly ? null : autofillHints,
              trailing: trailing,
              onChanged: (_) => onEdited(field),
              onSubmitted: (_) => onSubmitted(),
            );
          },
    );
  }
}

/// «Показать» / «Скрыть» inside a masked field. Listens to [controller]
/// itself, so toggling the mask rebuilds only this action and the field.
final class _RevealAction extends StatelessWidget {
  const _RevealAction({required this.controller, required this.valueName});

  final MaskedTextEditingController controller;

  /// What is revealed, for the screen reader: `ИИН`.
  final String valueName;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final String label = controller.isMasked ? 'Показать' : 'Скрыть';
        return ContractTextAction(
          label: label,
          semanticLabel: '$label $valueName',
          onPressed: () => controller.isMasked = !controller.isMasked,
        );
      },
    );
  }
}

/// «Данные распознаны. Сверьте с документом.»
final class _RecognizedNote extends StatelessWidget {
  const _RecognizedNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.large,
        bottom: AppSpacing.xLarge,
      ),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: SvgPicture.asset(
              AppAssets.icons.checkSmall,
              width: AppSizes.iconInline,
              height: AppSizes.iconInline,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'Данные распознаны. Сверьте с документом.',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
