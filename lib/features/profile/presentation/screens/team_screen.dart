import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_primary_button.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_phone_country_fields.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/phone_input_formatter.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_team_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/invite_team_member_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/remove_team_member_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/team_bloc/team_bloc.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_detail_layout.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_failure_message.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_footnote.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_list_row.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_section_label.dart';
import 'package:easy_booking/features/profile/presentation/widgets/team_labels.dart';
import 'package:easy_booking/features/profile/presentation/widgets/team_role_row.dart';

/// Screen 31 «Команда и доступ»: the members, the roles, and inviting a
/// member through a form in a bottom sheet. Tapping a member other than
/// the current user offers to revoke their access.
///
/// Provides its own [TeamBloc] through [wrappedRoute].
final class TeamScreen extends StatelessWidget implements GoRouterWrapper {
  const TeamScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<TeamBloc>(
      create: (_) => TeamBloc(
        getTeam: dependencies.getDep<GetTeamUsecase>(),
        inviteTeamMember: dependencies.getDep<InviteTeamMemberUsecase>(),
        removeTeamMember: dependencies.getDep<RemoveTeamMemberUsecase>(),
      )..add(const TeamRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<TeamBloc, TeamState>>[
        BlocListener<TeamBloc, TeamState>(
          listenWhen: (TeamState previous, TeamState current) =>
              previous.inviteStatus != current.inviteStatus &&
              current.inviteStatus.isSuccess,
          listener: (BuildContext context, TeamState state) {
            context.showAppSnackbar('Приглашение отправлено');
          },
        ),
        BlocListener<TeamBloc, TeamState>(
          listenWhen: (TeamState previous, TeamState current) =>
              previous.removeStatus != current.removeStatus &&
              (current.removeStatus.isSuccess ||
                  current.removeStatus.isFailure),
          listener: (BuildContext context, TeamState state) {
            final Failure? failure = state.removeFailure;
            context.showAppSnackbar(
              failure == null ? 'Доступ отозван' : failure.profileMessage,
            );
          },
        ),
        // Only a failed refresh: the first failure replaces the list.
        BlocListener<TeamBloc, TeamState>(
          listenWhen: (TeamState previous, TeamState current) =>
              previous.loadStatus != current.loadStatus &&
              current.loadStatus.isFailure &&
              current.members.isNotEmpty,
          listener: (BuildContext context, TeamState state) {
            context.showAppSnackbar(state.loadFailure!.profileMessage);
          },
        ),
      ],
      child: const ProfileDetailLayout(
        title: 'Команда и доступ',
        action: _InviteIconButton(),
        body: _TeamBody(),
        footer: _InviteFooter(),
      ),
    );
  }
}

/// Inviting is offered once the team is loaded.
bool _isTeamLoaded(TeamState state) {
  return state.members.isNotEmpty || state.loadStatus.isSuccess;
}

/// The invite form stays busy after success until the sheet closes.
bool _isInviteSending(TeamState state) {
  return state.inviteStatus.isLoading || state.inviteStatus.isSuccess;
}

/// Opens the invite form, first clearing the result of the previous invite
/// so the form starts empty and enabled.
Future<void> _openInvite(BuildContext context) {
  final TeamBloc bloc = context.read<TeamBloc>()
    ..add(const TeamInviteStarted());
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) {
      return BlocProvider<TeamBloc>.value(
        value: bloc,
        child: const _InviteSheet(),
      );
    },
  );
}

/// The header «+».
final class _InviteIconButton extends StatelessWidget {
  const _InviteIconButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeamBloc, TeamState, bool>(
      selector: _isTeamLoaded,
      builder: (BuildContext context, bool isLoaded) {
        return AppIconButton(
          semanticLabel: 'Пригласить участника',
          onPressed: isLoaded ? () => _openInvite(context) : null,
          icon: SvgPicture.asset(
            AppAssets.icons.plus,
            width: AppSizes.iconAppBar,
            height: AppSizes.iconAppBar,
            colorFilter: const ColorFilter.mode(
              AppColors.text,
              BlendMode.srcIn,
            ),
          ),
        );
      },
    );
  }
}

