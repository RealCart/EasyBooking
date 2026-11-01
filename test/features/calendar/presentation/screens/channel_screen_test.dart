import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_confirmation_dialog.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/disconnect_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/sync_channel_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/channel_bloc/channel_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/screens/channel_screen.dart';

import '../../../../helpers/fake_channels_repository.dart';

/// The 430 × 932 phone of the design.
void _usePhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1290, 2796)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps [ChannelScreen] for [channelId] at `/channel`, over a `/` page it
/// can pop back to, under its own [BlocProvider] over [repository].
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeChannelsRepository repository, {
  String channelId = 'airbnb',
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  final GoRouter router = GoRouter(
    initialLocation: '/channel',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('channels')),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.channel.name,
            path: 'channel',
            builder: (_, _) => BlocProvider<ChannelBloc>(
              create: (_) => ChannelBloc(
                getChannel: GetChannelUsecase(repository),
                syncChannel: SyncChannelUsecase(repository),
                disconnectChannel: DisconnectChannelUsecase(repository),
              )..add(ChannelRequested(channelId)),
              child: ChannelScreen(channelId: channelId),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

String _location(GoRouter router) => router.state.uri.toString();

/// The filled «Синхронизировать сейчас»; its label turns into a spinner
/// while it runs.
final Finder _syncButton = find.byType(FilledButton);
final Finder _disconnectButton = find.widgetWithText(
  OutlinedButton,
  'Отключить',
);

/// Whether the ⋯ menu button can be pressed.
bool _isMoreEnabled(WidgetTester tester) {
  return tester
          .widget<AppIconButton>(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is AppIconButton && widget.semanticLabel == 'Ещё',
            ),
          )
          .onPressed !=
      null;
}

bool _isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<ButtonStyleButton>(button).onPressed != null;
}

Finder _inSnackBar(String text) {
  return find.descendant(of: find.byType(SnackBar), matching: find.text(text));
}

