import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_connection_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/channels_repository.dart';

/// The last check of the test channels: 22 October 2026, 09:38.
final DateTime channelsTestCheckedAt = DateTime(2026, 10, 22, 9, 38);

/// When the source answered: 22 October 2026, 09:45, so the last check is
/// today and the next one, at 09:53, is in 8 minutes.
final DateTime channelsTestReceivedAt = DateTime(2026, 10, 22, 9, 45);

/// Booking.com, connected with Esentai `p1` and Mega Towers `p2`.
ChannelEntity testBookingChannel() {
  return ChannelEntity(
    id: 'booking-com',
    name: 'Booking.com',
    status: ChannelStatus.connected,
    connections: const <ChannelConnectionEntity>[
      ChannelConnectionEntity(
        propertyId: 'p1',
        propertyName: 'Esentai City',
        unit: '84',
        mode: ChannelSyncMode.importAndExport,
        status: ChannelConnectionStatus.working,
        importUrl: 'booking.com/ical/p1.ics',
        exportUrl: 'easybooking.kz/ical/p1.ics',
      ),
      ChannelConnectionEntity(
        propertyId: 'p2',
        propertyName: 'Mega Towers',
        unit: '126',
        mode: ChannelSyncMode.importOnly,
        status: ChannelConnectionStatus.working,
        importUrl: 'booking.com/ical/p2.ics',
      ),
    ],
    checkInterval: const Duration(minutes: 15),
    receivedAt: channelsTestReceivedAt,
    lastSyncedAt: channelsTestCheckedAt,
    nextCheckAt: DateTime(2026, 10, 22, 9, 53),
  );
}

/// Airbnb, whose Mega Towers `p2` import failed; Esentai `p1` works.
ChannelEntity testAirbnbChannel({bool isRepaired = false}) {
  return ChannelEntity(
    id: 'airbnb',
    name: 'Airbnb',
    status: isRepaired ? ChannelStatus.connected : ChannelStatus.failed,
    connections: <ChannelConnectionEntity>[
      const ChannelConnectionEntity(
        propertyId: 'p1',
        propertyName: 'Esentai City',
        unit: '84',
        mode: ChannelSyncMode.importAndExport,
        status: ChannelConnectionStatus.working,
        importUrl: 'airbnb.com/ical/p1.ics',
        exportUrl: 'easybooking.kz/ical/airbnb-p1.ics',
      ),
      ChannelConnectionEntity(
        propertyId: 'p2',
        propertyName: 'Mega Towers',
        unit: '126',
        mode: ChannelSyncMode.importAndExport,
        status: isRepaired
            ? ChannelConnectionStatus.working
            : ChannelConnectionStatus.failed,
        importUrl: 'airbnb.com/ical/p2.ics',
        exportUrl: 'easybooking.kz/ical/airbnb-p2.ics',
      ),
    ],
    checkInterval: const Duration(minutes: 15),
    receivedAt: channelsTestReceivedAt,
    lastSyncedAt: channelsTestCheckedAt,
    nextCheckAt: DateTime(2026, 10, 22, 9, 53),
  );
}

/// Krisha: manual bookings, no import.
ChannelEntity testManualChannel() {
  return ChannelEntity(
    id: 'krisha',
    name: 'Krisha',
    status: ChannelStatus.manual,
    connections: const <ChannelConnectionEntity>[],
    checkInterval: const Duration(minutes: 15),
    receivedAt: channelsTestReceivedAt,
  );
}

/// Avito, turned off by the host.
ChannelEntity testDisconnectedChannel() {
  return ChannelEntity(
    id: 'avito',
    name: 'Avito',
    status: ChannelStatus.disconnected,
    connections: const <ChannelConnectionEntity>[],
    checkInterval: const Duration(minutes: 15),
    receivedAt: channelsTestReceivedAt,
  );
}

/// One channel in each status.
ChannelsOverviewEntity testChannelsOverview() {
  return ChannelsOverviewEntity(
    channels: <ChannelEntity>[
      testBookingChannel(),
      testAirbnbChannel(),
      testManualChannel(),
      testDisconnectedChannel(),
    ],
    checkedAt: channelsTestCheckedAt,
    receivedAt: channelsTestReceivedAt,
  );
}

/// [ChannelsRepository] over [testChannelsOverview] that records calls.
///
/// Set a `hold…` flag to keep the next calls of that method pending; each
/// gets a completer in the matching `held…` list. Set [error] to throw it
/// from every call.
final class FakeChannelsRepository implements ChannelsRepository {
  Either<Failure, ChannelsOverviewEntity> channelsResult =
      Right<Failure, ChannelsOverviewEntity>(testChannelsOverview());

  /// `null` answers with the channel of [testChannelsOverview], or 404.
  Either<Failure, ChannelEntity>? channelResult;

  /// `null` answers with the channel, repaired when it is Airbnb.
  Either<Failure, ChannelEntity>? syncResult;
  Either<Failure, void> disconnectResult = const Right<Failure, void>(null);
  Object? error;

  bool holdChannels = false;
  final List<Completer<Either<Failure, ChannelsOverviewEntity>>> heldChannels =
      <Completer<Either<Failure, ChannelsOverviewEntity>>>[];
  bool holdChannel = false;
  final List<Completer<Either<Failure, ChannelEntity>>> heldChannel =
      <Completer<Either<Failure, ChannelEntity>>>[];
  bool holdSync = false;
  final List<Completer<Either<Failure, ChannelEntity>>> heldSyncs =
      <Completer<Either<Failure, ChannelEntity>>>[];
  bool holdDisconnect = false;
  final List<Completer<Either<Failure, void>>> heldDisconnects =
      <Completer<Either<Failure, void>>>[];

  int channelsCount = 0;
  final List<String> channelRequests = <String>[];
  final List<String> syncRequests = <String>[];
  final List<String> disconnectRequests = <String>[];

  @override
  Future<Either<Failure, ChannelsOverviewEntity>> getChannels() async {
    channelsCount += 1;
    _throwIfSet();
    if (holdChannels) {
      return _hold(heldChannels);
    }
    return channelsResult;
  }

  @override
  Future<Either<Failure, ChannelEntity>> getChannel(String id) async {
    channelRequests.add(id);
    _throwIfSet();
    if (holdChannel) {
      return _hold(heldChannel);
    }
    return channelResult ?? _find(id);
  }

  @override
  Future<Either<Failure, ChannelEntity>> syncChannel(String id) async {
    syncRequests.add(id);
    _throwIfSet();
    if (holdSync) {
      return _hold(heldSyncs);
    }
    final Either<Failure, ChannelEntity>? result = syncResult;
    if (result != null) {
      return result;
    }
    if (id == 'airbnb') {
      return Right<Failure, ChannelEntity>(testAirbnbChannel(isRepaired: true));
    }
    return _find(id);
  }

  @override
  Future<Either<Failure, void>> disconnectChannel(String id) async {
    disconnectRequests.add(id);
    _throwIfSet();
    if (holdDisconnect) {
      return _hold(heldDisconnects);
    }
    return disconnectResult;
  }

  void _throwIfSet() {
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
  }

  static Future<T> _hold<T>(List<Completer<T>> held) {
    final Completer<T> completer = Completer<T>();
    held.add(completer);
    return completer.future;
  }

  static Either<Failure, ChannelEntity> _find(String id) {
    for (final ChannelEntity channel in testChannelsOverview().channels) {
      if (channel.id == id) {
        return Right<Failure, ChannelEntity>(channel);
      }
    }
    return const Left<Failure, ChannelEntity>(ServerFailure(statusCode: 404));
  }
}
