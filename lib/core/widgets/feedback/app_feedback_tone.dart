import 'package:flutter/material.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
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

  String get iconPath => switch (this) {
    AppFeedbackTone.success => AppAssets.icons.statusSuccess,
    AppFeedbackTone.info => AppAssets.icons.statusInfo,
    AppFeedbackTone.warning => AppAssets.icons.statusWarning,
    AppFeedbackTone.error => AppAssets.icons.statusError,
  };
}
