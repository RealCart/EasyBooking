import 'package:flutter/material.dart';

import 'package:easy_booking/core/presentation/widgets/feedback/app_snackbar.dart';

extension ContextExtensions on BuildContext {
  /// Replaces the visible snackbar with an [AppSnackbar].
  void showAppSnackbar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackbar(
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ).toSnackBar(),
      );
  }

  void hideKeyboard() => FocusScope.of(this).unfocus();
}