/// The sticky «Пригласить участника».
final class _InviteFooter extends StatelessWidget {
  const _InviteFooter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeamBloc, TeamState, bool>(
      selector: _isTeamLoaded,
      builder: (BuildContext context, bool isLoaded) {
        return AppFlowFooter(
          primaryLabel: 'Пригласить участника',
          onPrimaryPressed: isLoaded ? () => _openInvite(context) : null,
        );
      },
    );
  }
}

/// The skeleton or the load error until the team is loaded, then the list.
final class _TeamBody extends StatelessWidget {
  const _TeamBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamBloc, TeamState>(
      buildWhen: (TeamState previous, TeamState current) =>
          _isTeamLoaded(previous) != _isTeamLoaded(current) ||
          (!_isTeamLoaded(current) &&
              previous.loadFailure != current.loadFailure),
      builder: (BuildContext context, TeamState state) {
        if (_isTeamLoaded(state)) {
          return const _TeamList();
        }
        final Failure? failure = state.loadFailure;
        if (failure != null) {
          return ProfileLoadError(
            title: 'Не удалось загрузить команду',
            failure: failure,
            onRetry: () => context.read<TeamBloc>().add(const TeamRequested()),
          );
        }
        return const ProfileListSkeleton();
      },
    );
  }
}

/// The members, the roles, and the invitation note, with pull-to-refresh.
final class _TeamList extends StatelessWidget {
  const _TeamList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
        children: <Widget>[
          const _TeamSummary(),
          const _TeamMembers(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.pageGutter,
              AppSpacing.xLarge,
              AppSizes.pageGutter,
              AppSpacing.small,
            ),
            child: ProfileSectionTitle(title: 'Роли'),
          ),
          for (final ProfileRole role in teamAssignableRoles)
            TeamRoleRow(role: role),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.pageGutter,
              20,
              AppSizes.pageGutter,
              0,
            ),
            child: ProfileFootnote(
              text:
                  'Приглашение действует 72 часа. Доступ можно отозвать в '
                  'любой момент.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context) {
    final TeamBloc bloc = context.read<TeamBloc>();
    bloc.add(const TeamRequested());
    return bloc.stream.firstWhere(
      (TeamState state) => !state.loadStatus.isLoading,
    );
  }
}

