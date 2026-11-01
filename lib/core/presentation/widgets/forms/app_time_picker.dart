import 'package:flutter/material.dart';

/// Shows the Material time picker in the 24-hour format, whatever the device
/// setting, and completes with the picked time or `null` when dismissed.
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    builder: (BuildContext context, Widget? child) =>
        _TwentyFourHourFormat(child: child ?? const SizedBox.shrink()),
  );
}

/// Forces the 24-hour format on the picker below it.
final class _TwentyFourHourFormat extends StatelessWidget {
  const _TwentyFourHourFormat({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child,
    );
  }
}
