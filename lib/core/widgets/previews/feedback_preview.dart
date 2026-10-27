import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:easy_booking/core/widgets/actions/app_button.dart';
import 'package:easy_booking/core/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/widgets/feedback/app_conflict_card.dart';
import 'package:easy_booking/core/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/widgets/feedback/app_signature_progress.dart';
import 'package:easy_booking/core/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/widgets/feedback/app_snackbar.dart';
import 'package:easy_booking/core/widgets/previews/app_preview_gallery.dart';

@Preview(
  name: 'Feedback & status',
  group: 'EasyBooking Core Widgets',
  size: Size(430, 900),
  wrapper: appWidgetPreviewWrapper,
)
Widget feedbackPreview() => const _FeedbackPreviewGallery();

class _FeedbackPreviewGallery extends StatelessWidget {
  const _FeedbackPreviewGallery();

  @override
  Widget build(BuildContext context) {
    return AppPreviewGallery(
      title: 'Feedback & status',
      description:
          'Tap actions to exercise messages, resolution controls, snackbars, '
          'and confirmation dialogs.',
      children: <Widget>[
        AppPreviewSection(
          title: 'Callout family',
          description: 'Success, information, warning, and error tones.',
          child: Column(
            children: <Widget>[
              AppCallout(
                title: 'Синхронизация завершена',
                message: 'Все календари обновлены в 09:38.',
                tone: AppFeedbackTone.success,
                actionLabel: 'Открыть',
                onAction: () => showPreviewMessage(
                  context,
                  'Opened the synchronization summary',
                ),
              ),
              const SizedBox(height: 12),
              const AppCallout(
                title: 'Данные распознаны',
                message: 'Сверьте имя и номер с удостоверением.',
                tone: AppFeedbackTone.info,
              ),
              const SizedBox(height: 12),
              AppCallout(
                title: 'Ждём подпись гостя',
                message: 'Ссылка отправлена Данияру в SMS.',
                tone: AppFeedbackTone.warning,
                actionLabel: 'Напомнить',
                onAction: () => showPreviewMessage(
                  context,
                  'Signature reminder sent',
                ),
              ),
              const SizedBox(height: 12),
              AppCallout(
                title: 'Не удалось обновить Airbnb',
                message: 'Проверьте ссылку iCal и повторите.',
                tone: AppFeedbackTone.error,
                actionLabel: 'Повторить',
                onAction: () => showPreviewMessage(context, 'Retry started'),
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Empty search',
          child: AppEmptyState(
            title: 'Ничего не найдено',
            message: 'Измените адрес или сбросьте фильтры доступности.',
            actionLabel: 'Сбросить фильтры',
            onAction: () => showPreviewMessage(context, 'Filters cleared'),
          ),
        ),
        const AppPreviewSection(
          title: 'Loading skeleton',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppSkeleton(height: 18, width: 180),
              SizedBox(height: 10),
              AppSkeleton(height: 14),
              SizedBox(height: 8),
              AppSkeleton(height: 14, width: 240),
              SizedBox(height: 16),
              AppSkeleton(height: 96),
            ],
          ),
        ),
        const AppPreviewSection(
          title: 'Signature progress',
          child: AppSignatureProgress(
            documentTitle: 'Договор аренды · №1042',
            steps: <AppSignatureStep>[
              AppSignatureStep(
                title: 'Черновик создан',
                subtitle: 'Сегодня, 09:12',
                status: AppSignatureStepStatus.draft,
              ),
              AppSignatureStep(
                title: 'Отправлен гостю',
                subtitle: 'Сегодня, 09:18',
                status: AppSignatureStepStatus.sent,
              ),
              AppSignatureStep(
                title: 'Подписан',
                subtitle: 'Сегодня, 09:31',
                status: AppSignatureStepStatus.signed,
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Overbooking conflict',
          child: AppConflictCard(
            title: 'Конфликт бронирований',
            message: 'Брони Booking.com и Airbnb пересекаются 22–24 октября.',
            primaryActionLabel: 'Разрешить',
            secondaryActionLabel: 'Посмотреть брони',
            onPrimaryAction: () => showPreviewMessage(
              context,
              'Conflict resolution opened',
            ),
            onSecondaryAction: () => showPreviewMessage(
              context,
              'Overlapping bookings opened',
            ),
          ),
        ),
        AppPreviewSection(
          title: 'Snackbar',
          description: 'Tap to display the production snackbar component.',
          child: AppButton(
            label: 'Показать snackbar',
            isExpanded: true,
            onPressed: () => _showSnackbar(context),
          ),
        ),
        AppPreviewSection(
          title: 'Confirmation dialog',
          description: 'Tap to open and test both dialog actions.',
          child: AppButton(
            label: 'Открыть диалог',
            isExpanded: true,
            variant: AppButtonVariant.secondary,
            onPressed: () => _showConfirmationDialog(context),
          ),
        ),
      ],
    );
  }

  void _showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackbar(
        message: 'Изменения сохранены',
        actionLabel: 'Отменить',
        onAction: () => showPreviewMessage(context, 'Changes reverted'),
      ).toSnackBar(),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppConfirmationDialog(
          title: 'Удалить бронирование?',
          message: 'Это действие нельзя отменить.',
          cancelLabel: 'Отмена',
          confirmLabel: 'Удалить',
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            showPreviewMessage(context, 'Booking deleted in preview');
          },
        );
      },
    );
  }
}
