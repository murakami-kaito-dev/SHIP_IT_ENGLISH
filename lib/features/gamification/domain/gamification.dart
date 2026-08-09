import 'package:ship_it_english/features/study/domain/models/study_session.dart';

/// ゲーミフィケーションのチューニング値（XP量・コンボ閾値・倍率など）を1か所に集約。
/// バランス調整はここだけを触れば済むようにする。
class GamificationConfig {
  // 1回で正解できたときの基礎XP（評価ごと）。
  static const int xpRemembered = 12; // 覚えてた
  static const int xpUncertain = 6; // 曖昧（正解扱いだが控えめ）
  static const int xpForgot = 3; // 忘れた（それでも「挑戦した」分だけ加点＝負の感情を軽減）

  // コンボ（連続で1回正解）1つあたりの追加ボーナスXP。
  static const int xpPerCombo = 2;
  static const int xpComboBonusCap = 20; // コンボボーナスの上限

  // FEVER（連続正解がこの数に達したら突入）。
  static const int feverThreshold = 5;
  static const double feverMultiplier = 1.5; // FEVER中の獲得XP倍率

  // 今日の目標カード数（達成でストリークの炎が強く発光）。
  static const int dailyGoalCards = 20;

  /// レベル [level]（1始まり）から次のレベルへ上がるのに必要なXP。
  /// 少しずつ増える緩やかなカーブ。
  static int xpForLevel(int level) => 60 + level * 40;

  // --- ストリーク保護（XPで交換する特典） ---
  /// ストリーク保護1つの交換コスト（使えるXP）。
  static const int streakFreezeCost = 200;

  /// 同時に持てるストリーク保護の上限。
  static const int maxStreakFreezes = 3;
}

/// レベル帯に対応する称号（テック企業のキャリアラダーになぞらえる）。
/// 数値だけのレベルに「今どの立場か」という意味を与える。
enum EngineerRank {
  intern,
  junior,
  engineer,
  senior,
  staff,
  principal,
  distinguished,
}

/// レベル [level] から称号を求める（各帯の下限レベル）。
EngineerRank rankForLevel(int level) {
  if (level >= 25) return EngineerRank.distinguished;
  if (level >= 17) return EngineerRank.principal;
  if (level >= 12) return EngineerRank.staff;
  if (level >= 8) return EngineerRank.senior;
  if (level >= 5) return EngineerRank.engineer;
  if (level >= 3) return EngineerRank.junior;
  return EngineerRank.intern;
}

/// あるXP総量に対する「レベル・レベル内進捗」のスナップショット。
class GamificationSnapshot {
  final int totalXp;
  final int level;

  /// 現在のレベル内で獲得済みのXP。
  final int xpIntoLevel;

  /// 現在のレベルから次のレベルに上がるのに必要なXP。
  final int xpForNextLevel;

  const GamificationSnapshot({
    required this.totalXp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  double get progress =>
      xpForNextLevel > 0 ? (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0) : 0.0;

  /// XP総量からレベルとレベル内進捗を算出する（純関数）。
  factory GamificationSnapshot.fromTotalXp(int totalXp) {
    var level = 1;
    var remaining = totalXp < 0 ? 0 : totalXp;
    while (remaining >= GamificationConfig.xpForLevel(level)) {
      remaining -= GamificationConfig.xpForLevel(level);
      level++;
    }
    return GamificationSnapshot(
      totalXp: totalXp,
      level: level,
      xpIntoLevel: remaining,
      xpForNextLevel: GamificationConfig.xpForLevel(level),
    );
  }

  static const empty =
      GamificationSnapshot(totalXp: 0, level: 1, xpIntoLevel: 0, xpForNextLevel: 100);
}

/// 1回の評価が生んだ演出用の結果。study_screen がこれを見てエフェクトを発火する。
class AnswerOutcome {
  final Rating rating;

  /// 1回で正解できたか（＝コンボ対象）。
  final bool firstTryCorrect;

  /// この評価で獲得したXP（FEVER倍率・コンボボーナス適用後）。
  final int xpGained;

  /// 評価後の連続正解数（0ならコンボ途切れ）。
  final int combo;

  /// FEVER中か（combo >= feverThreshold）。
  final bool fever;

  /// この評価でレベルアップしたか。
  final bool leveledUp;

  /// レベルアップ後のレベル（leveledUp のときのみ意味を持つ）。
  final int newLevel;

  const AnswerOutcome({
    required this.rating,
    required this.firstTryCorrect,
    required this.xpGained,
    required this.combo,
    required this.fever,
    required this.leveledUp,
    required this.newLevel,
  });

  bool get isCorrect => rating == Rating.remembered || rating == Rating.uncertain;
}
