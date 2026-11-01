import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/data/sources/local/guests_mock_local.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';

import '../../../../../helpers/fake_guests_repository.dart';

GuestsMockLocalImpl _localAt(DateTime now) {
  return GuestsMockLocalImpl(now: () => now);
}

Future<GuestDirectoryEntity> _directory(
  String query, {
  DateTime? now,
}) async {
  final Either<Failure, GuestDirectoryEntity> result = await _localAt(
    now ?? guestsTestNow,
  ).loadDirectory(query);
  return switch (result) {
    Right<Failure, GuestDirectoryEntity>(:final GuestDirectoryEntity value) =>
      value,
    Left<Failure, GuestDirectoryEntity>(:final Failure value) =>
      throw TestFailure(
        'Expected a directory, got $value',
      ),
  };
}

Future<GuestEntity> _guest(String id, {DateTime? now}) async {
  final Either<Failure, GuestEntity> result = await _localAt(
    now ?? guestsTestNow,
  ).loadGuest(id);
  return switch (result) {
    Right<Failure, GuestEntity>(:final GuestEntity value) => value,
    Left<Failure, GuestEntity>(:final Failure value) => throw TestFailure(
      'Expected a guest, got $value',
    ),
  };
}

List<String> _guestIds(GuestDirectoryEntity directory) => <String>[
  for (final GuestSummaryEntity guest in directory.guests) guest.id,
];

List<String> _contractIds(GuestDirectoryEntity directory) => <String>[
  for (final GuestContractEntity contract in directory.contracts) contract.id,
];

final Matcher _notFound = isA<Left<Failure, Object?>>().having(
  (Left<Failure, Object?> left) => left.value,
  'value',
  isA<ServerFailure>().having(
    (ServerFailure failure) => failure.statusCode,
    'statusCode',
    404,
  ),
);

