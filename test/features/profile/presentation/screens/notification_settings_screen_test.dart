import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/presentation/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/notification_settings_bloc/notification_settings_bloc.dart';
import 'package:easy_booking/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_toggle_row.dart';

import '../../../../helpers/fake_profile_repository.dart';
import 'profile_detail_harness.dart';

typedef _H = ProfileDetailHarness;

/// Pushes [NotificationSettingsScreen] under its own
/// [NotificationSettingsBloc], started as `wrappedRoute` does.
Future<void> _pump(
  WidgetTester tester,
  FakeProfileRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    () => BlocProvider<NotificationSettingsBloc>(
      create: (_) => NotificationSettingsBloc(
        getNotificationSettings: GetNotificationSettingsUsecase(repository),
        updateNotificationSettings: UpdateNotificationSettingsUsecase(
          repository,
        ),
      )..add(const NotificationSettingsRequested()),
      child: const NotificationSettingsScreen(),
    ),
    settle: settle,
  );
}

final Finder _saveButton = _H.filledButton('Сохранить настройки');

Finder _row(String title) => find.widgetWithText(ProfileToggleRow, title);

bool _isOn(WidgetTester tester, String title) {
  return tester.widget<ProfileToggleRow>(_row(title)).value;
}

bool _isChipSelected(WidgetTester tester, String label) {
  return tester
      .widget<AppChoiceChip>(find.widgetWithText(AppChoiceChip, label))
      .isSelected;
}

void main() {
  group('NotificationSettingsScreen states', () {
    testWidgets('shows a skeleton and a disabled save while loading', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdNotificationSettings = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(_H.isEnabled(tester, _saveButton), isFalse);

      repository.heldNotificationSettings.single.complete(
        const Right<Failure, NotificationSettingsEntity>(
          testNotificationSettings,
        ),
      );
      await tester.pumpAndSettle();

      expect(_H.isEnabled(tester, _saveButton), isTrue);
    });

    testWidgets('shows the saved toggles and channels', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      expect(find.text('ОПЕРАЦИИ'), findsOneWidget);
      expect(_isOn(tester, 'Новая бронь'), isTrue);
      expect(_isOn(tester, 'Заезд и выезд'), isTrue);
      expect(_isOn(tester, 'Изменение цены'), isFalse);
      await tester.ensureVisible(find.text('Push'));
      expect(_isChipSelected(tester, 'Push'), isTrue);
      expect(_isChipSelected(tester, 'Email'), isFalse);
      expect(_isChipSelected(tester, 'SMS важное'), isFalse);
    });

    testWidgets('a failed first load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..notificationSettingsResult =
            const Left<Failure, NotificationSettingsEntity>(
              ConnectionFailure(),
            );
      await _pump(tester, repository);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Не удалось загрузить настройки'), findsOneWidget);

      repository.notificationSettingsResult =
          const Right<Failure, NotificationSettingsEntity>(
            testNotificationSettings,
          );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(_row('Новая бронь'), findsOneWidget);
    });
  });

  group('NotificationSettingsScreen save', () {
    testWidgets('saves every toggle and channel and confirms', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);

      await _H.tapVisible(tester, _row('Новая бронь'));
      await _H.tapVisible(tester, _row('Изменение цены'));
      await _H.tapVisible(tester, find.text('Email'));

      expect(_isOn(tester, 'Новая бронь'), isFalse);
      expect(_isOn(tester, 'Изменение цены'), isTrue);
      expect(_isChipSelected(tester, 'Email'), isTrue);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(
        repository.updateNotificationSettingsParams,
        const <UpdateNotificationSettingsParamsEntity>[
          UpdateNotificationSettingsParamsEntity(
            enabledTopics: <NotificationTopic>{
              NotificationTopic.checkInOut,
              NotificationTopic.priceChange,
            },
            channels: <NotificationDeliveryChannel>{
              NotificationDeliveryChannel.push,
              NotificationDeliveryChannel.email,
            },
          ),
        ],
      );
      expect(_H.snackbar('Настройки сохранены'), findsOneWidget);
    });

    testWidgets('saving the unchanged settings sends the saved sets', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(
        repository.updateNotificationSettingsParams,
        const <UpdateNotificationSettingsParamsEntity>[
          UpdateNotificationSettingsParamsEntity(
            enabledTopics: <NotificationTopic>{
              NotificationTopic.newBooking,
              NotificationTopic.checkInOut,
            },
            channels: <NotificationDeliveryChannel>{
              NotificationDeliveryChannel.push,
            },
          ),
        ],
      );
    });

    testWidgets('no delivery channel is refused with a message', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);

      await _H.tapVisible(tester, find.text('Push'));
      expect(_isChipSelected(tester, 'Push'), isFalse);
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(
        _H.snackbar('Выберите хотя бы один канал доставки'),
        findsOneWidget,
      );
      expect(repository.updateNotificationSettingsParams, isEmpty);
    });

    testWidgets('toggles are disabled while saving', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdUpdateNotificationSettings = true;
      await _pump(tester, repository);

      await tester.tap(_saveButton);
      await tester.pump();

      expect(
        tester.widget<ProfileToggleRow>(_row('Новая бронь')).onChanged,
        isNull,
      );
      await tester.tap(_row('Новая бронь'));
      await tester.pump();
      expect(_isOn(tester, 'Новая бронь'), isTrue);

      repository.heldUpdateNotificationSettings.single.complete(
        const Right<Failure, NotificationSettingsEntity>(
          testNotificationSettings,
        ),
      );
      await tester.pumpAndSettle();

      expect(_H.snackbar('Настройки сохранены'), findsOneWidget);
    });

    testWidgets('a failed save shows the failure', (WidgetTester tester) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..updateNotificationSettingsResult =
            const Left<Failure, NotificationSettingsEntity>(
              ConnectionFailure(),
            );
      await _pump(tester, repository);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(_H.snackbar('Нет подключения к интернету'), findsOneWidget);
    });
  });
}
