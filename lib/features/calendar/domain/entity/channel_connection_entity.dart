import 'package:equatable/equatable.dart';

/// Which way availability flows between the channel and EasyBooking.
enum ChannelSyncMode {
  /// «Импорт и экспорт».
  importAndExport,

  /// «Только импорт».
  importOnly,
}

enum ChannelConnectionStatus {
  /// «Работает».
  working,

  /// The last import failed, usually because of a broken iCal link.
  failed,
}

/// One property's calendar link with a channel.
final class ChannelConnectionEntity extends Equatable {
  const ChannelConnectionEntity({
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.mode,
    required this.status,
    required this.importUrl,
    this.exportUrl,
  });

  final String propertyId;

  /// Building or complex, such as `Esentai City`.
  final String propertyName;

  /// Apartment number within [propertyName].
  final String unit;
  final ChannelSyncMode mode;
  final ChannelConnectionStatus status;

  /// The channel's iCal link EasyBooking imports («Импорт занятости»).
  final String importUrl;

  /// EasyBooking's iCal link for the channel («Экспорт из EasyBooking»);
  /// `null` for [ChannelSyncMode.importOnly].
  final String? exportUrl;

  bool get isFailed => status == ChannelConnectionStatus.failed;

  @override
  List<Object?> get props => <Object?>[
    propertyId,
    propertyName,
    unit,
    mode,
    status,
    importUrl,
    exportUrl,
  ];
}
