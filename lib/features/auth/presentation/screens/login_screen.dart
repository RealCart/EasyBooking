import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/phone_input_formatter.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_phone_country_fields.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/presentation/auth_failure_message.dart';
import 'package:easy_booking/features/auth/presentation/bloc/login_bloc/login_bloc.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_notice_card.dart';

/// Screen 11 «Вход»: asks for the phone number and sends the SMS code.
final class LoginScreen extends StatefulWidget {
  const LoginScreen({this.from, super.key});

  /// Location to open after sign-in; forwarded to the verification screen.
  final String? from;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: PhoneNumber.formatNational(context.read<LoginBloc>().state.phone),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    context.hideKeyboard();
    context.read<LoginBloc>().add(const LoginSubmitted());
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
      child: AuthFormLayout(
        header: AppDetailHeader(
          title: 'Вход',
          backSemanticLabel: 'Назад',
          showDivider: false,
          onBack: canPop ? () => context.pop() : null,
        ),
        title: 'Добро пожаловать',
        subtitle: 'Войдите, чтобы управлять квартирами и бронированиями.',
        footer: BlocBuilder<LoginBloc, LoginState>(
          buildWhen: (LoginState previous, LoginState current) =>
              previous.canSubmit != current.canSubmit ||
              previous.status != current.status,
          builder: (BuildContext context, LoginState state) {
            return AppFlowFooter(
              message: 'Для владельцев и участников команды',
              messageStyle: AppTypography.caption.copyWith(
                color: AppColors.secondaryText,
              ),
              primaryLabel: 'Получить код',
              onPrimaryPressed: state.canSubmit ? _submit : null,
              primaryLoading: state.status.isLoading,
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
                phoneHint: '(___)___-__-__',
                phoneController: _phoneController,
                phoneInputFormatters: const <TextInputFormatter>[
                  PhoneInputFormatter(),
                ],
                enabled: !isSending,
                onPhoneChanged: (String phone) {
                  context.read<LoginBloc>().add(LoginPhoneChanged(phone));
                },
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
    );
  }
}
