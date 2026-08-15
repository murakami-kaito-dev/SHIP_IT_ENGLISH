import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

/// 技術英語カバレッジ（実力を表す単一スコア）。
///
/// XP（努力量）とは別に、「全カードのうちどれだけ身についているか」を
/// SRS状態の重み付きで1つの%にする。ELSA の発音スコアのように
/// 「続けたら数字が上がる＝上達の実感」を作るのが目的。
class SkillScoreConfig {
  /// SRS状態ごとの習熟重み（new=0）。
  static const double learningWeight = 0.25;
  static const double reviewWeight = 0.6;
  static const double masteredWeight = 1.0;

  /// 初期診断で「知ってる」と申告したカードに与える復習間隔（日）。
  /// 新規キューを飛ばして、程よい位置からSRSに乗せる。
  static const int placementKnownIntervalDays = 7;
}

/// SRS状態の枚数内訳から算出するスコア。
class SkillScore {
  final int newCount;
  final int learningCount;
  final int reviewCount;
  final int masteredCount;

  const SkillScore({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.masteredCount,
  });

  int get totalCount => newCount + learningCount + reviewCount + masteredCount;

  int get studiedCount => learningCount + reviewCount + masteredCount;

  /// 0〜100 のカバレッジ%（重み付き習熟度）。
  double get percent {
    if (totalCount == 0) return 0;
    final weighted = learningCount * SkillScoreConfig.learningWeight +
        reviewCount * SkillScoreConfig.reviewWeight +
        masteredCount * SkillScoreConfig.masteredWeight;
    return (weighted / totalCount * 100).clamp(0.0, 100.0);
  }

  /// 表示用（小数1桁。例 "12.4"）。
  String get display => percent.toStringAsFixed(1);

  static const empty = SkillScore(
      newCount: 0, learningCount: 0, reviewCount: 0, masteredCount: 0);
}

/// 初期診断で「知ってる」と申告したカードの学習進捗を作る。
/// 復習状態（review）・間隔7日・次回復習は7日後＝新規キューを飛ばして
/// ほどよい位置からSRSに乗る（正直な自己申告を学習開始位置に反映する）。
LearningProgress placementKnownProgress(String cardId, DateTime now) {
  return LearningProgress(
    cardId: cardId,
    easeFactor: AppConstants.initialEaseFactor,
    intervalDays: SkillScoreConfig.placementKnownIntervalDays,
    repetitions: 1,
    nextReview:
        now.add(const Duration(days: SkillScoreConfig.placementKnownIntervalDays)),
    lastReviewed: now,
    status: CardStatus.review,
    lastRating: Rating.remembered,
  );
}
