import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/widgets/content/app_calendar_event_row.dart';
import 'package:easy_booking/core/widgets/content/app_channel_connector.dart';
import 'package:easy_booking/core/widgets/content/app_contract_preview.dart';
import 'package:easy_booking/core/widgets/content/app_file_row.dart';
import 'package:easy_booking/core/widgets/content/app_profile_menu_item.dart';
import 'package:easy_booking/core/widgets/content/app_task_row.dart';

void main() {
  testWidgets('content rows render long copy without horizontal overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestHarness(
        width: 260,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              AppTaskRow(
                title: 'Prepare the apartment for a late evening arrival',
                subtitle: 'Esentai City · apartment 84',
                leading: Icon(Icons.check_circle_outline),
              ),
              AppCalendarEventRow(
                time: '14:00',
                title: 'Guest arrival and key handover',
                propertyName: 'Esentai City · apartment 84',
                subtitle: 'Aruzhan S. · 2 guests',
              ),
              AppChannelConnector(
                title: 'Booking.com',
                subtitle: 'Reservations are synchronized automatically',
                leading: Icon(Icons.link),
              ),
              AppProfileMenuItem(
                title: 'Notification preferences',
                subtitle: 'Email, push notifications, and reminders',
                leading: Icon(Icons.notifications_outlined),
              ),
              AppFileRow(
                fileName: 'signed-rental-contract-october-2026.pdf',
                details: 'PDF · 1.8 MB',
              ),
              AppContractPreview(
                title: 'Short-term rental agreement',
                details: 'Signed 28 October 2026 · PDF · 4 pages',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Booking.com'), findsOneWidget);
    expect(find.text('PDF · 1.8 MB'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('row and child actions expose their callbacks', (
    WidgetTester tester,
  ) async {
    bool rowTapped = false;
    bool actionTapped = false;

    await tester.pumpWidget(
      _TestHarness(
        width: 360,
        child: AppChannelConnector(
          title: 'Airbnb',
          subtitle: 'Not connected',
          onTap: () => rowTapped = true,
          action: TextButton(
            onPressed: () => actionTapped = true,
            child: const Text('Connect'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Airbnb'));
    await tester.pump();
    expect(rowTapped, isTrue);

    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(actionTapped, isTrue);
  });
}

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }
}
