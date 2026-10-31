import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/phone_input_formatter.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_phone_country_fields.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/send_code_params_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/core/utils/error/auth_failure_message.dart';
import 'package:easy_booking/features/auth/presentation/bloc/login_bloc/login_bloc.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_notice_card.dart';

/// Screen 11 «Вход»: asks for the phone number and sends the SMS code.
///
/// Provides its own [LoginBloc] through [wrappedRoute].
final class LoginScreen extends StatefulWidget implements GoRouterWrapper {
  const LoginScreen({this.from, super.key});

  /// Location to open after sign-in; forwarded to the verification screen.
  final String? from;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<LoginBloc>(
      create: (_) =>
          LoginBloc(sendCode: dependencies.getDep<SendCodeUsecase>()),
      child: this,
    );
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends State<LoginScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _phoneController;
  late final FocusNode _phoneFocusNode;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _phoneController = TextEditingController();
    _phoneFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    context.hideKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<LoginBloc>().add(
      LoginSubmitted(SendCodeParamsEntity(phone: _phoneController.text)),
    );
  }

  void _openVerification(OtpChallengeEntity challenge) {
    context.pushNamed(
      AppRoutes.verifyCode.name,
      queryParameters: <String, String>{
        AppRoutes.phoneQuery: challenge.phone,
        AppRoutes.resendAfterQuery: '${challenge.resendAfter.inSeconds}',
        if (widget.from case final String from) AppRoutes.fromQuery: from,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = context.canPop();

    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (LoginState previous, LoginState current) =>
          previous.status != current.status &&
          (current.status.isSuccess || current.status.isFailure),
      listener: (BuildContext context, LoginState state) {
        if (state.challenge case final OtpChallengeEntity challenge
            when state.status.isSuccess) {
          _openVerification(challenge);
          return;
        }
        final Failure? failure = state.failure;
        if (failure != null && failure is! CancelledFailure) {
          context.showAppSnackbar(failure.authMessage);
        }
      },
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: AuthFormLayout(
          header: AppDetailHeader(
            title: 'Вход',
            backSemanticLabel: 'Назад',
            showDivider: false,
            onBack: canPop ? () => context.pop() : null,
          ),
          title: 'Добро пожаловать',
          subtitle: 'Войдите, чтобы управлять квартирами и бронированиями.',
          footer: BlocSelector<LoginBloc, LoginState, bool>(
            selector: (LoginState state) => state.status.isLoading,
            builder: (BuildContext context, bool isSending) {
              // Enabled once the number is complete; the form still validates
              // on submit.
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: _phoneController,
                builder: (_, TextEditingValue phone, _) {
                  final bool canSubmit =
                      !isSending && Validators.isValidPhone(phone.text);
                  return AppFlowFooter(
                    message: 'Для владельцев и участников команды',
                    messageStyle: AppTypography.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    primaryLabel: 'Получить код',
                    onPrimaryPressed: canSubmit ? _submit : null,
                    primaryLoading: isSending,
                  );
                },
              );
            },
          ),
          children: <Widget>[
            // The number cannot change while its code is being sent.
            BlocSelector<LoginBloc, LoginState, bool>(
              selector: (LoginState state) => state.status.isLoading,
              builder: (BuildContext context, bool isSending) {
                return AppPhoneCountryFields(
                  layout: AppPhoneCountryLayout.stacked,
                  countryLabel: 'Страна / регион',
                  countryValue: 'Казахстан (+7)',
                  // Only Kazakhstan numbers are supported for now.
                  isCountryReadOnly: true,
                  onCountryPressed: null,
                  phoneLabel: 'Номер телефона',
                  phoneHint: '+7 (___)___-__-__',
                  phoneController: _phoneController,
                  phoneFocusNode: _phoneFocusNode,
                  phoneValidator: FormValidators.phone,
                  onPhoneSubmitted: (_) => _submit(),
                  phoneInputFormatters: const <TextInputFormatter>[
                    PhoneInputFormatter(),
                  ],
                  enabled: !isSending,
                );
              },
            ),
            AuthNoticeCard(
              iconPath: AppAssets.icons.lock,
              message: 'Пришлём одноразовый код в SMS. Пароль не понадобится.',
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                'Продолжая, вы принимаете условия использования и политику '
                'конфиденциальности.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