/// The member rows. Tapping a member other than the current user offers to
/// revoke their access.
final class _TeamMembers extends StatelessWidget {
  const _TeamMembers();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamBloc, TeamState>(
      buildWhen: (TeamState previous, TeamState current) =>
          previous.members != current.members ||
          previous.removingMemberId != current.removingMemberId ||
          previous.removeStatus.isLoading != current.removeStatus.isLoading,
      builder: (BuildContext context, TeamState state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final TeamMemberEntity member in state.members)
              _TeamMemberRow(
                member: member,
                isRemoving: state.removingMemberId == member.id,
                onTap: member.isCurrentUser || state.removeStatus.isLoading
                    ? null
                    : () => _confirmRemove(context, member),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    TeamMemberEntity member,
  ) async {
    final TeamBloc bloc = context.read<TeamBloc>();
    final bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppConfirmationDialog(
          title: 'Отозвать доступ?',
          message:
              '${member.fullName} больше не сможет открывать объекты '
              'команды.',
          cancelLabel: 'Отмена',
          confirmLabel: 'Отозвать',
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    if (isConfirmed ?? false) {
      bloc.add(TeamMemberRemoveRequested(member.id));
    }
  }
}

/// «3 участника» and what the screen is for.
final class _TeamSummary extends StatelessWidget {
  const _TeamSummary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        18,
        AppSizes.pageGutter,
        AppSpacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xSmall,
        children: <Widget>[
          BlocSelector<TeamBloc, TeamState, int>(
            selector: (TeamState state) => state.members.length,
            builder: (BuildContext context, int memberCount) {
              return Text(
                teamMemberCountLabel(memberCount),
                style: AppTypography.largeTitle.copyWith(
                  color: AppColors.text,
                ),
              );
            },
          ),
          Text(
            'Распределяйте объекты и права без передачи пароля.',
            style: AppTypography.compactBody.copyWith(
              height: 19 / 13,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

final class _TeamMemberRow extends StatelessWidget {
  const _TeamMemberRow({
    required this.member,
    required this.isRemoving,
    required this.onTap,
  });

  final TeamMemberEntity member;

  /// Shows a progress indicator instead of the role.
  final bool isRemoving;

  /// Offers to revoke the access; `null` for the current user.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileListRow(
      title: member.fullName,
      subtitle: member.accessLabel,
      leading: ProfileAvatar(initials: member.initials),
      trailing: isRemoving
          ? const SizedBox.square(
              dimension: AppSizes.iconInline,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : ProfileTrailingLabel(
              label: member.role.teamLabel,
              color: member.status == TeamMemberStatus.invited
                  ? AppColors.secondaryText
                  : AppColors.text,
            ),
      onTap: onTap,
    );
  }
}

/// «Пригласить участника»: name, phone, and role. Closes itself once the
/// invitation is sent.
final class _InviteSheet extends StatefulWidget {
  const _InviteSheet();

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

final class _InviteSheetState extends State<_InviteSheet> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final FocusNode _firstNameFocusNode;
  late final FocusNode _lastNameFocusNode;
  late final FocusNode _phoneFocusNode;

  /// The picked role; only the chips and the description listen to it.
  late final ValueNotifier<ProfileRole> _role;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _role = ValueNotifier<ProfileRole>(teamAssignableRoles.first);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _role.dispose();
    super.dispose();
  }

  void _onFieldEdited(String field) {
    context.read<TeamBloc>().add(TeamInviteFieldEdited(field));
  }

  void _submit() {
    context.hideKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<TeamBloc>().add(
      TeamInviteSubmitted(
        InviteTeamMemberParamsEntity(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
          role: _role.value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TeamBloc, TeamState>(
      listenWhen: (TeamState previous, TeamState current) =>
          previous.inviteStatus != current.inviteStatus &&
          current.inviteStatus.isSuccess,
      listener: (BuildContext context, TeamState state) {
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            AppSpacing.large,
            AppSizes.pageGutter,
            AppSpacing.xLarge,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Expanded(
                      child: ProfileSectionTitle(
                        title: 'Пригласить участника',
                      ),
                    ),
                    _InviteCloseButton(),
                  ],
                ),
                Text(
                  'Отправим SMS со ссылкой. Приглашение действует 72 часа.',
                  style: AppTypography.caption.copyWith(
                    height: 18 / 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                const _InviteFailureCallout(),
                _InviteTextField(
                  field: ProfileFields.firstName,
                  label: 'Имя',
                  controller: _firstNameController,
                  focusNode: _firstNameFocusNode,
                  onEdited: _onFieldEdited,
                  onSubmitted: (_) => _lastNameFocusNode.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.medium),
                _InviteTextField(
                  field: ProfileFields.lastName,
                  label: 'Фамилия',
                  controller: _lastNameController,
                  focusNode: _lastNameFocusNode,
                  onEdited: _onFieldEdited,
                  onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.medium),
                _InvitePhoneFields(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  onEdited: _onFieldEdited,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xLarge),
                Text(
                  'Роль',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 18 / 14,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _InviteRoleChips(role: _role),
                const SizedBox(height: AppSpacing.small),
                _InviteRoleDescription(role: _role),
                const SizedBox(height: AppSpacing.xLarge),
                _InviteSubmitButton(onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Закрыть»; disabled while the invitation is being sent.
final class _InviteCloseButton extends StatelessWidget {
  const _InviteCloseButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeamBloc, TeamState, bool>(
      selector: _isInviteSending,
      builder: (BuildContext context, bool isSending) {
        return AppIconButton(
          semanticLabel: 'Закрыть',
          onPressed: isSending ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: AppSizes.iconAppBar),
        );
      },
    );
  }
}

/// An invite failure that does not belong to a field, followed by its gap;
/// nothing without one.
final class _InviteFailureCallout extends StatelessWidget {
  const _InviteFailureCallout();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeamBloc, TeamState, Failure?>(
      selector: (TeamState state) => state.inviteFailure,
      builder: (BuildContext context, Failure? failure) {
        if (failure == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppCallout(
              title: 'Не удалось пригласить',
              message: failure.profileMessage,
              tone: AppFeedbackTone.error,
            ),
            const SizedBox(height: AppSpacing.large),
          ],
        );
      },
    );
  }
}

/// A required name field; rebuilds only for its own server error and the
/// sending state.
final class _InviteTextField extends StatelessWidget {
  const _InviteTextField({
    required this.field,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onEdited,
    required this.onSubmitted,
  });

  /// The `ProfileFields` key of the field.
  final String field;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onEdited;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeamBloc, TeamState, (bool, String?)>(
      selector: (TeamState state) =>
          (_isInviteSending(state), state.inviteFieldErrors[field]),
      builder: (BuildContext context, (bool, String?) fieldState) {
        final (bool isSending, String? errorCode) = fieldState;
        return AppTextField(
          label: label,
          controller: controller,
          focusNode: focusNode,
          validator: FormValidators.required,
          errorText: profileFieldErrorMessage(errorCode),
          enabled: !isSending,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onEdited(field),
          onSubmitted: onSubmitted,
        );
      },
    );
  }
}

/// The read-only `+7` code and the phone field.
final class _InvitePhoneFields extends StatelessWidget {
  const _InvitePhoneFields({
    required this.controller,
    required this.focusNode,
    required this.onEdited,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onEdited;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeamBloc, TeamState, (bool, String?)>(
      selector: (TeamState state) => (
        _isInviteSending(state),
        state.inviteFieldErrors[ProfileFields.phone],
      ),
      builder: (BuildContext context, (bool, String?) fieldState) {
        final (bool isSending, String? errorCode) = fieldState;
        return AppPhoneCountryFields(
          countryLabel: 'Код',
          countryValue: '+7',
          // Only Kazakhstan numbers are supported for now.
          isCountryReadOnly: true,
          onCountryPressed: null,
          phoneLabel: 'Телефон',
          phoneHint: '700 123 45 67',
          phoneController: controller,
          phoneFocusNode: focusNode,
          phoneValidator: FormValidators.phone,
          phoneErrorText: profileFieldErrorMessage(errorCode),
          onPhoneChanged: (_) => onEdited(ProfileFields.phone),
          onPhoneSubmitted: onSubmitted,
          phoneInputFormatters: const <TextInputFormatter>[
            PhoneInputFormatter(),
          ],
          enabled: !isSending,
        );
      },
    );
  }
}

/// The role chips. A role cannot be changed while the invitation is sent.
final class _InviteRoleChips extends StatelessWidget {
  const _InviteRoleChips({required this.role});

  final ValueNotifier<ProfileRole> role;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProfileRole>(
      valueListenable: role,
      builder: (BuildContext context, ProfileRole selected, _) {
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: <Widget>[
            for (final ProfileRole option in teamAssignableRoles)
              Semantics(
                button: true,
                selected: option == selected,
                label: option.teamLabel,
                child: AppChoiceChip(
                  label: option.teamLabel,
                  isSelected: option == selected,
                  onSelected: (_) {
                    if (!_isInviteSending(context.read<TeamBloc>().state)) {
                      role.value = option;
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

/// What the picked role may do.
final class _InviteRoleDescription extends StatelessWidget {
  const _InviteRoleDescription({required this.role});

  final ValueListenable<ProfileRole> role;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProfileRole>(
      valueListenable: role,
      builder: (BuildContext context, ProfileRole selected, _) {
        return Text(
          selected.description,
          style: AppTypography.caption.copyWith(
            height: 18 / 12,
            color: AppColors.secondaryText,
          ),
        );
      },
    );
  }
}

/// «Отправить приглашение», busy while the invitation is sent.
final class _InviteSubmitButton extends StatelessWidget {
  const _InviteSubmitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeamBloc, TeamState, bool>(
      selector: _isInviteSending,
      builder: (BuildContext context, bool isSending) {
        return AppPrimaryButton(
          label: 'Отправить приглашение',
          onPressed: onPressed,
          isLoading: isSending,
        );
      },
    );
  }
}
