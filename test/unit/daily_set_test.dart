import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:ship_it_english/features/study/domain/srs_engine.dart';

void main() {
  group('デイリーセット取得ロジック（SRS計算）', () {
    late SrsEngine engine;

    setUp(() {
      engine = SrsEngine();
    });

    test('新規カードは repetitions=0, status=new', () {
      final progress = LearningProgress.initial('card_001');
      expect(progress.repetitions, 0);
      expect(progress.status, CardStatus.newCard);
      expect(progress.intervalDays, 0);
      expect(progress.easeFactor, AppConstants.initialEaseFactor);
    });

    test('「わからなかった」評価後は next_review が短い再学習ステップ（当日中）', () {
      final progress = LearningProgress.initial('card_001');
      final result = engine.processReview(
        current: progress,
        rating: Rating.forgot,
      );

      // エビングハウス基準の短いステップ（relearnStepMinutes 分後・当日中）
      final now = DateTime.now();
      expect(result.nextReview.isAfter(now), true);
      expect(
        result.nextReview.isBefore(
          now.add(const Duration(minutes: AppConstants.relearnStepMinutes + 1)),
        ),
        true,
      );
    });

    test('「覚えてた」連続評価でintervalが増加する', () {
      LearningProgress progress = LearningProgress.initial('card_001');
      int prevInterval = 0;

      for (int i = 0; i < 5; i++) {
        progress = engine.processReview(
          current: progress,
          rating: Rating.remembered,
        );
        expect(progress.intervalDays, greaterThanOrEqualTo(prevInterval));
        prevInterval = progress.intervalDays;
      }
    });

    test('maxRetriesPerSession は 2 である', () {
      expect(AppConstants.maxRetriesPerSession, 2);
    });

    test('masteredThresholdDays は 21 である', () {
      expect(AppConstants.masteredThresholdDays, 21);
    });
  });
}
