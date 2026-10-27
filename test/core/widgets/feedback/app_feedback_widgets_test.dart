import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/widgets/feedback/app_conflict_card.dart';
import 'package:easy_booking/core/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/widgets/feedback/app_signature_progress.dart';
import 'package:easy_booking/core/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/widgets/feedback/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('feedback widgets', () {
    testWidgets('callout adapts to a narrow layout and invokes its action', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        buildSubject(
          SizedBox(
            width: 280,
            child: AppCallout(
              title: 'Payment received',
              message: 'The booking balance is now settled.',
              tone: AppFeedbackTone.success,
              actionLabel: 'View',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Payment received'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('View'));
      expect(tapped, isTrue);
    });

    testWidgets('empty state displays and invokes its action', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        buildSubject(
          AppEmptyState(
            title: 'No stays found',
            message: 'Try changing the current filters.',
            actionLabel: 'Clear filters',
            onAction: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Clear filters'));
      expect(tapped, isTrue);
    });

    testWidgets('signature progress renders every document state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          const AppSignatureProgress(
            documentTitle: 'Rental agreement',
            steps: <AppSignatureStep>[
              AppSignatureStep(
                title: 'Draft created',
                subtitle: 'Today, 09:00',
                status: AppSignatureStepStatus.draft,
              ),
              AppSignatureStep(
                title: 'Sent to guest',
                subtitle: 'Today, 09:05',
                status: AppSignatureStepStatus.sent,
              ),
              AppSignatureStep(
                title: 'Signed',
                subtitle: 'Today, 09:20',
                status: AppSignatureStepStatus.signed,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Rental agreement'), findsOneWidget);
      expect(find.text('Draft created'), findsOneWidget);
      expect(find.text('Sent to guest'), findsOneWidget);
      expect(find.text('Signed'), findsOneWidget);
    });

    testWidgets('conflict card invokes both resolution actions', (
      WidgetTester tester,
    ) async {
      var primaryTapped = false;
      var secondaryTapped = false;

      await tester.pumpWidget(
        buildSubject(
          SizedBox(
            width: 280,
            child: AppConflictCard(
              title: 'Overbooking detected',
              message: 'Two reservations overlap for this property.',
              primaryActionLabel: 'Resolve',
              secondaryActionLabel: 'Review',
              onPrimaryAction: () => primaryTapped = true,
              onSecondaryAction: () => secondaryTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Review'));
      await tester.tap(find.text('Resolve'));
      expect(primaryTapped, isTrue);
      expect(secondaryTapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('snackbar exposes its message and action', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      final AppSnackbar content = AppSnackbar(
        message: 'Changes saved',
        actionLabel: 'Undo',
        onAction: () => tapped = true,
      );

      await tester.pumpWidget(buildSubject(content.toSnackBar().content));
      await tester.tap(find.text('Undo'));

      expect(find.text('Changes saved'), findsOneWidget);
      expect(tapped, isTrue);
    });

    testWidgets('confirmation dialog invokes cancel and confirm callbacks', (
      WidgetTester tester,
    ) async {
      var cancelled = false;
      var confirmed = false;

      await tester.pumpWidget(
        buildSubject(
          AppConfirmationDialog(
            title: 'Delete booking?',
            message: 'This action cannot be undone.',
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete',
            onCancel: () => cancelled = true,
            onConfirm: () => confirmed = true,
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.tap(find.text('Delete'));
      expect(cancelled, isTrue);
      expect(confirmed, isTrue);
    });

    testWidgets('skeleton has a loading semantics label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildSubject(const AppSkeleton(height: 20)));

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });
  });
}