void main() {
  group('GuestsMockLocalImpl.loadDirectory', () {
    test(
      'an empty query returns the four recent guests and every contract',
      () async {
        final GuestDirectoryEntity directory = await _directory('');

        expect(directory.query, '');
        expect(_guestIds(directory), <String>[
          GuestsMockLocalImpl.aizhanId,
          GuestsMockLocalImpl.daniyarId,
          GuestsMockLocalImpl.armanId,
          GuestsMockLocalImpl.mariaId,
        ]);
        expect(directory.totalGuestCount, 12);
        expect(directory.contracts, hasLength(10));
        expect(directory.receivedAt, guestsTestNow);
      },
    );

    test('a blank query is the default view with an empty query', () async {
      final GuestDirectoryEntity directory = await _directory('   ');

      expect(directory.query, '');
      expect(directory.guests, hasLength(4));
      expect(directory.contracts, hasLength(10));
    });

    test(
      'contracts awaiting a signature come first, then the newest',
      () async {
        final GuestDirectoryEntity directory = await _directory('');

        expect(_contractIds(directory), <String>[
          'eb-1052',
          'eb-1050',
          'eb-1049',
          'eb-1047',
          'eb-1048',
          'eb-1040',
          'eb-1033',
          'eb-1031',
          'eb-1022',
          'eb-1015',
        ]);
        expect(
          directory.contracts.first.status.isAwaitingSignature,
          isTrue,
        );
        expect(
          directory.contracts
              .skip(1)
              .every((GuestContractEntity c) => !c.status.isAwaitingSignature),
          isTrue,
        );
      },
    );

    test(
      'a name matches case-insensitively and reports the trimmed query',
      () async {
        final GuestDirectoryEntity directory = await _directory('  данияр ');

        expect(directory.query, 'данияр');
        expect(_guestIds(directory), <String>[GuestsMockLocalImpl.daniyarId]);
        expect(_contractIds(directory), <String>['eb-1052']);
        expect(directory.totalGuestCount, 12);
      },
    );

    test('phone digits match regardless of spaces', () async {
      final GuestDirectoryEntity directory = await _directory('245 18');

      expect(_guestIds(directory), <String>[GuestsMockLocalImpl.aizhanId]);
    });

    test('a property name matches every guest who stayed there', () async {
      final GuestDirectoryEntity directory = await _directory('Samal');

      expect(_guestIds(directory), <String>[
        GuestsMockLocalImpl.daniyarId,
        GuestsMockLocalImpl.aselId,
        GuestsMockLocalImpl.ruslanId,
      ]);
      expect(_contractIds(directory), <String>['eb-1052', 'eb-1049']);
    });

    test(
      'a property with its unit matches only the guests of that unit',
      () async {
        final GuestDirectoryEntity directory = await _directory(
          'Samal Residence 7',
        );

        expect(_guestIds(directory), <String>[GuestsMockLocalImpl.aselId]);
        expect(_contractIds(directory), <String>['eb-1049']);
      },
    );

    test('a contract number matches only that contract', () async {
      final GuestDirectoryEntity directory = await _directory('EB-1048');

      expect(directory.guests, isEmpty);
      expect(_contractIds(directory), <String>['eb-1048']);
    });

    test('a query that matches nothing returns empty lists', () async {
      final GuestDirectoryEntity directory = await _directory('zzz');

      expect(directory.guests, isEmpty);
      expect(directory.contracts, isEmpty);
      expect(directory.totalGuestCount, 12);
    });

    test('the summary holds the newest stay and contract status', () async {
      final GuestDirectoryEntity directory = await _directory('');
      final GuestSummaryEntity aizhan = directory.guests[0];
      final GuestSummaryEntity arman = directory.guests[2];

      expect(aizhan.fullName, 'Айжан Сарсенова');
      expect(aizhan.phone, '+7 701 245 18 92');
      expect(aizhan.latestStay?.bookingId, 'booking-1042');
      expect(aizhan.latestContractStatus, GuestContractStatus.signed);
      expect(arman.latestStay?.bookingId, 'booking-1039');
      expect(arman.latestContractStatus, isNull);
    });

    test('the published lists are unmodifiable', () async {
      final GuestDirectoryEntity directory = await _directory('');

      expect(
        () => directory.guests.add(directory.guests.first),
        throwsUnsupportedError,
      );
      expect(
        () => directory.contracts.add(directory.contracts.first),
        throwsUnsupportedError,
      );
    });
  });

  group('GuestsMockLocalImpl.loadGuest', () {
    test('returns the guest with stays and contracts', () async {
      final GuestEntity aizhan = await _guest(GuestsMockLocalImpl.aizhanId);

      expect(aizhan.fullName, 'Айжан Сарсенова');
      expect(aizhan.document, isNotNull);
      expect(
        aizhan.stays.map((GuestStayEntity stay) => stay.bookingId),
        <String>['booking-1042', 'booking-0912'],
      );
      expect(aizhan.contracts.single.id, 'eb-1048');
      expect(aizhan.contracts.single.guestId, GuestsMockLocalImpl.aizhanId);
      expect(aizhan.contracts.single.guestName, 'Айжан Сарсенова');
      expect(aizhan.contracts.single.bookingId, 'booking-1042');
    });

    test('stays are placed around the injected clock', () async {
      final GuestEntity aizhan = await _guest(GuestsMockLocalImpl.aizhanId);

      expect(aizhan.stays.first.checkIn, DateTime(2026, 10, 22, 14));
      expect(aizhan.stays.first.checkOut, DateTime(2026, 10, 25, 12));
      expect(aizhan.stays.first.nights, 3);
    });

    test(
      'a stay before check-in is upcoming and after check-out is past',
      () async {
        final GuestEntity aizhan = await _guest(GuestsMockLocalImpl.aizhanId);

        expect(aizhan.stays[0].status, GuestStayStatus.upcoming);
        expect(aizhan.stays[1].status, GuestStayStatus.past);
      },
    );

    test('a stay is current from check-in up to check-out', () async {
      final GuestEntity atCheckIn = await _guest(
        GuestsMockLocalImpl.aizhanId,
        now: DateTime(2026, 10, 22, 14),
      );
      final GuestEntity arman = await _guest(GuestsMockLocalImpl.armanId);

      expect(atCheckIn.stays.first.status, GuestStayStatus.current);
      // Арман checks out today at 12:00; at 09:41 he is still there.
      expect(arman.stays.single.status, GuestStayStatus.current);
    });

    test('a stay is past from the moment of check-out', () async {
      final GuestEntity arman = await _guest(
        GuestsMockLocalImpl.armanId,
        now: DateTime(2026, 10, 22, 12),
      );

      expect(arman.stays.single.status, GuestStayStatus.past);
    });

    test('an unknown id is a 404 failure', () async {
      expect(await _localAt(guestsTestNow).loadGuest('missing'), _notFound);
    });
  });

  group('GuestsMockLocalImpl.createContract', () {
    test('Данияр gets the existing draft', () async {
      expect(
        await _localAt(
          guestsTestNow,
        ).createContract(GuestsMockLocalImpl.daniyarId),
        const Right<Failure, String>(
          GuestsMockLocalImpl.daniyarDraftContractId,
        ),
      );
      expect(GuestsMockLocalImpl.daniyarDraftContractId, 'samal-daniyar');
    });

    test(
      'other guests get a draft named after them, the same every time',
      () async {
        final GuestsMockLocalImpl local = _localAt(guestsTestNow);

        expect(
          await local.createContract(GuestsMockLocalImpl.aizhanId),
          const Right<Failure, String>('draft-aizhan'),
        );
        expect(
          await local.createContract(GuestsMockLocalImpl.aizhanId),
          const Right<Failure, String>('draft-aizhan'),
        );
      },
    );

    test('an unknown guest is a 404 failure', () async {
      expect(
        await _localAt(guestsTestNow).createContract('missing'),
        _notFound,
      );
    });
  });
}
