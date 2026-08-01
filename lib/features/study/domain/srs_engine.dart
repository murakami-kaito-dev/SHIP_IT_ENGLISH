import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

class SrsEngine {
  LearningProgress processReview({
    required LearningProgress current,
    required Rating rating,
  }) {
    final int quality = switch (rating) {
      Rating.forgot => 1,
      Rating.uncertain => 3,
      Rating.remembered => 5,
    };

    double newEaseFactor = current.easeFactor;
    int newInterval;
    int newRepetitions;
    CardStatus newStatus;

    if (quality < 3) {
      newRepetitions = 0;
      newInterval = 0;
      newStatus = CardStatus.learning;
    } else {
      newRepetitions = current.repetitions + 1;

      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 3;
      } else {
        newInterval = (current.intervalDays * newEaseFactor).round();
      }

      newEaseFactor = current.easeFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

      if (newEaseFactor < AppConstants.minimumEaseFactor) {
        newEaseFactor = AppConstants.minimumEaseFactor;
      }

      if (newInterval >= AppConstants.masteredThresholdDays) {
        newStatus = CardStatus.mastered;
      } else {
        newStatus = CardStatus.review;
      }
    }

    // 「忘れた」は当日中に急速に忘れるため、数十分後に再提示する
    // （エビングハウスの忘却曲線に基づく短い再学習ステップ）。
    final DateTime nextReview = quality < 3
        ? DateTime.now()
            .add(const Duration(minutes: AppConstants.relearnStepMinutes))
        : DateTime.now().add(Duration(days: newInterval));

    return LearningProgress(
      cardId: current.cardId,
      easeFactor: newEaseFactor,
      intervalDays: newInterval,
      repetitions: newRepetitions,
      nextReview: nextReview,
      lastReviewed: DateTime.now(),
      status: newStatus,
      lastRating: rating,
    );
  }

  /// 指定の評価を選んだ場合の「次に復習するまでの待ち時間」を返す（保存はしない）。
  /// 評価ボタンに次回間隔を表示するための予測に使う。表示と実挙動を一致させるため
  /// 内部で [processReview] を呼ぶ（副作用なし）。
  Duration projectedInterval({
    required LearningProgress current,
    required Rating rating,
  }) {
    final projected = processReview(current: current, rating: rating);
    // 日数の丸め誤差を避けるため、graduated（1日以上）は日数から直接組む。
    // 「忘れた」等の当日ステップは再学習ステップの分数を返す。
    if (projected.intervalDays <= 0) {
      return const Duration(minutes: AppConstants.relearnStepMinutes);
    }
    return Duration(days: projected.intervalDays);
  }
}
