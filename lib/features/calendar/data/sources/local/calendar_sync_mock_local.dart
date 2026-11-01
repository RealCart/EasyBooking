import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/features/calendar/domain/entity/booking_source.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_connection_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/conflict_booking_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_schedule_entity.dart';

/// The channel-synced calendar until the calendar and channels APIs exist:
/// stays and closed dates per property, the channels they are imported
/// from, and the conflicts between overlapping bookings. Ids match the
/// properties, calendar, and notifications mocks.
///
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. Syncs, disconnections, and resolved
/// conflicts live in memory, so they last until the app restarts, and they
/// show everywhere: a resolved conflict removes the cancelled stay from
/// «Занятость», a synced channel repairs its failed calendars.
abstract interface class CalendarSyncMockLocal {
  /// The blocks of the week containing [date], or of the current week when
  /// it is `null`.
  Future<Either<Failure, OccupancyScheduleEntity>> loadSchedule(
    DateTime? date,
  );

  Future<Either<Failure, ChannelsOverviewEntity>> loadChannels();

  /// Imports channel [id] now and returns it after the import.
  Future<Either<Failure, ChannelEntity>> syncChannel(String id);

  Future<Either<Failure, void>> disconnectChannel(String id);

  Future<Either<Failure, CalendarConflictEntity>> loadConflict(String id);

  /// Keeps [keepBookingId] and returns the resolved conflict.
  Future<Either<Failure, CalendarConflictEntity>> resolveConflict({
    required String conflictId,
    required String keepBookingId,
  });
}

final class CalendarSyncMockLocalImpl implements CalendarSyncMockLocal {
  /// [now] supplies the current time, so stays and syncs are around today.
  CalendarSyncMockLocalImpl({required this._now});

  static const String bookingComId = 'booking-com';
  static const String airbnbId = 'airbnb';
  static const String krishaId = 'krisha';

  static const String esentaiConflictId = 'conflict-esentai-84';

  static const String _esentaiId = 'esentai-city-84';
  static const String _megaTowersId = 'mega-towers-126';
  static const String _samalId = 'samal-residence';
  static const String _highvillId = 'highvill-5';

  static const String _aizhanBookingId = 'booking-1042';
  static const String _maratBookingId = 'booking-1046';

  static const Duration _checkInterval = Duration(minutes: 15);

  /// How long before now the sample channels were last checked.
  static const Duration _lastCheckAgo = Duration(minutes: 3);

  final DateTime Function() _now;

  /// When the host synced a channel by hand, by channel id. A synced
  /// channel has its failed calendars repaired.
  final Map<String, DateTime> _syncedAtByChannel = <String, DateTime>{};

  final Set<String> _disconnectedChannelIds = <String>{};

  /// The booking kept for each resolved conflict, by conflict id.
  final Map<String, String> _keptBookingByConflict = <String, String>{};

