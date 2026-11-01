import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_callout.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_team_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/invite_team_member_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/remove_team_member_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/team_bloc/team_bloc.dart';
import 'package:easy_booking/features/profile/presentation/screens/team_screen.dart';

import '../../../../helpers/fake_profile_repository.dart';
import 'profile_detail_harness.dart';

typedef _H = ProfileDetailHarness;

final TeamMemberEntity _invited = TeamMemberEntity(
  id: 'member-invited-1',
  firstName: 'Дана',
  lastName: 'Ахметова',
  phone: '+77005551234',
  role: ProfileRole.checkInOperator,
  propertyCount: 0,
  hasAllProperties: false,
  isCurrentUser: false,
  status: TeamMemberStatus.invited,
  inviteExpiresAt: DateTime(2026, 10, 25, 14),
);

/// Pushes [TeamScreen] under its own [TeamBloc], started as `wrappedRoute`
/// does.
Future<void> _pump(
  WidgetTester tester,
  FakeProfileRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    () => BlocProvider<TeamBloc>(
      create: (_) => TeamBloc(
        getTeam: GetTeamUsecase(repository),
        inviteTeamMember: InviteTeamMemberUsecase(repository),
        removeTeamMember: RemoveTeamMemberUsecase(repository),
      )..add(const TeamRequested()),
      child: const TeamScreen(),
    ),
    settle: settle,
  );
}

final Finder _inviteIcon = find.byWidgetPredicate(
  (Widget widget) =>
      widget is AppIconButton && widget.semanticLabel == 'Пригласить участника',
);

Finder _inSheet(Finder finder) {
  return find.descendant(of: find.byType(BottomSheet), matching: finder);
}

Future<void> _openInvite(WidgetTester tester) async {
  await tester.tap(_inviteIcon);
  await tester.pumpAndSettle();
}

Future<void> _fillInvite(
  WidgetTester tester, {
  String firstName = ' Дана ',
  String lastName = 'Ахметова',
  String phone = '7005551234',
}) async {
  await _H.type(tester, 'Имя', firstName);
  await _H.type(tester, 'Фамилия', lastName);
  await _H.type(tester, 'Телефон', phone);
}

Future<void> _sendInvite(WidgetTester tester) async {
  await _H.tapVisible(tester, _inSheet(find.text('Отправить приглашение')));
}

