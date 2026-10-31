import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_document_tile.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_phone_country_fields.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_search_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_upload_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_value_field.dart';
import 'package:easy_booking/core/utils/phone_input_formatter.dart';

void main() {
  Future<void> pumpWidget(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: Center(child: child)),
        ),
      ),
    );
  }

  testWidgets('AppTextField uses the Paper border for focus and errors', (
    WidgetTester tester,
  ) async {
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpWidget(
      tester,
      SizedBox(
        width: 300,
        child: AppTextField(label: 'Name', focusNode: focusNode),
      ),
    );

    final Finder field = find.byType(InputDecorator);

    expect(
      field,
      paints..rrect(color: AppColors.border, strokeWidth: 1),
    );
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(
      field,
      paints..rrect(color: AppColors.text, strokeWidth: 2),
    );

    await pumpWidget(
      tester,
      const SizedBox(
        width: 300,
        child: AppTextField(label: 'Name', errorText: 'Required'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      field,
      paints..rrect(color: AppColors.error, strokeWidth: 1),
    );
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('AppTextField renders errors and reports input', (
    WidgetTester tester,
  ) async {
    String? input;
    await pumpWidget(
      tester,
      AppTextField(
        label: 'Email',
        errorText: 'Enter a valid email',
        onChanged: (String value) => input = value,
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'guest@example.com');

    expect(input, 'guest@example.com');
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('form controls accommodate enlarged text at a narrow width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SingleChildScrollView(
              child: SizedBox(
                width: 280,
                child: Column(
                  children: <Widget>[
                    const AppTextField(label: 'Name', hint: 'Enter name'),
                    AppUploadField(title: 'Add photo', onPressed: () {}),
                    AppDocumentTile(fileName: 'Identity.pdf', onAction: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppSearchField clears its controller and reports the change', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: 'Almaty',
    );
    addTearDown(controller.dispose);
    String? query;
    await pumpWidget(
      tester,
      AppSearchField(
        controller: controller,
        onChanged: (String value) => query = value,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Clear search'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(query, isEmpty);
    expect(find.bySemanticsLabel('Clear search'), findsNothing);
  });

  testWidgets('AppPhoneCountryFields stacks without overflow when narrow', (
    WidgetTester tester,
  ) async {
    int countryTaps = 0;
    await pumpWidget(
      tester,
      SizedBox(
        width: 300,
        child: AppPhoneCountryFields(
          countryValue: 'Kazakhstan',
          onCountryPressed: () => countryTaps++,
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(tester.getCenter(find.text('Kazakhstan')));
    await tester.tapAt(
      tester.getTopLeft(find.byType(AppPhoneCountryFields)) +
          const Offset(4, 4),
    );

    expect(countryTaps, 2);
  });

  testWidgets(
    'country selector uses Paper proportions and one keyboard field',
    (
      WidgetTester tester,
    ) async {
      await pumpWidget(
        tester,
        SizedBox(
          width: 400,
          child: AppPhoneCountryFields(
            countryValue: 'KZ (+7)',
            onCountryPressed: () {},
          ),
        ),
      );
      final Finder country = find
          .ancestor(
            of: find.text('KZ (+7)'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(tester.getSize(country).width, closeTo(142, 0.1));
      expect(tester.getSize(country).height, 72);
      expect(
        tester.getSize(find.byType(AppTextField)).width,
        closeTo(246, 0.1),
      );
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('KZ (+7)')).style!.fontSize,
        14,
      );
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    },
  );

  testWidgets(
    'country without callback is visually and semantically disabled',
    (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpWidget(
        tester,
        const SizedBox(
          width: 400,
          child: AppPhoneCountryFields(
            countryValue: 'Kazakhstan',
            onCountryPressed: null,
          ),
        ),
      );
      final Finder countryLabel = find.bySemanticsLabel('Country, Kazakhstan');
      expect(countryLabel, findsOneWidget);
      final SemanticsNode node = tester.getSemantics(countryLabel);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      final Iterable<Opacity> opacityWidgets = tester.widgetList<Opacity>(
        find.ancestor(
          of: find.text('Kazakhstan'),
          matching: find.byType(Opacity),
        ),
      );
      expect(
        opacityWidgets.any((Opacity widget) => widget.opacity == 0.4),
        isTrue,
      );
      handle.dispose();
    },
  );

  testWidgets('upload and document actions invoke typed callbacks', (
    WidgetTester tester,
  ) async {
    int uploadTaps = 0;
    int removeTaps = 0;
    await pumpWidget(
      tester,
      SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppUploadField(
              title: 'Upload document',
              description: 'PDF or JPG',
              onPressed: () => uploadTaps++,
            ),
            const SizedBox(height: 12),
            AppDocumentTile(
              fileName: 'a-very-long-confirmation-document-name.pdf',
              details: '1.2 MB',
              onAction: () => removeTaps++,
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Upload document'));
    await tester.tap(find.text('Remove'));

    expect(uploadTaps, 1);
    expect(removeTaps, 1);
  });

  testWidgets('AppValueField configures and reports money input', (
    WidgetTester tester,
  ) async {
    String? value;
    await pumpWidget(
      tester,
      AppValueField(
        type: AppValueFieldType.money,
        label: 'Price',
        currencySymbol: '₸',
        onChanged: (String input) => value = input,
      ),
    );

    await tester.enterText(find.byType(TextFormField), '18000');

    expect(value, '18000');
    expect(find.text('₸'), findsOneWidget);
  });

  testWidgets('AppFlowFooter adapts both actions to a narrow width', (
    WidgetTester tester,
  ) async {
    int primaryTaps = 0;
    int secondaryTaps = 0;
    await pumpWidget(
      tester,
      SizedBox(
        width: 320,
        child: AppFlowFooter(
          primaryLabel: 'Continue',
          onPrimaryPressed: () => primaryTaps++,
          secondaryLabel: 'Back',
          onSecondaryPressed: () => secondaryTaps++,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Back'));

    expect(primaryTaps, 1);
    expect(secondaryTaps, 1);
  });

  group('AppPhoneCountryFields options', () {
    Finder countryBox(String value) {
      return find
          .ancestor(of: find.text(value), matching: find.byType(DecoratedBox))
          .first;
    }

    double countryOpacity(WidgetTester tester, String value) {
      return tester
          .widget<Opacity>(
            find
                .ancestor(of: find.text(value), matching: find.byType(Opacity))
                .first,
          )
          .opacity;
    }

    testWidgets('stacked puts the country above the phone at full width', (
      WidgetTester tester,
    ) async {
      await pumpWidget(
        tester,
        const SizedBox(
          width: 400,
          child: AppPhoneCountryFields(
            layout: AppPhoneCountryLayout.stacked,
            countryValue: 'Казахстан (+7)',
            onCountryPressed: null,
          ),
        ),
      );

      final Rect country = tester.getRect(countryBox('Казахстан (+7)'));
      final Rect phone = tester.getRect(find.byType(AppTextField));
      expect(country.width, 400);
      expect(phone.width, 400);
      expect(phone.top - country.bottom, 16);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the adaptive default keeps both fields in one row', (
      WidgetTester tester,
    ) async {
      await pumpWidget(
        tester,
        const SizedBox(
          width: 400,
          child: AppPhoneCountryFields(
            countryValue: 'Казахстан (+7)',
            onCountryPressed: null,
          ),
        ),
      );

      expect(
        tester.getRect(countryBox('Казахстан (+7)')).top,
        tester.getRect(find.byType(AppTextField)).top,
      );
    });

    testWidgets('a read-only country is not tappable and not dimmed', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int countryTaps = 0;
      await pumpWidget(
        tester,
        SizedBox(
          width: 400,
          child: AppPhoneCountryFields(
            countryLabel: 'Страна / регион',
            countryValue: 'Казахстан (+7)',
            isCountryReadOnly: true,
            onCountryPressed: () => countryTaps++,
          ),
        ),
      );

      await tester.tap(find.text('Казахстан (+7)'));
      await tester.pump();

      expect(countryTaps, 0);
      expect(countryOpacity(tester, 'Казахстан (+7)'), 1);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Страна / регион, Казахстан (+7)'),
        ),
        isSemantics(
          isReadOnly: true,
          isButton: false,
          hasTapAction: false,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a read-only country is dimmed when disabled', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpWidget(
        tester,
        const SizedBox(
          width: 400,
          child: AppPhoneCountryFields(
            countryLabel: 'Страна / регион',
            countryValue: 'Казахстан (+7)',
            isCountryReadOnly: true,
            onCountryPressed: null,
            enabled: false,
          ),
        ),
      );

      expect(countryOpacity(tester, 'Казахстан (+7)'), 0.4);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Страна / регион, Казахстан (+7)'),
        ),
        isSemantics(
          isReadOnly: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      handle.dispose();
    });

    testWidgets('phoneInputFormatters are applied to the phone input', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      final List<String> changes = <String>[];
      const List<TextInputFormatter> formatters = <TextInputFormatter>[
        PhoneInputFormatter(),
      ];
      await pumpWidget(
        tester,
        SizedBox(
          width: 400,
          child: AppPhoneCountryFields(
            countryValue: 'Казахстан (+7)',
            onCountryPressed: null,
            phoneController: controller,
            phoneInputFormatters: formatters,
            onPhoneChanged: changes.add,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '7001234567');
      await tester.pump();

      expect(controller.text, '700 123 45 67');
      expect(changes.last, '700 123 45 67');
      expect(
        tester.widget<AppTextField>(find.byType(AppTextField)).inputFormatters,
        same(formatters),
      );
    });
  });

  testWidgets('AppTextField applies its inputFormatters', (
    WidgetTester tester,
  ) async {
    String? value;
    final List<TextInputFormatter> formatters = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ];
    await pumpWidget(
      tester,
      SizedBox(
        width: 400,
        child: AppTextField(
          label: 'Код',
          inputFormatters: formatters,
          onChanged: (String input) => value = input,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a1b2c3d4e5');
    await tester.pump();

    expect(value, '1234');
    expect(
      tester.widget<TextField>(find.byType(TextField)).inputFormatters,
      formatters,
    );
  });

  testWidgets('AppFlowFooter applies messageStyle to its message', (
    WidgetTester tester,
  ) async {
    const TextStyle style = TextStyle(fontSize: 12, color: AppColors.error);
    await pumpWidget(
      tester,
      SizedBox(
        width: 400,
        child: AppFlowFooter(
          message: 'Для владельцев',
          messageStyle: style,
          primaryLabel: 'Получить код',
          onPrimaryPressed: () {},
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('Для владельцев')).style, style);
  });

  testWidgets('AppFlowFooter keeps its default message style without one', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      SizedBox(
        width: 400,
        child: AppFlowFooter(
          message: 'Для владельцев',
          primaryLabel: 'Получить код',
          onPrimaryPressed: () {},
        ),
      ),
    );

    final TextStyle? style = tester
        .widget<Text>(find.text('Для владельцев'))
        .style;
    expect(style?.color, AppColors.secondaryText);
    expect(style?.fontSize, isNot(12));
  });

  group('AppSearchField options', () {
    Future<void> pumpSearch(
      WidgetTester tester, {
      String? clearSemanticLabel,
    }) {
      return pumpWidget(
        tester,
        SizedBox(
          width: 400,
          child: clearSemanticLabel == null
              ? const AppSearchField(
                  hint: 'Найти город',
                  subtitle: 'Например, Шымкент',
                )
              : AppSearchField(
                  hint: 'Найти город',
                  subtitle: 'Например, Шымкент',
                  clearSemanticLabel: clearSemanticLabel,
                ),
        ),
      );
    }

    testWidgets('uses clearSemanticLabel for the clear button', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester, clearSemanticLabel: 'Очистить поиск');

      await tester.enterText(find.byType(TextField), 'алм');
      await tester.pump();

      expect(find.bySemanticsLabel('Очистить поиск'), findsOneWidget);
      expect(find.bySemanticsLabel('Clear search'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Очистить поиск'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('hides the subtitle while there is a query', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester);
      expect(find.text('Например, Шымкент'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'алм');
      await tester.pump();
      expect(find.text('Например, Шымкент'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Clear search'));
      await tester.pump();
      expect(find.text('Например, Шымкент'), findsOneWidget);
    });

    testWidgets('keeps a 66 px height when the clear button appears', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester);
      final double emptyHeight = tester
          .getSize(find.byType(AppSearchField))
          .height;

      await tester.enterText(find.byType(TextField), 'алм');
      await tester.pump();

      expect(emptyHeight, 66);
      expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
      expect(tester.getSize(find.byType(AppSearchField)).height, emptyHeight);
      expect(tester.takeException(), isNull);
    });
  });
}
