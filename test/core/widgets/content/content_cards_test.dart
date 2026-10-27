import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/widgets/content/app_arrival_card.dart';
import 'package:easy_booking/core/widgets/content/app_listing_card.dart';
import 'package:easy_booking/core/widgets/content/app_property_row.dart';
import 'package:easy_booking/core/widgets/content/app_selected_property_card.dart';

void main() {
  testWidgets('AppListingCard adapts its image and long copy to narrow width', (
    WidgetTester tester,
  ) async {
    bool wasTapped = false;

    await tester.pumpWidget(
      _TestHarness(
        width: 240,
        child: AppListingCard(
          title: 'Esentai City apartment with an intentionally very long title',
          subtitle:
              'A long address that must remain inside the available card width',
          details: '2 guests · 1 bedroom · arrival today',
          price: '₸ 48 000',
          unitLabel: 'per night',
          badgeLabel: 'Arrival today',
          image: const ColoredBox(color: Colors.blue),
          onTap: () => wasTapped = true,
        ),
      ),
    );

    expect(find.text('Arrival today'), findsOneWidget);
    expect(find.textContaining('₸ 48 000', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(AppListingCard));
    await tester.pump();

    expect(wasTapped, isTrue);
  });

  testWidgets(
    'property content widgets render optional details at narrow width',
    (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const _TestHarness(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                AppPropertyRow(
                  title: 'Esentai City · apartment 84',
                  subtitle: 'Al-Farabi Avenue 77/8',
                  price: '₸ 48 000',
                  unitLabel: 'night',
                  status: 'Available',
                  image: ColoredBox(color: Colors.orange),
                ),
                AppArrivalCard(
                  time: '14:00',
                  propertyName: 'Esentai City · apartment 84',
                  stayDetails: 'Aruzhan S. · 2 nights',
                  status: 'Confirmed',
                ),
                AppSelectedPropertyCard(
                  title: 'Esentai City · apartment 84',
                  stayDetails: '28–30 October · 2 nights',
                  guestName: 'Aruzhan S.',
                  image: ColoredBox(color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.textContaining('Aruzhan S.'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
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
