import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/widgets/navigation/app_progress_app_bar.dart';
import 'package:easy_booking/core/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/widgets/navigation/app_system_status_style.dart';

void main() {
  testWidgets('AppRootHeader renders title, subtitle, and action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppRootHeader(
          title: 'Сегодня',
          subtitle: 'Среда, 28 октября',
          action: IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ),
      ),
    );

    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('Среда, 28 октября'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
  });

  testWidgets('AppDetailHeader invokes back action and shows trailing action', (
    WidgetTester tester,
  ) async {
    int backCount = 0;

    await tester.pumpWidget(
      _TestApp(
        appBar: AppDetailHeader(
          title: 'Esentai City',
          onBack: () => backCount += 1,
          action: const Text('Изменить'),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pump();

    expect(backCount, 1);
    expect(find.text('Esentai City'), findsOneWidget);
    expect(find.text('Изменить'), findsOneWidget);
  });

  testWidgets('AppProgressAppBar renders progress and invokes back', (
    WidgetTester tester,
  ) async {
    int backCount = 0;

    await tester.pumpWidget(
      _TestApp(
        appBar: AppProgressAppBar(
          title: 'Новая бронь',
          currentStep: 2,
          totalSteps: 3,
          onBack: () => backCount += 1,
        ),
      ),
    );

    expect(find.text('2 из 3'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pump();
    expect(backCount, 1);
  });

  testWidgets('AppSystemStatusRegion exposes configured overlay style', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const AppSystemStatusRegion(
        style: AppSystemStatusStyle.light,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      ),
    );

    final AnnotatedRegion<SystemUiOverlayStyle> region = tester.widget(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    expect(region.value, AppSystemStatusStyle.light);
  });
}

final class _TestApp extends StatelessWidget {
  const _TestApp({this.child = const SizedBox(), this.appBar});

  final Widget child;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(appBar: appBar, body: child),
    );
  }
}