  @override
  Future<Either<Failure, OccupancyScheduleEntity>> loadSchedule(
    DateTime? date,
  ) async {
    final DateTime now = _now();
    final DateTime today = now.dateOnly;
    final DateTime weekStart = (date ?? today).startOfWeek;
    final DateTime weekEnd = weekStart.addDays(DateTime.daysPerWeek);
    final List<ChannelEntity> channels = _channels(now);

    final List<OccupancyBlockEntity> blocks =
        <OccupancyBlockEntity>[
          for (final OccupancyBlockEntity block in _blocks(today))
            if (block.overlaps(weekStart, weekEnd)) block,
        ]..sort(
          (OccupancyBlockEntity a, OccupancyBlockEntity b) =>
              a.start.compareTo(b.start),
        );

    return Right<Failure, OccupancyScheduleEntity>(
      OccupancyScheduleEntity(
        weekStart: weekStart,
        today: today,
        blocks: List<OccupancyBlockEntity>.unmodifiable(blocks),
        syncCheckedAt: _checkedAt(channels, now),
        isSyncHealthy: channels.every(
          (ChannelEntity channel) => channel.status != ChannelStatus.failed,
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, ChannelsOverviewEntity>> loadChannels() async {
    final DateTime now = _now();
    final List<ChannelEntity> channels = _channels(now);
    return Right<Failure, ChannelsOverviewEntity>(
      ChannelsOverviewEntity(
        channels: List<ChannelEntity>.unmodifiable(channels),
        checkedAt: _checkedAt(channels, now),
        receivedAt: now,
      ),
    );
  }

  @override
  Future<Either<Failure, ChannelEntity>> syncChannel(String id) async {
    if (!_allChannelIds.contains(id)) {
      return Left<Failure, ChannelEntity>(_unknownChannel(id));
    }
    if (_disconnectedChannelIds.contains(id)) {
      return Left<Failure, ChannelEntity>(
        ServerFailure(statusCode: 409, message: 'Channel $id is disconnected'),
      );
    }
    final DateTime now = _now();
    _syncedAtByChannel[id] = now;
    return Right<Failure, ChannelEntity>(
      _channels(now).firstWhere((ChannelEntity channel) => channel.id == id),
    );
  }

  @override
  Future<Either<Failure, void>> disconnectChannel(String id) async {
    if (!_allChannelIds.contains(id)) {
      return Left<Failure, void>(_unknownChannel(id));
    }
    _disconnectedChannelIds.add(id);
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, CalendarConflictEntity>> loadConflict(
    String id,
  ) async {
    if (id != esentaiConflictId) {
      return Left<Failure, CalendarConflictEntity>(_unknownConflict(id));
    }
    return Right<Failure, CalendarConflictEntity>(_esentaiConflict(_now()));
  }

  @override
  Future<Either<Failure, CalendarConflictEntity>> resolveConflict({
    required String conflictId,
    required String keepBookingId,
  }) async {
    if (conflictId != esentaiConflictId) {
      return Left<Failure, CalendarConflictEntity>(
        _unknownConflict(conflictId),
      );
    }
    final CalendarConflictEntity conflict = _esentaiConflict(_now());
    if (conflict.isResolved) {
      return Left<Failure, CalendarConflictEntity>(
        ServerFailure(
          statusCode: 409,
          message: 'Conflict $conflictId is already resolved',
        ),
      );
    }
    final bool isPartOfConflict = conflict.bookings.any(
      (ConflictBookingEntity booking) => booking.bookingId == keepBookingId,
    );
    if (!isPartOfConflict) {
      return Left<Failure, CalendarConflictEntity>(
        ServerFailure(
          statusCode: 404,
          message: 'Booking $keepBookingId is not part of $conflictId',
        ),
      );
    }
    _keptBookingByConflict[conflictId] = keepBookingId;
    return Right<Failure, CalendarConflictEntity>(_esentaiConflict(_now()));
  }

  // Stays and closed dates.

  List<OccupancyBlockEntity> _blocks(DateTime today) {
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(
        today.year,
        today.month,
        today.day + dayOffset,
        hour,
        minute,
      );
    }

    final String? keptBookingId = _keptBookingByConflict[esentaiConflictId];
    final String? conflictId = keptBookingId == null ? esentaiConflictId : null;
    bool isCancelled(String bookingId) {
      return keptBookingId != null &&
          keptBookingId != bookingId &&
          (bookingId == _aizhanBookingId || bookingId == _maratBookingId);
    }

    // Stays of the bookings mock, with the same dates and channels. The rows
    // have no unit, so Samal Residence · 7 (booking-1037) is left out, and
    // so is booking-1047 (+3..+6): the sample has one conflict, 1042 against
    // 1046.
    return <OccupancyBlockEntity>[
      OccupancyBlockEntity(
        id: 'stay-1039',
        propertyId: _megaTowersId,
        kind: OccupancyBlockKind.booking,
        start: at(-2, 15),
        end: at(0, 12),
        bookingId: 'booking-1039',
        guestName: 'Арман',
        source: BookingSource.airbnb,
      ),
      OccupancyBlockEntity(
        id: 'stay-1034',
        propertyId: _highvillId,
        kind: OccupancyBlockKind.booking,
        start: at(-1, 15),
        end: at(2, 12),
        bookingId: 'booking-1034',
        guestName: 'Мадина',
        source: BookingSource.direct,
      ),
      if (!isCancelled(_aizhanBookingId))
        OccupancyBlockEntity(
          id: 'stay-1042',
          propertyId: _esentaiId,
          kind: OccupancyBlockKind.booking,
          start: at(0, 14),
          end: at(3, 12),
          bookingId: _aizhanBookingId,
          guestName: 'Айжан',
          source: BookingSource.airbnb,
          conflictId: conflictId,
        ),
      OccupancyBlockEntity(
        id: 'stay-1044',
        propertyId: _samalId,
        kind: OccupancyBlockKind.booking,
        start: at(0, 18, 30),
        end: at(2, 12),
        bookingId: 'booking-1044',
        guestName: 'Данияр',
        source: BookingSource.bookingCom,
      ),
      if (!isCancelled(_maratBookingId))
        OccupancyBlockEntity(
          id: 'stay-1046',
          propertyId: _esentaiId,
          kind: OccupancyBlockKind.booking,
          start: at(2, 14),
          end: at(5, 12),
          bookingId: _maratBookingId,
          guestName: 'Марат',
          source: BookingSource.direct,
          conflictId: conflictId,
        ),
      OccupancyBlockEntity(
        id: 'stay-1051',
        propertyId: _megaTowersId,
        kind: OccupancyBlockKind.booking,
        start: at(3, 15),
        end: at(5, 12),
        bookingId: 'booking-1051',
        guestName: 'Тимур',
        source: BookingSource.airbnb,
      ),
      OccupancyBlockEntity(
        id: 'maintenance-samal-12',
        propertyId: _samalId,
        kind: OccupancyBlockKind.maintenance,
        start: today.addDays(3),
        end: today.addDays(5),
      ),
    ];
  }

  // Channels.

  static const Set<String> _allChannelIds = <String>{
    bookingComId,
    airbnbId,
    krishaId,
  };

  List<ChannelEntity> _channels(DateTime now) {
    final bool isAirbnbRepaired = _syncedAtByChannel.containsKey(airbnbId);
    return <ChannelEntity>[
      _channel(
        id: bookingComId,
        name: 'Booking.com',
        now: now,
        connections: const <ChannelConnectionEntity>[
          ChannelConnectionEntity(
            propertyId: _esentaiId,
            propertyName: 'Esentai City',
            unit: '84',
            mode: ChannelSyncMode.importAndExport,
            status: ChannelConnectionStatus.working,
            importUrl:
                'admin.booking.com/hotel/hoteladmin/ical.html?t=5d2e8f1a',
            exportUrl: 'easybooking.kz/ical/esentai-84.ics',
          ),
          ChannelConnectionEntity(
            propertyId: _samalId,
            propertyName: 'Samal Residence',
            unit: '12',
            mode: ChannelSyncMode.importAndExport,
            status: ChannelConnectionStatus.working,
            importUrl:
                'admin.booking.com/hotel/hoteladmin/ical.html?t=a71c03e9',
            exportUrl: 'easybooking.kz/ical/samal-12.ics',
          ),
          ChannelConnectionEntity(
            propertyId: _highvillId,
            propertyName: 'Highvill',
            unit: '5',
            mode: ChannelSyncMode.importAndExport,
            status: ChannelConnectionStatus.working,
            importUrl:
                'admin.booking.com/hotel/hoteladmin/ical.html?t=c4b98d27',
            exportUrl: 'easybooking.kz/ical/highvill-5.ics',
          ),
        ],
      ),
      _channel(
        id: airbnbId,
        name: 'Airbnb',
        now: now,
        connections: <ChannelConnectionEntity>[
          ChannelConnectionEntity(
            propertyId: _esentaiId,
            propertyName: 'Esentai City',
            unit: '84',
            mode: ChannelSyncMode.importAndExport,
            // The broken iCal link of the «Airbnb не обновился» notification.
            status: isAirbnbRepaired
                ? ChannelConnectionStatus.working
                : ChannelConnectionStatus.failed,
            importUrl: 'airbnb.com/calendar/ical/93841275.ics',
            exportUrl: 'easybooking.kz/ical/esentai-84.ics',
          ),
          const ChannelConnectionEntity(
            propertyId: _megaTowersId,
            propertyName: 'Mega Towers',
            unit: '126',
            mode: ChannelSyncMode.importAndExport,
            status: ChannelConnectionStatus.working,
            importUrl: 'airbnb.com/calendar/ical/71265048.ics',
            exportUrl: 'easybooking.kz/ical/mega-126.ics',
          ),
          const ChannelConnectionEntity(
            propertyId: _highvillId,
            propertyName: 'Highvill',
            unit: '5',
            mode: ChannelSyncMode.importOnly,
            status: ChannelConnectionStatus.working,
            importUrl: 'airbnb.com/calendar/ical/50938172.ics',
          ),
        ],
      ),
      // Krisha has no calendar import: bookings are entered by hand.
      _channel(
        id: krishaId,
        name: 'Krisha',
        now: now,
        connections: const <ChannelConnectionEntity>[],
        isManual: true,
      ),
    ];
  }

  ChannelEntity _channel({
    required String id,
    required String name,
    required DateTime now,
    required List<ChannelConnectionEntity> connections,
    bool isManual = false,
  }) {
    if (_disconnectedChannelIds.contains(id)) {
      return ChannelEntity(
        id: id,
        name: name,
        status: ChannelStatus.disconnected,
        connections: const <ChannelConnectionEntity>[],
        checkInterval: _checkInterval,
        receivedAt: now,
      );
    }
    if (isManual) {
      return ChannelEntity(
        id: id,
        name: name,
        status: ChannelStatus.manual,
        connections: const <ChannelConnectionEntity>[],
        checkInterval: _checkInterval,
        receivedAt: now,
      );
    }
    final DateTime lastCheck = _lastCheck(id, now);
    DateTime nextCheck = lastCheck.add(_checkInterval);
    while (!nextCheck.isAfter(now)) {
      nextCheck = nextCheck.add(_checkInterval);
    }
    final bool hasFailure = connections.any(
      (ChannelConnectionEntity connection) => connection.isFailed,
    );
    return ChannelEntity(
      id: id,
      name: name,
      status: hasFailure ? ChannelStatus.failed : ChannelStatus.connected,
      connections: List<ChannelConnectionEntity>.unmodifiable(connections),
      checkInterval: _checkInterval,
      receivedAt: now,
      // The other calendars of a failed channel still imported.
      lastSyncedAt: lastCheck,
      nextCheckAt: nextCheck,
    );
  }

  DateTime _lastCheck(String channelId, DateTime now) {
    return _syncedAtByChannel[channelId] ?? now.subtract(_lastCheckAgo);
  }

  /// The latest check of any importing channel.
  DateTime _checkedAt(List<ChannelEntity> channels, DateTime now) {
    DateTime checkedAt = now.subtract(_lastCheckAgo);
    for (final ChannelEntity channel in channels) {
      final DateTime? syncedAt = channel.lastSyncedAt;
      if (syncedAt != null && syncedAt.isAfter(checkedAt)) {
        checkedAt = syncedAt;
      }
    }
    return checkedAt;
  }

  static Failure _unknownChannel(String id) {
    return ServerFailure(statusCode: 404, message: 'Unknown channel $id');
  }

  // Conflicts.

  CalendarConflictEntity _esentaiConflict(DateTime now) {
    final DateTime today = now.dateOnly;
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(
        today.year,
        today.month,
        today.day + dayOffset,
        hour,
        minute,
      );
    }

    return CalendarConflictEntity(
      id: esentaiConflictId,
      propertyId: _esentaiId,
      propertyName: 'Esentai City',
      unit: '84',
      overlapStart: today.addDays(2),
      overlapEnd: today.addDays(3),
      bookings: List<ConflictBookingEntity>.unmodifiable(
        <ConflictBookingEntity>[
          ConflictBookingEntity(
            bookingId: _aizhanBookingId,
            source: BookingSource.airbnb,
            guestName: 'Айжан',
            checkIn: at(0, 14),
            checkOut: at(3, 12),
            totalPrice: 127500,
            createdAt: at(-6, 11, 24),
            isConfirmed: true,
            isPhoneVerified: false,
            confirmationCode: 'HM73P2',
          ),
          ConflictBookingEntity(
            bookingId: _maratBookingId,
            source: BookingSource.direct,
            guestName: 'Марат',
            checkIn: at(2, 14),
            checkOut: at(5, 12),
            totalPrice: 114000,
            createdAt: at(-1, 19, 20),
            isConfirmed: false,
            isPhoneVerified: true,
          ),
        ],
      ),
      position: 1,
      total: 1,
      receivedAt: now,
      keptBookingId: _keptBookingByConflict[esentaiConflictId],
    );
  }

  static Failure _unknownConflict(String id) {
    return ServerFailure(statusCode: 404, message: 'Unknown conflict $id');
  }
}
