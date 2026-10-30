import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_primary_button.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_secondary_button.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_conflict_card.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_signature_progress.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_snackbar.dart';
import 'package:easy_booking/core/presentation/widgets/previews/app_preview_gallery.dart';

@Preview(
  name: 'Feedback & status · narrow, large text',
  group: 'EasyBooking Core Widgets',
  size: Size(320, 900),
  textScaleFactor: 1.5,
  wrapper: appWidgetPreviewWrapper,
)
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
        const AppPreviewSection(
          title: 'Callout family',
          description: 'Success, information, warning, and error tones.',
          child: Column(
            children: <Widget>[
              AppCallout(
                title: 'Синхронизация завершена',
                message: 'Все календари обновлены в 09:38.',
                tone: AppFeedbackTone.success,
              ),
              SizedBox(height: 12),
              AppCallout(
                title: 'Данные распознаны',
                message: 'Сверьте имя и номер с удостоверением.',
                tone: AppFeedbackTone.info,
              ),
              SizedBox(height: 12),
              AppCallout(
                title: 'Ждём подпись гостя',
                message: 'Ссылка отправлена Данияру в SMS.',
                tone: AppFeedbackTone.warning,
              ),
              SizedBox(height: 12),
              AppCallout(
                title: 'Не удалось обновить Airbnb',
                message: 'Проверьте ссылку iCal и повторите.',
                tone: AppFeedbackTone.error,
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
        AppPreviewSection(
          title: 'Loading skeleton',
          child: Column(
            children: <Widget>[
              for (int index = 0; index < 3; index++) ...<Widget>[
                const Row(
                  children: <Widget>[
                    AppSkeleton(
                      height: 72,
                      width: 72,
                      borderRadius: 12,
                      color: AppColors.skeletonImage,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppSkeleton(
                            height: 12,
                            width: 176,
                            color: AppColors.skeletonLine,
                          ),
                          SizedBox(height: 8),
                          AppSkeleton(height: 10, width: 220),
                          SizedBox(height: 8),
                          AppSkeleton(height: 10, width: 108),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index != 2) const SizedBox(height: 12),
              ],
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
                statusLabel: 'Черновик',
              ),
              AppSignatureStep(
                title: 'Отправлен гостю',
                subtitle: 'Сегодня, 09:18',
                status: AppSignatureStepStatus.sent,
                statusLabel: 'Отправлен',
              ),
              AppSignatureStep(
                title: 'Подписан',
                subtitle: 'Сегодня, 09:31',
                status: AppSignatureStepStatus.signed,
                statusLabel: 'Подписан',
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
          child: AppPrimaryButton(
            label: 'Показать snackbar',
            onPressed: () => _showSnackbar(context),
          ),
        ),
        AppPreviewSection(
          title: 'Confirmation dialog',
          description: 'Tap to open and test both dialog actions.',
          child: AppSecondaryButton(
            label: 'Открыть диалог',
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