/// Records what is copied to the clipboard.
List<String> _captureClipboard(WidgetTester tester) {
  final List<String> copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add(
          (call.arguments as Map<Object?, Object?>)['text']! as String,
        );
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  group('ChannelScreen', () {
    testWidgets('shows a skeleton and no actions while loading', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..holdChannel = true;

      await _pump(tester, repository, settle: false);

      expect(repository.channelRequests, <String>['airbnb']);
      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Синхронизировать сейчас'), findsNothing);
      expect(find.bySemanticsLabel('Ещё'), findsNothing);
    });

    testWidgets('a failing channel shows its first failed calendar', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeChannelsRepository());

      expect(find.text('Airbnb'), findsWidgets);
      expect(find.text('Ошибка · 2 объекта'), findsOneWidget);
      expect(find.text('Календарь Mega Towers · 126'), findsOneWidget);
      expect(find.text('airbnb.com/ical/p2.ics'), findsOneWidget);
      expect(find.text('Проверить'), findsOneWidget);
      expect(find.text('Работает'), findsOneWidget);
      expect(_isEnabled(tester, _syncButton), isTrue);
      expect(_isEnabled(tester, _disconnectButton), isTrue);
    });

    testWidgets('the last sync and the next check are relative to the '
        'source time', (WidgetTester tester) async {
      await _pump(tester, FakeChannelsRepository());

      // Synced at 09:38 and next checked at 09:53; the source answered at
      // 09:45 the same day.
      expect(
        find.text('Последняя успешная синхронизация сегодня в 09:38.'),
        findsOneWidget,
      );
      expect(
        find.text('Следующая автоматическая проверка через 8 минут.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping a property row shows its calendar', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeChannelsRepository());

      await tester.ensureVisible(find.text('Esentai City · 84'));
      await tester.tap(find.text('Esentai City · 84'));
      await tester.pumpAndSettle();

      expect(find.text('Календарь Esentai City · 84'), findsOneWidget);
      expect(find.text('airbnb.com/ical/p1.ics'), findsOneWidget);
      expect(find.text('airbnb.com/ical/p2.ics'), findsNothing);
    });

    testWidgets('«Скопировать ссылку» copies the export link', (
      WidgetTester tester,
    ) async {
      final List<String> copied = _captureClipboard(tester);
      await _pump(tester, FakeChannelsRepository());

      await tester.ensureVisible(find.text('Скопировать ссылку'));
      await tester.tap(find.text('Скопировать ссылку'));
      await tester.pumpAndSettle();

      expect(copied, <String>['easybooking.kz/ical/airbnb-p2.ics']);
      expect(_inSnackBar('Ссылка скопирована'), findsOneWidget);
    });

    testWidgets('a sync updates the channel and says so', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository();
      await _pump(tester, repository);

      await tester.tap(_syncButton);
      await tester.pumpAndSettle();

      expect(repository.syncRequests, <String>['airbnb']);
      expect(_inSnackBar('Календари обновлены'), findsOneWidget);
      expect(find.text('Подключён · 2 объекта'), findsOneWidget);
      expect(find.text('Проверить'), findsNothing);
    });

    testWidgets('a failed sync shows its message', (WidgetTester tester) async {
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..syncResult = const Left<Failure, ChannelEntity>(ConnectionFailure());
      await _pump(tester, repository);

      await tester.tap(_syncButton);
      await tester.pumpAndSettle();

      expect(_inSnackBar('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('Ошибка · 2 объекта'), findsOneWidget);
    });

    testWidgets('while a sync runs, every action is disabled', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..holdSync = true;
      await _pump(tester, repository);

      await tester.tap(_syncButton);
      await tester.pump();

      expect(_isEnabled(tester, _syncButton), isFalse);
      expect(_isEnabled(tester, _disconnectButton), isFalse);
      expect(_isMoreEnabled(tester), isFalse);
      await tester.tap(_disconnectButton, warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AppConfirmationDialog), findsNothing);
      expect(repository.syncRequests, hasLength(1));

      repository.heldSyncs.single.complete(
        Right<Failure, ChannelEntity>(testAirbnbChannel(isRepaired: true)),
      );
      await tester.pumpAndSettle();

      expect(_isEnabled(tester, _syncButton), isTrue);
      expect(_isEnabled(tester, _disconnectButton), isTrue);
      expect(_isMoreEnabled(tester), isTrue);
    });

    testWidgets('«Отключить» asks first; cancel keeps the channel', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_disconnectButton);
      await tester.pumpAndSettle();

      expect(find.text('Отключить Airbnb?'), findsOneWidget);

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsNothing);
      expect(repository.disconnectRequests, isEmpty);
      expect(_location(router), '/channel');
    });

    testWidgets('a confirmed disconnect leaves the screen', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_disconnectButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmationDialog),
          matching: find.text('Отключить'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.disconnectRequests, <String>['airbnb']);
      expect(_location(router), '/');
      expect(find.text('channels'), findsOneWidget);
    });

    testWidgets('while a disconnect runs, every action is disabled', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..holdDisconnect = true;
      await _pump(tester, repository);

      await tester.tap(_disconnectButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmationDialog),
          matching: find.text('Отключить'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_isEnabled(tester, _syncButton), isFalse);
      // The outlined button only keeps its width, disabled, under a spinner.
      expect(_isEnabled(tester, _disconnectButton), isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.heldDisconnects.single.complete(
        const Left<Failure, void>(TimeoutFailure()),
      );
      await tester.pumpAndSettle();

      expect(
        _inSnackBar('Сервер долго не отвечает. Попробуйте ещё раз'),
        findsOneWidget,
      );
      expect(_isEnabled(tester, _disconnectButton), isTrue);
    });

    testWidgets('a disconnected channel has no footer', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeChannelsRepository(), channelId: 'avito');

      expect(find.text('Канал отключён'), findsOneWidget);
      expect(find.text('Синхронизировать сейчас'), findsNothing);
    });

    testWidgets('an unknown channel is not found, without a retry', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeChannelsRepository(), channelId: 'missing');

      expect(find.text('Канал не найден'), findsOneWidget);
      expect(find.text('Повторить'), findsNothing);
      expect(find.text('Синхронизировать сейчас'), findsNothing);
    });

    testWidgets('another failure offers a retry', (WidgetTester tester) async {
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..channelResult = const Left<Failure, ChannelEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить канал'), findsOneWidget);

      repository.channelResult = null;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.channelRequests, <String>['airbnb', 'airbnb']);
      expect(find.text('Ошибка · 2 объекта'), findsOneWidget);
    });
  });
}
