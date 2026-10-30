import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_resend_timer_row.dart';
import 'package:easy_booking/features/auth/presentation/auth_failure_message.dart';
import 'package:easy_booking/features/auth/presentation/bloc/verify_code_bloc/verify_code_bloc.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_notice_card.dart';
import 'package:easy_booking/features/auth/presentation/widgets/otp_code_field.dart';

/// Screen 12 «Подтверждение»: checks the SMS code. After a successful check
/// the router redirect leaves this screen.
final class VerifyCodeScreen extends StatelessWidget {
  const VerifyCodeScreen({required this.phone, this.from, super.key});

  /// E.164 number the code was sent to.
  final String phone;

  /// Location to open after sign-in, kept when returning to login.
  final String? from;

  void _backToLogin(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(
      AppRoutes.login.name,
      queryParameters: <String, String>{
        if (from case final String from) AppRoutes.fromQuery: from,
      },
    );
  }

  static String? _visibleMessage(Failure? failure) {
    if (failure == null || failure is CancelledFailure) {
      return null;
    }
    return failure.authMessage;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyCodeBloc, VerifyCodeState>(
      listenWhen: (VerifyCodeState previous, VerifyCodeState current) =>
          previous.resendStatus != current.resendStatus &&
          current.resendStatus.isFailure,
      listener: (BuildContext context, VerifyCodeState state) {
        if (_visibleMessage(state.resendFailure) case final String message) {
          context.showAppSnackbar(message);
        }
      },
      child: AuthFormLayout(
        header: AppDetailHeader(
          title: 'Подтверждение',
          backSemanticLabel: 'Назад',
          showDivider: false,
          onBack: () => _backToLogin(context),
        ),
        title: 'Введите код из SMS',
        subtitle: 'Отправили на ${PhoneNumber.format(phone)}',
        footer: BlocBuilder<VerifyCodeBloc, VerifyCodeState>(
          buildWhen: (VerifyCodeState previous, VerifyCodeState current) =>
              previous.canSubmit != current.canSubmit ||
              previous.verifyStatus != current.verifyStatus,
          builder: (BuildContext context, VerifyCodeState state) {
            return AppFlowFooter(
              primaryLabel: 'Подтвердить',
              onPrimaryPressed: state.canSubmit
                  ? () => context.read<VerifyCodeBloc>().add(
                      const VerifyCodeSubmitted(),
                    )
                  : null,
              primaryLoading: state.verifyStatus.isLoading,
            );
          },
        ),
        children: <Widget>[
          BlocBuilder<VerifyCodeBloc, VerifyCodeState>(
            buildWhen: (VerifyCodeState previous, VerifyCodeState current) =>
                previous.code != current.code ||
                previous.verifyFailure != current.verifyFailure ||
                previous.verifyStatus != current.verifyStatus,
            builder: (BuildContext context, VerifyCodeState state) {
              return OtpCodeField(
                code: state.code,
                errorText: _visibleMessage(state.verifyFailure),
                autofocus: true,
                readOnly: state.verifyStatus.isLoading,
                onChanged: (String code) {
                  context.read<VerifyCodeBloc>().add(VerifyCodeChanged(code));
                },
              );
            },
          ),
          BlocBuilder<VerifyCodeBloc, VerifyCodeState>(
            buildWhen: (VerifyCodeState previous, VerifyCodeState current) =>
                previous.resendAvailableIn != current.resendAvailableIn ||
                previous.canResend != current.canResend,
            builder: (BuildContext context, VerifyCodeState state) {
              final bool isWaiting = state.resendAvailableIn > Duration.zero;
              final String? waitingText = isWaiting
                  ? 'Можно через '
                        '${DateFormatter.countdown(state.resendAvailableIn)}'
                  : null;
              return AppResendTimerRow(
                prompt: waitingText ?? 'Код не пришёл? Отправим новый',
                actionLabel: 'Отправить код повторно',
                subtitle: waitingText,
                leading: SvgPicture.asset(
                  AppAssets.icons.clock,
                  width: AppSizes.iconAppBar,
                  height: AppSizes.iconAppBar,
                  colorFilter: const ColorFilter.mode(
                    AppColors.text,
                    BlendMode.srcIn,
                  ),
                ),
                remaining: state.resendAvailableIn,
                onResend: () {
                  if (state.canResend) {
                    context.read<VerifyCodeBloc>().add(
                      const VerifyCodeResendRequested(),
                    );
                  }
                },
              );
            },
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _backToLogin(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSizes.touchTarget),
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.text,
                overlayColor: Colors.transparent,
                textStyle: AppTypography.action.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
              child: const Text('Изменить номер телефона'),
            ),
          ),
          AuthNoticeCard(
            iconPath: AppAssets.icons.lock,
            message:
                'Код действует 5 минут. Никому не сообщайте его, даже '
                'сотрудникам поддержки.',
          ),
        ],
      ),
    );
  }
}
