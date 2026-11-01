import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/profile/domain/entity/active_session_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/plan_usage_entity.dart';

import '../../../../helpers/fake_profile_repository.dart';

void main() {
  group('HelpCenterEntity.matching', () {
    test('a blank query keeps everything', () {
      expect(testHelpCenter.matching('   '), same(testHelpCenter));
      expect(testHelpCenter.matching(''), same(testHelpCenter));
    });

    test('matches topic titles ignoring case and surrounding spaces', () {
      final HelpCenterEntity result = testHelpCenter.matching('  СИНХРОН ');

      expect(
        result.topics.map((HelpTopicEntity topic) => topic.id),
        <String>['calendar-sync'],
      );
      expect(result.guides, isEmpty);
      expect(result.support, testHelpCenter.support);
    });

    test('matches topic summaries and guide titles', () {
      expect(
        testHelpCenter
            .matching('карты')
            .topics
            .map((HelpTopicEntity topic) => topic.id),
        <String>['billing'],
      );
      final HelpCenterEntity airbnb = testHelpCenter.matching('airbnb');
      expect(airbnb.topics, isEmpty);
      expect(
        airbnb.guides.map((HelpGuideEntity guide) => guide.id),
        <String>['connect-airbnb'],
      );
    });

    test('no match leaves empty, unmodifiable lists', () {
      final HelpCenterEntity result = testHelpCenter.matching('zzz');

      expect(result.topics, isEmpty);
      expect(result.guides, isEmpty);
      expect(
        () => result.topics.add(testHelpCenter.topics.first),
        throwsUnsupportedError,
      );
    });
  });

  group('PlanUsageEntity', () {
    test('fraction is the used share of the limit', () {
      expect(const PlanUsageEntity(used: 4, limit: 10).fraction, 0.4);
      expect(const PlanUsageEntity(used: 0, limit: 5).fraction, 0);
    });

    test('fraction is clamped to 1 above the limit', () {
      expect(const PlanUsageEntity(used: 7, limit: 5).fraction, 1);
    });

    test('isAtLimit is true from the limit on', () {
      expect(const PlanUsageEntity(used: 4, limit: 5).isAtLimit, isFalse);
      expect(const PlanUsageEntity(used: 5, limit: 5).isAtLimit, isTrue);
      expect(const PlanUsageEntity(used: 6, limit: 5).isAtLimit, isTrue);
    });
  });

  group('SecurityOverviewEntity.otherSessions', () {
    test('lists every session except the current one', () {
      expect(
        testSecurityOverview().otherSessions.map(
          (ActiveSessionEntity session) => session.id,
        ),
        <String>['session-macbook'],
      );
      expect(
        testSecurityOverview(hasOtherSession: false).otherSessions,
        isEmpty,
      );
    });
  });
}
