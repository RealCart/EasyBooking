import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/widgets/content/app_account_identity.dart';
import 'package:easy_booking/core/widgets/content/app_arrival_card.dart';
import 'package:easy_booking/core/widgets/content/app_calendar_event_row.dart';
import 'package:easy_booking/core/widgets/content/app_channel_connector.dart';
import 'package:easy_booking/core/widgets/content/app_contract_preview.dart';
import 'package:easy_booking/core/widgets/content/app_file_row.dart';
import 'package:easy_booking/core/widgets/content/app_guest_booking_summary.dart';
import 'package:easy_booking/core/widgets/content/app_key_value_list.dart';
import 'package:easy_booking/core/widgets/content/app_listing_card.dart';
import 'package:easy_booking/core/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/widgets/content/app_property_row.dart';
import 'package:easy_booking/core/widgets/content/app_selected_property_card.dart';
import 'package:easy_booking/core/widgets/content/app_sync_summary.dart';
import 'package:easy_booking/core/widgets/content/app_task_row.dart';
import 'package:easy_booking/core/widgets/content/app_workspace_summary.dart';
import 'package:easy_booking/core/widgets/previews/app_preview_gallery.dart';

@Preview(
  name: 'Content & Lists',
  group: 'EasyBooking Core Widgets',
  size: Size(430, 900),
  wrapper: appWidgetPreviewWrapper,
)
Widget contentWidgetsPreview() => const ContentWidgetsPreview();

class ContentWidgetsPreview extends StatelessWidget {
  const ContentWidgetsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    void notify(String message) => showPreviewMessage(context, message);

    final Widget chevronAction = IconButton(
      tooltip: 'Open',
      onPressed: () => notify('Trailing action pressed'),
      icon: const Icon(Icons.chevron_right_rounded),
    );

