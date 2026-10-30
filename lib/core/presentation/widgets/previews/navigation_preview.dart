import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_bottom_navigation.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_progress_app_bar.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_resend_timer_row.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_section_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_sticky_action_bar.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_system_status_style.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_tabs.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_week_selector.dart';
import 'package:easy_booking/core/presentation/widgets/previews/app_preview_gallery.dart';

@Preview(
  name: 'Navigation & Structure',
  group: 'EasyBooking Core Widgets',
  size: Size(430, 900),
  wrapper: appWidgetPreviewWrapper,
)
@Preview(
  name: 'Navigation & Structure · Narrow / Large Text',
  group: 'EasyBooking Core Widgets',
  size: Size(320, 800),
  textScaleFactor: 1.5,
  wrapper: appWidgetPreviewWrapper,
)
Widget navigationWidgetsPreview() => const NavigationPreviewGallery();

class NavigationPreviewGallery extends StatefulWidget {
  const NavigationPreviewGallery({super.key});

  @override
  State<NavigationPreviewGallery> createState() {
    return _NavigationPreviewGalleryState();
  }
}

class _NavigationPreviewGalleryState extends State<NavigationPreviewGallery> {
  static final List<AppWeekDay> _weekDays = <AppWeekDay>[
    AppWeekDay(date: DateTime(2026, 10, 19), weekdayLabel: 'Mon'),
    AppWeekDay(date: DateTime(2026, 10, 20), weekdayLabel: 'Tue'),
    AppWeekDay(date: DateTime(2026, 10, 21), weekdayLabel: 'Wed'),
    AppWeekDay(date: DateTime(2026, 10, 22), weekdayLabel: 'Thu'),
    AppWeekDay(date: DateTime(2026, 10, 23), weekdayLabel: 'Fri'),
    AppWeekDay(date: DateTime(2026, 10, 24), weekdayLabel: 'Sat'),
    AppWeekDay(date: DateTime(2026, 10, 25), weekdayLabel: 'Sun'),
  ];

  static final List<AppBottomNavigationItem> _navigationItems =
      <AppBottomNavigationItem>[
        AppBottomNavigationItem.destination(
          label: 'Today',
          iconPath: AppAssets.icons.home,
        ),
        AppBottomNavigationItem.destination(
          label: 'Calendar',
          iconPath: AppAssets.icons.calendar,
        ),
        AppBottomNavigationItem.add(
          label: 'Add property',
          iconPath: AppAssets.icons.plus,
        ),
        AppBottomNavigationItem.destination(
          label: 'Properties',
          iconPath: AppAssets.icons.building,
        ),
        AppBottomNavigationItem.destination(
          label: 'Profile',
          iconPath: AppAssets.icons.user,
        ),
      ];

  int _selectedTab = 0;
  int _selectedScope = 0;
  int _selectedDestination = 0;
  DateTime _selectedDate = DateTime(2026, 10, 22);

  @override
  Widget build(BuildContext context) {
    return AppSystemStatusRegion(
      child: AppPreviewGallery(
        title: 'Navigation & Structure',
        description:
            'Tap tabs, filters, dates, navigation destinations, and actions.',
        children: <Widget>[
          AppPreviewSection(
            title: 'System status region',
            description:
                'Applies the native dark system overlay style to its child.',
            child: Container(
              height: 44,
              color: AppColors.surface,
              alignment: Alignment.center,
              child: const Text('Native status bar styling'),
            ),
          ),
          AppPreviewSection(
            title: 'Root header',
            child: AppRootHeader(
              title: 'Today',
              subtitle: 'Thursday, 22 October',
              action: Semantics(
                button: true,
                label: 'Notifications',
                child: SizedBox.square(
                  dimension: 40,
                  child: IconButton(
                    onPressed: () => _show('Notifications tapped'),
                    icon: SvgPicture.asset(
                      AppAssets.icons.notification,
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AppPreviewSection(
            title: 'Compact detail header',
            child: AppDetailHeader(
              title: 'Your property',
              onBack: () => _show('Back tapped'),
              action: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.text,
                  overlayColor: Colors.transparent,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onPressed: () => _show('Edit tapped'),
                child: const Text('Edit'),
              ),
            ),
          ),
          AppPreviewSection(
            title: 'Progress app bar',
            child: AppProgressAppBar(
              title: 'Add apartment',
              currentStep: 2,
              totalSteps: 3,
              onBack: () => _show('Back from flow'),
              stepSeparator: ' of ',
            ),
          ),
          AppPreviewSection(
            title: 'Property tabs',
            child: AppTabs(
              labels: const <String>['Overview', 'Bookings', 'Settings'],
              selectedIndex: _selectedTab,
              onSelected: (int index) {
                setState(() => _selectedTab = index);
              },
            ),
          ),
          AppPreviewSection(
            title: 'Scope filters',
            child: AppScopeFilter(
              labels: const <String>[
                'All properties',
                'Favorites',
                'Available',
              ],
              selectedIndex: _selectedScope,
              padding: EdgeInsets.zero,
              onSelected: (int index) {
                setState(() => _selectedScope = index);
              },
            ),
          ),
          AppPreviewSection(
            title: 'Week selector',
            child: AppWeekSelector(
              days: _weekDays,
              selectedDate: _selectedDate,
              onSelected: (AppWeekDay day) {
                setState(() => _selectedDate = day.date);
              },
            ),
          ),
          AppPreviewSection(
            title: 'Section heading',
            child: AppSectionHeader(
              title: 'Before arrival',
              subtitle: '2 tasks are still open',
              actionLabel: 'All tasks',
              onAction: () => _show('All tasks tapped'),
            ),
          ),
          AppPreviewSection(
            title: 'Resend and timer rows',
            child: Column(
              children: <Widget>[
                AppResendTimerRow(
                  prompt: 'Did not receive the code?',
                  actionLabel: 'Resend',
                  remaining: const Duration(seconds: 28),
                  onResend: () => _show('Code resent'),
                ),
                AppResendTimerRow(
                  prompt: 'The timer has finished',
                  actionLabel: 'Resend code',
                  onResend: () => _show('Code resent'),
                ),
              ],
            ),
          ),
          AppPreviewSection(
            title: 'Bottom navigation',
            description:
                'The center add action is independent from destination state.',
            child: AppBottomNavigation(
              items: _navigationItems,
              selectedIndex: _selectedDestination,
              onDestinationSelected: (int index) {
                setState(() => _selectedDestination = index);
              },
              onAdd: () => _show('Add property tapped'),
            ),
          ),
          AppPreviewSection(
            title: 'Sticky rate action',
            child: AppStickyActionBar.rate(
              rate: '42 500 ₸',
              rateCaption: 'Base price per night',
              primaryLabel: 'Calendar',
              onPrimaryPressed: () => _show('Calendar tapped'),
            ),
          ),
          AppPreviewSection(
            title: 'Flow action',
            child: AppStickyActionBar.flow(
              supportingText:
                  'Signature status will appear in the booking card',
              secondaryLabel: 'Save draft',
              onSecondaryPressed: () => _show('Draft saved'),
              primaryLabel: 'Send to sign',
              onPrimaryPressed: () => _show('Sent to sign'),
            ),
          ),
        ],
      ),
    );
  }

  void _show(String message) {
    showPreviewMessage(context, message);
  }
}
