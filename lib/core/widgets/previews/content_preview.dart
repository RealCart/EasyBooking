import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/widgets/actions/app_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';

import 'package:easy_booking/core/widgets/content/app_account_identity.dart';
import 'package:easy_booking/core/widgets/content/app_arrival_card.dart';
import 'package:easy_booking/core/widgets/content/app_calendar_event_row.dart';
import 'package:easy_booking/core/widgets/content/app_channel_connector.dart';
import 'package:easy_booking/core/widgets/content/app_contract_preview.dart';
import 'package:easy_booking/core/widgets/content/app_file_row.dart';
import 'package:easy_booking/core/widgets/content/app_guest_booking_summary.dart';
import 'package:easy_booking/core/widgets/content/app_key_value_list.dart';
import 'package:easy_booking/core/widgets/content/app_large_listing_card.dart';
import 'package:easy_booking/core/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/widgets/content/app_property_row.dart';
import 'package:easy_booking/core/widgets/content/app_sync_summary.dart';
import 'package:easy_booking/core/widgets/content/app_task_row.dart';
import 'package:easy_booking/core/widgets/content/app_workspace_summary.dart';
import 'package:easy_booking/core/widgets/previews/app_preview_gallery.dart';

@Preview(
  name: 'Content & Lists · narrow, large text',
  group: 'EasyBooking Core Widgets',
  size: Size(320, 900),
  textScaleFactor: 1.5,
  wrapper: appWidgetPreviewWrapper,
)
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

    return AppPreviewGallery(
      title: 'Content & Lists',
      description:
          'Tap cards, rows, and trailing actions to verify interaction states.',
      children: <Widget>[
        AppPreviewSection(
          title: 'Listings & properties',
          child: Column(
            children: <Widget>[
              AppLargeListingCard(
                title: 'Esentai City · apartment 84',
                imageUrl: AppAssets.images.propertyLivingRoomWarm,
                subtitle: 'Al-Farabi 77/8 · 2 rooms',
                details: '2 channels · updated at 09:38',
                price: '42 500 ₸',
                unitLabel: 'per night',
                badgeLabel: 'Arrival today',
                onTap: () => notify('Listing opened'),
              ),
              const SizedBox(height: 16),
              AppPropertyRow(
                title: 'Mega Towers · 126',
                imageUrl: AppAssets.images.propertyLivingRoomBlue,
                subtitle: 'Kablukova 264 · 1 room',
                status: 'Available until 25 October',
                price: '32 000 ₸',
                unitLabel: 'per night',
                onTap: () => notify('Property opened'),
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Arrivals & operations',
          child: Column(
            children: <Widget>[
              Row(
                spacing: 18.0,
                children: [
                  Expanded(
                    child: AppArrivalCard(
                      time: '14:00',
                      propertyName: 'Esentai City · 84',
                      stayDetails: 'Aizhan · 3 nights',
                      status: 'Ready for arrival',
                      onTap: () => notify('Arrival opened'),
                    ),
                  ),
                  Expanded(
                    child: AppArrivalCard(
                      time: '14:00',
                      propertyName: 'Esentai City · 84',
                      stayDetails: 'Aizhan · 3 nights',
                      status: 'Ready for arrival',
                      onTap: () => notify('Arrival opened'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTaskRow(
                title: 'Daniyar’s agreement',
                subtitle: 'Samal · not signed yet',
                leading: SvgPicture.asset(
                  AppAssets.icons.documentText,
                  width: 22,
                  height: 22,
                ),
                action: AppTextButton.accent(
                  label: 'Remind',
                  labelColor: AppColors.text,
                  onPressed: () => notify('Reminder sent'),
                ),
                onTap: () => notify('Task opened'),
              ),
              AppCalendarEventRow(
                time: '14:00',
                title: 'Arrival · Aizhan',
                propertyName: 'Esentai City · apartment 84',
                subtitle: '3 nights · agreement signed',
                imageUrl: AppAssets.images.propertyLivingRoomWarm,
                onTap: () => notify('Calendar event opened'),
              ),
              AppGuestBookingSummary(
                guestName: 'Aizhan Sarsenova',
                stayDetails: '22–25 Oct · 3 nights · 2 guests',
                trailingText: '14:00',
                onTap: () => notify('Guest booking opened'),
              ),
              AppChannelConnector(
                title: 'Booking.com',
                onTap: () => notify('Channel details opened'),
              ),
              AppProfileMenuItem(
                title: 'Guests & agreements',
                subtitle: 'Documents, signatures, templates',
                leading: SvgPicture.asset(
                  AppAssets.icons.users,
                  width: 24,
                  height: 24,
                ),
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
                onTap: () => notify('PDF opened'),
                onReplcae: () {},
              ),
              const SizedBox(height: 12),
              AppContractPreview(
                title: 'Rental agreement',
                details: '3 pages · Russian language',
                onTap: () => notify('Agreement preview opened'),
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Account & workspace',
          child: Column(
            children: <Widget>[
              const AppAccountIdentity(
                name: 'Bexultan Nishanbek',
                details: 'Owner · Almaty',
                avatarUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSORJgezgSVfKPU9hI13wkD0Sfci6HzUbCAagmVyBvbudVidHqWurj2scrO&s=10",
              ),
              const SizedBox(height: 12),
              const AppWorkspaceSummary(
                title: 'Workspace surface',
                metrics: <AppWorkspaceMetric>[
                  AppWorkspaceMetric(label: 'apartments', value: '4'),
                  AppWorkspaceMetric(label: 'in the team', value: '2'),
                  AppWorkspaceMetric(label: 'your plan', value: 'Pro'),
                ],
              ),
              const SizedBox(height: 12),
              AppSyncSummary(
                title: 'Calendars updated at 09:38',
                subtitle: 'Booking.com and Airbnb · 4 properties',
                action: Semantics(
                  button: true,
                  label: 'Refresh calendars',
                  child: IconButton(
                    onPressed: () => notify('Calendar refresh started'),
                    icon: SvgPicture.asset(
                      AppAssets.icons.refresh,
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
                onTap: () => notify('Sync details opened'),
              ),
              const SizedBox(height: 12),
              AppSyncSummary(
                title: 'Airbnb needs attention',
                subtitle: 'Check the iCal link for Samal Residence.',
                isSuccessful: false,
                leading: SvgPicture.asset(
                  AppAssets.icons.statusWarning,
                  width: 18,
                  height: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
