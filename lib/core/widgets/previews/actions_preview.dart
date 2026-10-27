import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:easy_booking/core/widgets/actions/app_button.dart';
import 'package:easy_booking/core/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/widgets/actions/app_status_badge.dart';
import 'package:easy_booking/core/widgets/actions/app_stepper.dart';
import 'package:easy_booking/core/widgets/previews/app_preview_gallery.dart';

@Preview(
  name: 'Actions',
  group: 'EasyBooking Core Widgets',
  size: Size(430, 900),
  wrapper: appWidgetPreviewWrapper,
)
Widget actionsWidgetPreview() => const _ActionsPreview();

class _ActionsPreview extends StatefulWidget {
  const _ActionsPreview();

  @override
  State<_ActionsPreview> createState() => _ActionsPreviewState();
}

class _ActionsPreviewState extends State<_ActionsPreview> {
  int _selectedPropertyType = 0;
  int _guestCount = 2;

  @override
  Widget build(BuildContext context) {
    return AppPreviewGallery(
      title: 'Actions',
      description: 'Tap every enabled control to test its interaction state.',
      children: <Widget>[
        AppPreviewSection(
          title: 'Buttons',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton(
                label: 'Continue',
                isExpanded: true,
                onPressed: () => _notify('Primary button tapped'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Open document',
                isExpanded: true,
                variant: AppButtonVariant.secondary,
                onPressed: () => _notify('Secondary button tapped'),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Remind',
                variant: AppButtonVariant.text,
                leading: const Icon(Icons.notifications_none, size: 18),
                onPressed: () => _notify('Text button tapped'),
              ),
              const SizedBox(height: 8),
              const Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton(
                      label: 'Loading',
                      isLoading: true,
                      isExpanded: true,
                      onPressed: null,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Disabled',
                      isExpanded: true,
                      onPressed: null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Icon actions',
          description: 'Every target is at least 44 × 44.',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              AppIconButton(
                icon: const Icon(Icons.arrow_back),
                semanticLabel: 'Back',
                onPressed: () => _notify('Back tapped'),
              ),
              AppIconButton(
                icon: const Icon(Icons.more_horiz),
                semanticLabel: 'More',
                onPressed: () => _notify('More tapped'),
              ),
              AppIconButton(
                icon: const Icon(Icons.bookmark_outline),
                semanticLabel: 'Save',
                onPressed: () => _notify('Save tapped'),
              ),
              const AppIconButton(
                icon: Icon(Icons.chevron_right),
                semanticLabel: 'Disabled action',
                onPressed: null,
              ),
            ],
          ),
        ),
        const AppPreviewSection(
          title: 'Status badges',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              AppStatusBadge(
                label: 'Signed',
                variant: AppStatusBadgeVariant.success,
                icon: Icon(Icons.check_circle_outline),
              ),
              AppStatusBadge(
                label: 'Waiting',
                variant: AppStatusBadgeVariant.warning,
                icon: Icon(Icons.schedule),
              ),
              AppStatusBadge(
                label: 'Conflict',
                variant: AppStatusBadgeVariant.error,
                icon: Icon(Icons.error_outline),
              ),
              AppStatusBadge(
                label: 'Synced',
                variant: AppStatusBadgeVariant.info,
                icon: Icon(Icons.sync),
              ),
              AppStatusBadge(label: 'Draft'),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Choice chips',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (int index = 0; index < _propertyTypes.length; index++)
                AppChoiceChip(
                  label: _propertyTypes[index],
                  isSelected: _selectedPropertyType == index,
                  onSelected: (bool isSelected) {
                    if (isSelected) {
                      setState(() => _selectedPropertyType = index);
                    }
                  },
                ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Stepper',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Guests'),
              AppStepper(
                value: _guestCount,
                maximum: 8,
                onChanged: (int value) {
                  setState(() => _guestCount = value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _notify(String message) => showPreviewMessage(context, message);

  static const List<String> _propertyTypes = <String>[
    'Apartment',
    'House',
    'Room',
  ];
}
