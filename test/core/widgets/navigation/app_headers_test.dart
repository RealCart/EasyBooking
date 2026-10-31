import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_header_back_button.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_progress_app_bar.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_system_status_style.dart';

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

  group('AppHeaderBackButton', () {
    testWidgets('without onPressed is disabled, dimmed and announced so', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const _TestApp(
          child: AppHeaderBackButton(semanticLabel: 'Назад', onPressed: null),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Назад')),
        isSemantics(
          label: 'Назад',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(AppHeaderBackButton),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.4,
      );
      handle.dispose();
    });

    testWidgets('with onPressed is enabled and invokes it', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int presses = 0;
      await tester.pumpWidget(
        _TestApp(
          child: AppHeaderBackButton(
            semanticLabel: 'Назад',
            onPressed: () => presses++,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Назад')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      await tester.tap(find.byType(AppHeaderBackButton));
      expect(presses, 1);
      handle.dispose();
    });
  });

  group('AppDetailHeader back options', () {
    testWidgets('onBack null hides the back button and centres the title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const _TestApp(appBar: AppDetailHeader(title: 'Вход', onBack: null)),
      );

      expect(find.byType(AppHeaderBackButton), findsNothing);
      expect(
        tester.getCenter(find.text('Вход')).dx,
        tester.getCenter(find.byType(AppDetailHeader)).dx,
      );
    });

    // Known lib bug: the padded Material tap target makes the back button
    // 48 px wide while the empty trailing slot is 44 px, so the title is
    // 2 px right of centre when a back button is shown without an action.
    testWidgets('the title is also centred with a back button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          appBar: AppDetailHeader(title: 'Вход', onBack: () {}),
        ),
      );

      expect(
        tester.getCenter(find.text('Вход')).dx,
        tester.getCenter(find.byType(AppDetailHeader)).dx,
      );
    });

    testWidgets('isBackEnabled false shows a disabled back button', (
      WidgetTester tester,
    ) async {
      int backCount = 0;
      await tester.pumpWidget(
        _TestApp(
          appBar: AppDetailHeader(
            title: 'Ваш аккаунт',
            onBack: () => backCount++,
            isBackEnabled: false,
          ),
        ),
      );

      expect(find.byType(AppHeaderBackButton), findsOneWidget);
      expect(
        tester
            .widget<AppHeaderBackButton>(find.byType(AppHeaderBackButton))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(AppHeaderBackButton), warnIfMissed: false);
      expect(backCount, 0);
    });
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
