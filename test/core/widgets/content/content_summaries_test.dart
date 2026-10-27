import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/widgets/content/app_account_identity.dart';
import 'package:easy_booking/core/widgets/content/app_guest_booking_summary.dart';
import 'package:easy_booking/core/widgets/content/app_key_value_list.dart';
import 'package:easy_booking/core/widgets/content/app_sync_summary.dart';
import 'package:easy_booking/core/widgets/content/app_workspace_summary.dart';

void main() {
  testWidgets('summary widgets expose fallback identity and supplied values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestHarness(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              AppGuestBookingSummary(
                guestName: 'Aruzhan Saparova',
                stayDetails: '28–30 October · 2 guests',
                trailingText: '14:00',
              ),
              AppAccountIdentity(
                name: 'Bexultan Akhmetov',
                details: 'Owner · Almaty',
              ),
              AppWorkspaceSummary(
                title: 'Workspace',
                metrics: <AppWorkspaceMetric>[
                  AppWorkspaceMetric(label: 'Apartments', value: '12'),
                  AppWorkspaceMetric(label: 'Team', value: '4'),
                  AppWorkspaceMetric(label: 'Plan', value: 'Pro'),
                ],
              ),
              AppSyncSummary(
                title: 'Everything is up to date',
                subtitle: 'Last synchronized just now',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('AS'), findsOneWidget);
    expect(find.text('BA'), findsOneWidget);
    expect(find.text('Apartments'), findsOneWidget);
    expect(find.text('Everything is up to date'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppKeyValueList stacks long values at very narrow width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestHarness(
        width: 220,
        child: AppKeyValueList(
          rows: <AppKeyValueRow>[
            AppKeyValueRow(
              label: 'Cancellation policy',
              value: 'Free cancellation until 14:00 on 27 October',
            ),
            AppKeyValueRow(
              label: 'Guests',
              value: '2 adults',
              valueWidget: Icon(Icons.people_outline),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Cancellation policy'), findsOneWidget);
    expect(
      find.text('Free cancellation until 14:00 on 27 October'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
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
