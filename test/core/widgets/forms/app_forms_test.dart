import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/widgets/forms/app_document_tile.dart';
import 'package:easy_booking/core/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/widgets/forms/app_phone_country_fields.dart';
import 'package:easy_booking/core/widgets/forms/app_search_field.dart';
import 'package:easy_booking/core/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/widgets/forms/app_upload_field.dart';
import 'package:easy_booking/core/widgets/forms/app_value_field.dart';

void main() {
  Future<void> pumpWidget(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: Center(child: child)),
        ),
      ),
    );
  }

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

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(query, isEmpty);
    expect(find.byTooltip('Clear search'), findsNothing);
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

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Kazakhstan'));

    expect(countryTaps, 1);
  });

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
}