    return AppPreviewGallery(
      title: 'Content & Lists',
      description:
          'Tap cards, rows, and trailing actions to verify interaction states.',
      children: <Widget>[
        AppPreviewSection(
          title: 'Listings & properties',
          child: Column(
            children: <Widget>[
              AppListingCard(
                title: 'Esentai City · apartment 84',
                subtitle: 'Al-Farabi 77/8 · 2 rooms',
                details: '2 channels · updated at 09:38',
                price: '42 500 ₸',
                unitLabel: 'per night',
                badgeLabel: 'Arrival today',
                image: const AppPreviewImage(height: 168),
                action: IconButton(
                  tooltip: 'More',
                  onPressed: () => notify('Listing menu opened'),
                  icon: const Icon(Icons.more_horiz),
                ),
                onTap: () => notify('Listing opened'),
              ),
              const SizedBox(height: 16),
              AppPropertyRow(
                title: 'Mega Towers · 126',
                subtitle: 'Kablukova 264 · 1 room',
                status: 'Available until 25 October',
                price: '32 000 ₸',
                unitLabel: 'per night',
                image: const AppPreviewImage(height: 56),
                action: chevronAction,
                onTap: () => notify('Property opened'),
              ),
              const SizedBox(height: 16),
              AppSelectedPropertyCard(
                title: 'Samal Residence · 12',
                stayDetails: '22–24 October · 2 nights',
                guestName: 'Daniyar Muratov',
                image: const AppPreviewImage(height: 64),
                action: IconButton(
                  tooltip: 'Change property',
                  onPressed: () => notify('Property chooser opened'),
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
                onTap: () => notify('Selected property opened'),
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Arrivals & operations',
          child: Column(
            children: <Widget>[
              AppArrivalCard(
                time: '14:00',
                propertyName: 'Esentai City · 84',
                stayDetails: 'Aizhan · 3 nights',
                status: 'Ready for arrival',
                action: chevronAction,
                onTap: () => notify('Arrival opened'),
              ),
              const SizedBox(height: 12),
              AppTaskRow(
                title: 'Daniyar’s agreement',
                subtitle: 'Samal · not signed yet',
                leading: const Icon(Icons.assignment_outlined),
                action: TextButton(
                  onPressed: () => notify('Reminder sent'),
                  child: const Text('Remind'),
                ),
                onTap: () => notify('Task opened'),
              ),
              AppCalendarEventRow(
                time: '14:00',
                title: 'Arrival · Aizhan',
                propertyName: 'Esentai City · apartment 84',
                subtitle: '3 nights · agreement signed',
                action: chevronAction,
                onTap: () => notify('Calendar event opened'),
              ),
              AppGuestBookingSummary(
                guestName: 'Aizhan Sarsenova',
                stayDetails: '22–25 Oct · 3 nights · 2 guests',
                trailingText: '14:00',
                action: chevronAction,
                onTap: () => notify('Guest booking opened'),
              ),
              AppChannelConnector(
                title: 'Booking.com',
                subtitle: 'iCal calendar link',
                leading: const Icon(Icons.language_rounded),
                action: TextButton(
                  onPressed: () => notify('Booking.com connected'),
                  child: const Text('Connect'),
                ),
                onTap: () => notify('Channel details opened'),
              ),
              AppProfileMenuItem(
                title: 'Guests & agreements',
                subtitle: 'Documents, signatures, templates',
                leading: const Icon(Icons.people_outline_rounded),
                onTap: () => notify('Profile menu opened'),
                showDivider: false,
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Terms & documents',
          child: Column(
            children: <Widget>[
              const AppKeyValueList(
                rows: <AppKeyValueRow>[
                  AppKeyValueRow(
                    label: 'Rent · 38 000 ₸ × 2 nights',
                    value: '76 000 ₸',
                  ),
                  AppKeyValueRow(
                    label: 'Refundable deposit',
                    value: '50 000 ₸',
                  ),
                  AppKeyValueRow(
                    label: 'Check-in / check-out',
                    value: '18:30 / 12:00',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppFileRow(
                fileName: 'Identity.pdf',
                details: '2 pages · 842 KB',
                action: TextButton(
                  onPressed: () => notify('Replace file selected'),
                  child: const Text('Replace'),
                ),
                onTap: () => notify('PDF opened'),
              ),
              const SizedBox(height: 12),
              AppContractPreview(
                title: 'Rental agreement',
                details: '3 pages · Russian language',
                action: IconButton(
                  tooltip: 'Open agreement',
                  onPressed: () => notify('Agreement opened'),
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
                onTap: () => notify('Agreement preview opened'),
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Account & workspace',
          child: Column(
            children: <Widget>[
              AppAccountIdentity(
                name: 'Bexultan Nishanbek',
                details: 'Owner · Almaty',
                initials: 'BN',
                action: IconButton(
                  tooltip: 'Edit profile',
                  onPressed: () => notify('Profile editor opened'),
                  icon: const Icon(Icons.edit_outlined),
                ),
                onTap: () => notify('Account opened'),
              ),
              const SizedBox(height: 12),
              AppWorkspaceSummary(
                title: 'Workspace',
                metrics: const <AppWorkspaceMetric>[
                  AppWorkspaceMetric(label: 'apartments', value: '4'),
                  AppWorkspaceMetric(label: 'in the team', value: '2'),
                  AppWorkspaceMetric(label: 'your plan', value: 'Pro'),
                ],
                action: IconButton(
                  tooltip: 'Workspace settings',
                  onPressed: () => notify('Workspace settings opened'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
              const SizedBox(height: 12),
              AppSyncSummary(
                title: 'Calendars updated at 09:38',
                subtitle: 'Booking.com and Airbnb · 4 properties',
                action: IconButton(
                  tooltip: 'Refresh calendars',
                  onPressed: () => notify('Calendar refresh started'),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                onTap: () => notify('Sync details opened'),
              ),
              const SizedBox(height: 12),
              const AppSyncSummary(
                title: 'Airbnb needs attention',
                subtitle: 'Check the iCal link for Samal Residence.',
                isSuccessful: false,
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
