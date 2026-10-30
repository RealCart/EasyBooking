import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/widgets/actions/app_primary_button.dart';
import 'package:easy_booking/core/widgets/actions/app_secondary_button.dart';
import 'package:easy_booking/core/widgets/actions/app_status_badge.dart';
import 'package:easy_booking/core/widgets/actions/app_stepper.dart';
import 'package:easy_booking/core/widgets/actions/app_text_button.dart';
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
  bool _isSaved = true;

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
              AppPrimaryButton(
                label: 'Continue',
                onPressed: () => _notify('Primary button tapped'),
              ),
              const SizedBox(height: 12),
              AppSecondaryButton(
                label: 'Open document',
                onPressed: () => _notify('Secondary button tapped'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 24,
                children: <Widget>[
                  AppTextButton.underlined(
                    label: 'Изменить',
                    onPressed: () => _notify('Edit tapped'),
                  ),
                  AppTextButton.accent(
                    label: 'Remind',
                    onPressed: () => _notify('Remind tapped'),
                  ),
                  AppTextButton.muted(
                    label: 'Cancel',
                    onPressed: () => _notify('Cancel tapped'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: <Widget>[
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Loading',
                      isLoading: true,
                      onPressed: null,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Disabled',
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
              AppBackIconButton(
                onPressed: () => _notify('Back tapped'),
              ),
              AppMoreIconButton(
                onPressed: () => _notify('More tapped'),
              ),
              AppSavedIconButton(
                isSaved: _isSaved,
                onPressed: () => setState(() => _isSaved = !_isSaved),
              ),
              const AppChevronIconButton(
                onPressed: null,
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Status badges',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              const AppStatusBadge(
                label: 'Signed',
                variant: AppStatusBadgeVariant.success,
              ),
              const AppStatusBadge(
                label: 'Waiting',
                variant: AppStatusBadgeVariant.warning,
              ),
              const AppStatusBadge(
                label: 'Conflict',
                variant: AppStatusBadgeVariant.error,
              ),
              AppStatusBadge(
                label: 'Synced',
                variant: AppStatusBadgeVariant.info,
                icon: SvgPicture.asset(
                  AppAssets.icons.refresh,
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    AppColors.info,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const AppStatusBadge(label: 'Draft'),
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
