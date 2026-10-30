import 'package:flutter/material.dart';

import 'package:easy_booking/core/widgets/content/app_file_row.dart';

class AppDocumentTile extends StatelessWidget {
  const AppDocumentTile({
    required this.fileName,
    this.details,
    this.actionLabel = 'Remove',
    this.onAction,
    this.leading,
    super.key,
  });

  final String fileName;
  final String? details;
  final String actionLabel;
  final VoidCallback? onAction;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return AppFileRow(
      fileName: fileName,
      details: details,
    );
  }
}
