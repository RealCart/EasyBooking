import 'package:equatable/equatable.dart';

/// The support chat («Поддержка EasyBooking»).
final class SupportContactEntity extends Equatable {
  const SupportContactEntity({
    required this.name,
    required this.typicalResponseTime,
    required this.isOnline,
  });

  final String name;

  /// «Обычно отвечаем за 10 минут».
  final Duration typicalResponseTime;
  final bool isOnline;

  @override
  List<Object?> get props => <Object?>[name, typicalResponseTime, isOnline];
}

/// A «Частые вопросы» topic.
final class HelpTopicEntity extends Equatable {
  const HelpTopicEntity({
    required this.id,
    required this.title,
    required this.summary,
  });

  final String id;

  /// Such as `Синхронизация календарей`.
  final String title;

  /// Such as `iCal, ошибки и частота обновлений`.
  final String summary;

  @override
  List<Object?> get props => <Object?>[id, title, summary];
}

/// A «Быстрые инструкции» guide.
final class HelpGuideEntity extends Equatable {
  const HelpGuideEntity({
    required this.id,
    required this.title,
    required this.readingTime,
  });

  final String id;

  /// Such as `Как подключить Airbnb`.
  final String title;
  final Duration readingTime;

  @override
  List<Object?> get props => <Object?>[id, title, readingTime];
}

/// Everything «Помощь» shows.
final class HelpCenterEntity extends Equatable {
  const HelpCenterEntity({
    required this.support,
    required this.topics,
    required this.guides,
  });

  final SupportContactEntity support;
  final List<HelpTopicEntity> topics;
  final List<HelpGuideEntity> guides;

  /// Topics and guides whose texts contain [query], ignoring case and
  /// surrounding spaces. A blank query keeps everything.
  HelpCenterEntity matching(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return this;
    }
    bool contains(String text) => text.toLowerCase().contains(needle);
    return HelpCenterEntity(
      support: support,
      topics: List<HelpTopicEntity>.unmodifiable(
        topics.where(
          (HelpTopicEntity topic) =>
              contains(topic.title) || contains(topic.summary),
        ),
      ),
      guides: List<HelpGuideEntity>.unmodifiable(
        guides.where((HelpGuideEntity guide) => contains(guide.title)),
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[support, topics, guides];
}
