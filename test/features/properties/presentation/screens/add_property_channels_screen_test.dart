import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/presentation/screens/add_property_channels_screen.dart';
import 'package:easy_booking/features/properties/presentation/widgets/add_property_channel_row.dart';

import '../../../../helpers/add_property_step_harness.dart';
import '../../../../helpers/fake_property_management_repository.dart';

typedef _H = AddPropertyStepHarness;

const String _continue = 'Продолжить';
const String _stepLocation = '/add-property/channels';

/// Step 2 above step 1, with step 3 above it.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakePropertyManagementRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    initialLocation: _stepLocation,
    settle: settle,
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.addProperty.name,
        path: AppRoutes.addProperty.path,
        builder: (_, GoRouterState state) => _H.destination(state),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.addPropertyChannels.name,
            path: AppRoutes.addPropertyChannels.path,
            builder: (_, _) =>
                _H.provide(repository, const AddPropertyChannelsScreen()),
            routes: <RouteBase>[
              GoRoute(
                name: AppRoutes.addPropertyTerms.name,
                path: AppRoutes.addPropertyTerms.path,
                builder: (_, GoRouterState state) => _H.destination(state),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Finder _row(BookingChannel channel) {
  return find.widgetWithText(AddPropertyChannelRow, channel.title);
}

bool _isConnected(WidgetTester tester, BookingChannel channel) {
  return tester.widget<AddPropertyChannelRow>(_row(channel)).isConnected;
}

FakePropertyManagementRepository _filled() {
  return FakePropertyManagementRepository()
    ..draftResult = const Right<Failure, AddPropertyDraftEntity>(
      testFilledDraft,
    );
}

void main() {
  group('AddPropertyChannelsScreen', () {
    testWidgets(
      'shows a skeleton and a disabled button until the draft loads',
      (
        WidgetTester tester,
      ) async {
        final FakePropertyManagementRepository repository = _filled()
          ..holdDraft = true;

        await _pump(tester, repository, settle: false);

        expect(find.byType(AppSkeleton), findsWidgets);
        expect(find.byType(AddPropertyChannelRow), findsNothing);
        expect(_H.isEnabled(tester, _continue), isFalse);

        repository.heldDraft.single.complete(
          const Right<Failure, AddPropertyDraftEntity>(testFilledDraft),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddPropertyChannelRow), findsNWidgets(3));
        expect(_H.isEnabled(tester, _continue), isTrue);
      },
    );

    testWidgets('a failed draft load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..draftResult = const Left<Failure, AddPropertyDraftEntity>(
              StorageFailure(),
            );

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить черновик'), findsOneWidget);
      expect(_H.isEnabled(tester, _continue), isFalse);

      repository.draftResult = const Right<Failure, AddPropertyDraftEntity>(
        testFilledDraft,
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.byType(AddPropertyChannelRow), findsNWidgets(3));
    });

    testWidgets('shows the draft and its connected channels', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _filled());

      expect(find.text('Al-Farabi Residence · 19'), findsOneWidget);
      expect(find.text('Аль-Фараби, 21'), findsOneWidget);
      expect(_isConnected(tester, BookingChannel.airbnb), isTrue);
      expect(_isConnected(tester, BookingChannel.bookingCom), isFalse);
      expect(_isConnected(tester, BookingChannel.krisha), isFalse);
      expect(find.text('Подключено'), findsOneWidget);
      expect(find.text('Подключить'), findsOneWidget);
      expect(find.text('Настроить'), findsOneWidget);
    });

    testWidgets('a row tap connects the channel; another tap disconnects it', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _filled());

      await _H.tapVisible(tester, _row(BookingChannel.bookingCom));
      expect(_isConnected(tester, BookingChannel.bookingCom), isTrue);
      expect(find.text('Подключено'), findsNWidgets(2));

      await _H.tapVisible(tester, _row(BookingChannel.bookingCom));
      expect(_isConnected(tester, BookingChannel.bookingCom), isFalse);
      expect(find.text('Подключить'), findsOneWidget);
    });

    testWidgets(
      'submits the channels in the order connected and opens step 3',
      (
        WidgetTester tester,
      ) async {
        final FakePropertyManagementRepository repository = _filled();
        final GoRouter router = await _pump(tester, repository);

        await _H.tapVisible(tester, _row(BookingChannel.krisha));
        await _H.tapVisible(tester, _row(BookingChannel.bookingCom));
        await tester.tap(_H.button(_continue));
        await tester.pumpAndSettle();

        expect(repository.savedChannels.single, const <BookingChannel>[
          BookingChannel.airbnb,
          BookingChannel.krisha,
          BookingChannel.bookingCom,
        ]);
        expect(_H.location(router), '$_stepLocation/terms');
      },
    );

    testWidgets('no channel at all is allowed', (WidgetTester tester) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_H.button(_continue));
      await tester.pumpAndSettle();

      expect(repository.savedChannels.single, isEmpty);
      expect(_H.location(router), '$_stepLocation/terms');
    });

    testWidgets('a failed save shows a snackbar and stays', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository = _filled()
        ..saveChannelsResult = const Left<Failure, void>(TimeoutFailure());
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_H.button(_continue));
      await tester.pumpAndSettle();

      expect(find.text(const TimeoutFailure().userMessage), findsOneWidget);
      expect(_H.location(router), _stepLocation);
    });

    testWidgets('back returns to step 1', (WidgetTester tester) async {
      final GoRouter router = await _pump(tester, _filled());

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(_H.location(router), AppRoutes.addProperty.path);
    });
  });
}
