import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';

enum AppFeedbackTone { success, info, warning, error }

extension AppFeedbackToneColors on AppFeedbackTone {
  Color get foregroundColor => switch (this) {
    AppFeedbackTone.success => AppColors.success,
    AppFeedbackTone.info => AppColors.info,
    AppFeedbackTone.warning => AppColors.warning,
    AppFeedbackTone.error => AppColors.error,
  };

  Color get backgroundColor => switch (this) {
    AppFeedbackTone.success => AppColors.successSurface,
    AppFeedbackTone.info => AppColors.infoSurface,
    AppFeedbackTone.warning => AppColors.warningSurface,
    AppFeedbackTone.error => AppColors.errorSurface,
  };

  IconData get icon => switch (this) {
    AppFeedbackTone.success => Icons.check_circle_outline,
    AppFeedbackTone.info => Icons.info_outline,
    AppFeedbackTone.warning => Icons.warning_amber_rounded,
    AppFeedbackTone.error => Icons.error_outline,
  };
}
