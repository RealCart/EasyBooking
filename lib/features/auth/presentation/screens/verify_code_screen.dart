import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_resend_timer_row.dart';
import 'package:easy_booking/features/auth/domain/entity/verify_code_params_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';
import 'package:easy_booking/core/utils/error/auth_failure_message.dart';
import 'package:easy_booking/features/auth/presentation/bloc/verify_code_bloc/verify_code_bloc.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:easy_booking/features/auth/presentation/widgets/auth_notice_card.dart';
import 'package:easy_booking/features/auth/presentation/widgets/otp_code_field.dart';

/// Screen 12 «Подтверждение»: checks the SMS code. After a successful check
/// the router redirect leaves this screen.
///
/// Provides its own [VerifyCodeBloc] through [wrappedRoute] and starts it
/// with [phone] and [resendAfter].
final class VerifyCodeScreen extends StatefulWidget implements GoRouterWrapper {
  const VerifyCodeScreen({
    required this.phone,
    required this.resendAfter,
    this.from,
    super.key,
  });

  /// E.164 number the code was sent to.
  final String phone;

  /// Time left before another code may be requested.
  final Duration resendAfter;

  /// Location to open after sign-in, kept when returning to login.
  final String? from;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<VerifyCodeBloc>(
      create: (_) => VerifyCodeBloc(
        verifyCode: dependencies.getDep<VerifyCodeUsecase>(),
        sendCode: dependencies.getDep<SendCodeUsecase>(),
      )..add(VerifyCodeStarted(phone: phone, resendAfter: resendAfter)),
      child: this,
    );
  }

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

final class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _codeController;
  late final FocusNode _codeFocusNode;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _codeController = TextEditingController();
    _codeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged(String code) {
    final VerifyCodeBloc bloc = context.read<VerifyCodeBloc>()
      ..add(const VerifyCodeEdited());
    // The last digit submits without a tap.
    if (code.length == Validators.otpLength && bloc.state.canSubmit) {
      _submit();
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<VerifyCodeBloc>().add(
      VerifyCodeSubmitted(
        VerifyCodeParamsEntity(
          phone: widget.phone,
          code: _codeController.text,
        ),
      ),
    );
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(
      AppRoutes.login.name,
      queryParameters: <String, String>{
        if (widget.from case final String from) AppRoutes.fromQuery: from,
      },
    );
  }

  static String? _visibleMessage(Failure? failure) {
    if (failure == null || failure is CancelledFailure) {
      return null;
    }
    return failure.authMessage;
  }

  static bool _clearsCode(VerifyCodeState previous, VerifyCodeState current) {
    final bool verifyFailed =
        previous.verifyStatus != current.verifyStatus &&
        current.verifyStatus.isFailure;
    final bool codeResent =
        previous.resendStatus != current.resendStatus &&
        current.resendStatus.isSuccess;
    return verifyFailed || codeResent;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<VerifyCodeBloc, VerifyCodeState>>[
        BlocListener<VerifyCodeBloc, VerifyCodeState>(
          listenWhen: (VerifyCodeState previous, VerifyCodeState current) =>
              previous.resendStatus != current.resendStatus &&
              current.resendStatus.isFailure,
          listener: (BuildContext context, VerifyCodeState state) {
            if (_visibleMessage(state.resendFailure)
                case final String message) {
              context.showAppSnackbar(message);
            }
          },
        ),
        // A rejected code is cleared so the next one can be typed; a new
        // code makes the old digits useless.
        BlocListener<VerifyCodeBloc, VerifyCodeState>(
          listenWhen: _clearsCode,
          listener: (_, _) => _codeController.clear(),
        ),
      ],
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: AuthFormLayout(
          header: AppDetailHeader(
            title: 'Подтверждение',
            backSemanticLabel: 'Назад',
            showDivider: false,
            onBack: _backToLogin,
          ),
          title: 'Введите код из SMS',
          subtitle: 'Отправили на ${PhoneNumber.format(widget.phone)}',
          footer: BlocBuilder<VerifyCodeBloc, VerifyCodeState>(
            buildWhen: (VerifyCodeState previous, VerifyCodeState current) =>
                previous.canSubmit != current.canSubmit ||
                previous.verifyStatus != current.verifyStatus,
            builder: (BuildContext context, VerifyCodeState state) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: _codeController,
                builder: (_, TextEditingValue code, _) {
                  final bool canSubmit =
                      state.canSubmit &&
                      code.text.length == Validators.otpLength;
                  return AppFlowFooter(
                    primaryLabel: 'Подтвердить',
                    onPrimaryPressed: canSubmit ? _submit : null,
                    primaryLoading: state.verifyStatus.isLoading,
                  );
                },
              );
            },
          ),
          children: <Widget>[
            BlocBuilder<VerifyCodeBloc, VerifyCodeState>(
              buildWhen: (VerifyCodeState previous, VerifyCodeState current) =>
                  previous.verifyFailure != current.verifyFailure ||
                  previous.verifyStatus != current.verifyStatus,
              builder: (BuildContext context, VerifyCodeState state) {
                return OtpCodeField(
                  controller: _codeController,
                  focusNode: _codeFocusNode,
                  validator: FormValidators.otp,
                  errorText: _visibleMessage(state.verifyFailure),
                  autofocus: true,
                  readOnly: state.verifyStatus.isLoading,
                  onChanged: _onCodeChanged,
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
                onPressed: _backToLogin,
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
      ),
    );
  }
}