void main() {
  group('TeamScreen states', () {
    testWidgets('shows a skeleton and no invite while loading', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdTeam = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(tester.widget<AppIconButton>(_inviteIcon).onPressed, isNull);

      repository.heldTeam.single.complete(
        const Right<Failure, List<TeamMemberEntity>>(testTeam),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
      expect(tester.widget<AppIconButton>(_inviteIcon).onPressed, isNotNull);
    });

    testWidgets('shows the member count, the members, and their access', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      expect(find.text('3 участника'), findsOneWidget);
      expect(find.text('Бексултан Нишанбек'), findsOneWidget);
      expect(find.text('Все объекты · полный доступ'), findsOneWidget);
      expect(find.text('Алия Жумабек'), findsOneWidget);
      expect(find.text('4 объекта · брони и гости'), findsOneWidget);
      expect(find.text('Айгерим Касым'), findsOneWidget);
      expect(find.text('2 объекта · календарь задач'), findsOneWidget);
    });

    testWidgets('a failed first load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..teamResult = const Left<Failure, List<TeamMemberEntity>>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Не удалось загрузить команду'), findsOneWidget);

      repository.teamResult = const Right<Failure, List<TeamMemberEntity>>(
        testTeam,
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('3 участника'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the members and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);
      repository.teamResult = const Left<Failure, List<TeamMemberEntity>>(
        ConnectionFailure(),
      );

      await tester.fling(find.text('3 участника'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(repository.teamCount, 2);
      expect(_H.snackbar('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('3 участника'), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
    });
  });

  group('TeamScreen invite', () {
    testWidgets('«+» opens the invite form', (WidgetTester tester) async {
      await _pump(tester, FakeProfileRepository());

      await _openInvite(tester);

      expect(_inSheet(find.text('Пригласить участника')), findsOneWidget);
      expect(_inSheet(_H.field('Имя')), findsOneWidget);
      expect(_inSheet(_H.field('Фамилия')), findsOneWidget);
      expect(_inSheet(_H.field('Телефон')), findsOneWidget);
      for (final String role in <String>[
        'Менеджер',
        'Оператор заселения',
        'Уборка',
      ]) {
        expect(_inSheet(find.text(role)), findsOneWidget);
      }
      expect(_inSheet(find.text('Отправить приглашение')), findsOneWidget);
    });

    testWidgets('an invalid form shows the messages and sends nothing', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);
      await _openInvite(tester);

      await _sendInvite(tester);

      expect(_inSheet(find.text('Заполните поле')), findsNWidgets(2));
      expect(_inSheet(find.text('Проверьте номер телефона')), findsOneWidget);
      expect(repository.inviteParams, isEmpty);
    });

    testWidgets('a valid form invites, closes the form, and confirms', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..inviteResult = Right<Failure, List<TeamMemberEntity>>(
          <TeamMemberEntity>[...testTeam, _invited],
        );
      await _pump(tester, repository);
      await _openInvite(tester);

      await _fillInvite(tester);
      await _H.tapVisible(tester, _inSheet(find.text('Оператор заселения')));
      await _sendInvite(tester);

      expect(
        repository.inviteParams,
        const <InviteTeamMemberParamsEntity>[
          InviteTeamMemberParamsEntity(
            firstName: 'Дана',
            lastName: 'Ахметова',
            phone: '+77005551234',
            role: ProfileRole.checkInOperator,
          ),
        ],
      );
      expect(find.byType(BottomSheet), findsNothing);
      expect(_H.snackbar('Приглашение отправлено'), findsOneWidget);
      expect(find.text('4 участника'), findsOneWidget);
      expect(find.text('Дана Ахметова'), findsOneWidget);
      expect(find.text('Приглашение до 25 октября'), findsOneWidget);
    });

    testWidgets('the form opens ready for input after a sent invitation', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..inviteResult = Right<Failure, List<TeamMemberEntity>>(
          <TeamMemberEntity>[...testTeam, _invited],
        );
      await _pump(tester, repository);
      await _openInvite(tester);
      await _fillInvite(tester);
      await _sendInvite(tester);
      expect(find.byType(BottomSheet), findsNothing);

      // Fixed frames instead of settling: a stuck spinner never settles.
      await tester.tap(_inviteIcon);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        tester.widget<TextField>(_inSheet(_H.field('Имя'))).enabled,
        isTrue,
      );
      expect(
        _inSheet(find.text('Отправить приглашение')),
        findsOneWidget,
        reason: 'the send button should show its label, not a spinner',
      );
    });

    testWidgets('a reopened form does not show the previous failure', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..inviteResult = const Left<Failure, List<TeamMemberEntity>>(
          ValidationFailure(code: ProfileErrorCodes.teamLimitReached),
        );
      await _pump(tester, repository);
      await _openInvite(tester);
      await _fillInvite(tester);
      await _sendInvite(tester);
      expect(_inSheet(find.byType(AppCallout)), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await tester.pumpAndSettle();
      await _openInvite(tester);

      expect(_inSheet(find.byType(AppCallout)), findsNothing);
    });

    testWidgets('an invite failure shows an error callout in the form', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..inviteResult = const Left<Failure, List<TeamMemberEntity>>(
          ValidationFailure(code: ProfileErrorCodes.teamLimitReached),
        );
      await _pump(tester, repository);
      await _openInvite(tester);

      await _fillInvite(tester);
      await _sendInvite(tester);

      expect(_inSheet(find.byType(AppCallout)), findsOneWidget);
      expect(_inSheet(find.text('Не удалось пригласить')), findsOneWidget);
      expect(
        _inSheet(
          find.text(
            'В команде нет свободных мест. Смените тариф, чтобы пригласить ещё',
          ),
        ),
        findsOneWidget,
      );
      expect(_H.snackbar('Приглашение отправлено'), findsNothing);
    });

    testWidgets('a phone already in the team shows under the phone', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..inviteResult = const Left<Failure, List<TeamMemberEntity>>(
          ValidationFailure(
            fieldErrors: <String, String>{
              ProfileFields.phone: ProfileErrorCodes.alreadyInTeam,
            },
          ),
        );
      await _pump(tester, repository);
      await _openInvite(tester);

      await _fillInvite(tester, phone: '7015550142');
      await _sendInvite(tester);

      expect(
        _inSheet(find.text('Этот номер уже есть в команде')),
        findsOneWidget,
      );
      expect(_inSheet(find.byType(AppCallout)), findsNothing);

      await _H.type(tester, 'Телефон', '7015550143');

      expect(find.text('Этот номер уже есть в команде'), findsNothing);
    });
  });

  group('TeamScreen remove', () {
    testWidgets('tapping the current user offers nothing', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      await tester.tap(find.text('Бексултан Нишанбек'));
      await tester.pumpAndSettle();

      expect(find.text('Отозвать доступ?'), findsNothing);
    });

    testWidgets('cancelling the confirmation keeps the member', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);

      await tester.tap(find.text('Алия Жумабек'));
      await tester.pumpAndSettle();
      expect(find.text('Отозвать доступ?'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(repository.removedMemberIds, isEmpty);
    });

    testWidgets('confirming revokes the access', (WidgetTester tester) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..removeResult = const Right<Failure, List<TeamMemberEntity>>(
          <TeamMemberEntity>[testOwner, testCleaner],
        );
      await _pump(tester, repository);

      await tester.tap(find.text('Алия Жумабек'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отозвать'));
      await tester.pumpAndSettle();

      expect(repository.removedMemberIds, <String>['member-aliya']);
      expect(_H.snackbar('Доступ отозван'), findsOneWidget);
      expect(find.text('Алия Жумабек'), findsNothing);
      expect(find.text('2 участника'), findsOneWidget);
    });

    testWidgets('a failed removal shows the failure', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..removeResult = const Left<Failure, List<TeamMemberEntity>>(
          ValidationFailure(code: ProfileErrorCodes.cannotRemoveOwner),
        );
      await _pump(tester, repository);

      await tester.tap(find.text('Алия Жумабек'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отозвать'));
      await tester.pumpAndSettle();

      expect(_H.snackbar('Владельца нельзя удалить'), findsOneWidget);
      expect(find.text('Алия Жумабек'), findsOneWidget);
    });
  });
}
