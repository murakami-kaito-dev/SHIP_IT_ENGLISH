import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:ship_it_english/features/study/domain/srs_engine.dart';

void main() {
  late SrsEngine engine;
  late LearningProgress initial;

  setUp(() {
    engine = SrsEngine();
    initial = LearningProgress.initial('card_001');
  });

  group('SrsEngine.processReview', () {
    test('1. 新規カードに「わかった」→ interval = 1, repetitions = 1', () {
      final result = engine.processReview(
        current: initial,
        rating: Rating.remembered,
      );

      expect(result.intervalDays, 1);
      expect(result.repetitions, 1);
      expect(result.status, CardStatus.review);
    });

    test('2. 1回正答済みカードに「わかった」→ interval = 3, repetitions = 2', () {
      final afterFirst = engine.processReview(
        current: initial,
        rating: Rating.remembered,
      );
      final result = engine.processReview(
        current: afterFirst,
        rating: Rating.remembered,
      );

      expect(result.intervalDays, 3);
      expect(result.repetitions, 2);
    });

    test('3. 2回正答済みカードに「わかった」→ interval = round(前回interval × ease_factor)', () {
      final afterFirst = engine.processReview(
        current: initial,
        rating: Rating.remembered,
      );
      final afterSecond = engine.processReview(
        current: afterFirst,
        rating: Rating.remembered,
      );
      final result = engine.processReview(
        current: afterSecond,
        rating: Rating.remembered,
      );

      final expected = (afterSecond.intervalDays * afterSecond.easeFactor)
          .round();
      expect(result.intervalDays, expected);
      expect(result.repetitions, 3);
    });

    test('4. 任意の状態で「わからなかった」→ repetitions = 0, interval = 0', () {
      // まず2回正解させてから忘れる
      final afterFirst = engine.processReview(
        current: initial,
        rating: Rating.remembered,
      );
      final afterSecond = engine.processReview(
        current: afterFirst,
        rating: Rating.remembered,
      );

      final result = engine.processReview(
        current: afterSecond,
        rating: Rating.forgot,
      );

      expect(result.repetitions, 0);
      expect(result.intervalDays, 0);
      expect(result.status, CardStatus.learning);
    });

    test('5. 「あいまい」→ 正解扱いだがease_factorの上昇が小さい', () {
      final rememberedResult = engine.processReview(
        current: initial,
        rating: Rating.remembered,
      );
      final uncertainResult = engine.processReview(
        current: initial,
        rating: Rating.uncertain,
      );

      // どちらも repetitions が増える
      expect(uncertainResult.repetitions, 1);
      // 「わかった」より ease_factor の上昇が小さい
      expect(uncertainResult.easeFactor, lessThan(rememberedResult.easeFactor));
      // 両方とも status は review
      expect(uncertainResult.status, CardStatus.review);
    });

    test('6. ease_factorが1.3を下回らない', () {
      // 「わからなかった」を連続して評価しても1.3を下回らない
      // 注: forgot は repetitions リセットなので ease_factor は変更されないが、
      // uncertain は ease_factor を下げる可能性があるので uncertain で確認
      LearningProgress progress = initial;
      for (int i = 0; i < 10; i++) {
        progress = engine.processReview(
          current: progress,
          rating: Rating.uncertain,
        );
      }

      expect(progress.easeFactor, greaterThanOrEqualTo(AppConstants.minimumEaseFactor));
    });

    test('7. interval >= 21日 で mastered ステータスになる', () {
      // 何度も正解させてintervalを21以上にする
      LearningProgress progress = initial;

      for (int i = 0; i < 10; i++) {
        progress = engine.processReview(
          current: progress,
          rating: Rating.remembered,
        );
        if (progress.status == CardStatus.mastered) break;
      }

      expect(progress.status, CardStatus.mastered);
      expect(progress.intervalDays, greaterThanOrEqualTo(AppConstants.masteredThresholdDays));
    });

    test('8. mastered状態のカードに「わからなかった」→ learning に戻る', () {
      // masteredカードを模擬
      final mastered = LearningProgress(
        cardId: 'card_001',
        easeFactor: 2.5,
        intervalDays: 30,
        repetitions: 5,
        nextReview: DateTime.now(),
        lastReviewed: DateTime.now().subtract(const Duration(days: 30)),
        status: CardStatus.mastered,
      );

      final result = engine.processReview(
        current: mastered,
        rating: Rating.forgot,
      );

      expect(result.status, CardStatus.learning);
      expect(result.repetitions, 0);
      expect(result.intervalDays, 0);
    });

    test('forgot → next_review は短い再学習ステップ（約10分後・当日中）', () {
      final result = engine.processReview(
        current: initial,
        rating: Rating.forgot,
      );

      final now = DateTime.now();
      // エビングハウス基準の短いステップ（relearnStepMinutes 分後）
      expect(result.nextReview.isAfter(now), true);
      expect(
        result.nextReview.isBefore(
          now.add(const Duration(minutes: AppConstants.relearnStepMinutes + 1)),
        ),
        true,
      );
    });

    test('projectedInterval: 新規カードの各評価の間隔', () {
      // 忘れた → 再学習ステップ（分）
      expect(
        engine.projectedInterval(current: initial, rating: Rating.forgot),
        const Duration(minutes: AppConstants.relearnStepMinutes),
      );
      // 覚えてた → 1日
      expect(
        engine.projectedInterval(current: initial, rating: Rating.remembered),
        const Duration(days: 1),
      );
    });

    test('remembered → next_review は interval日後', () {
      final result = engine.processReview(
        current: initial,
        rating: Rating.remembered,
      );

      final expectedDate = DateTime.now().add(Duration(days: result.intervalDays));
      // 数秒の誤差を許容
      expect(
        result.nextReview.difference(expectedDate).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    });
  });
}
