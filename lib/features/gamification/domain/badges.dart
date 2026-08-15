import 'package:ship_it_english/core/i18n/app_strings.dart';

/// マイルストーンバッジ（実績）。
///
/// ストリーク・学習量・ユニットクリア・パーフェクト・称号到達の節目で獲得する
/// コレクション。中長期の継続動機（「次のバッジまであと少し」）を作る。
/// 判定は端末内の統計のみ・通信なし。
enum BadgeKind {
  /// ストリーク日数
  streak,

  /// 学習着手カード数（status != 'new'）
  studied,

  /// クリアしたユニット数
  unitsCleared,

  /// パーフェクトセッション回数
  perfect,

  /// 到達レベル（称号の節目）
  rank,
}

/// バッジ定義（名前・説明はカテゴリ定義と同様にバイリンガルで持つ）。
class BadgeDef {
  final String id;
  final String emoji;
  final BadgeKind kind;

  /// 獲得条件のしきい値（kind の対象値がこれ以上で獲得）。
  final int threshold;

  final String nameJa;
  final String nameEn;
  final String descJa;
  final String descEn;

  const BadgeDef({
    required this.id,
    required this.emoji,
    required this.kind,
    required this.threshold,
    required this.nameJa,
    required this.nameEn,
    required this.descJa,
    required this.descEn,
  });

  String name(LanguageMode mode) =>
      mode == LanguageMode.ja ? nameJa : nameEn;

  String desc(LanguageMode mode) =>
      mode == LanguageMode.ja ? descJa : descEn;
}

/// バッジ判定に使う現在の統計値のスナップショット。
class BadgeInput {
  final int streak;
  final int studied;
  final int unitsCleared;
  final int perfectCount;
  final int level;

  const BadgeInput({
    required this.streak,
    required this.studied,
    required this.unitsCleared,
    required this.perfectCount,
    required this.level,
  });
}

/// 全バッジ（順序＝一覧の表示順）。
const List<BadgeDef> allBadges = [
  // --- ストリーク ---
  BadgeDef(id: 'streak_3', emoji: '🔥', kind: BadgeKind.streak, threshold: 3, nameJa: '3日ストリーク', nameEn: '3-Day Streak', descJa: '3日連続で学習した', descEn: 'Studied 3 days in a row'),
  BadgeDef(id: 'streak_7', emoji: '📅', kind: BadgeKind.streak, threshold: 7, nameJa: '1週間ストリーク', nameEn: '1-Week Streak', descJa: '7日連続で学習した', descEn: 'Studied 7 days in a row'),
  BadgeDef(id: 'streak_30', emoji: '🗓️', kind: BadgeKind.streak, threshold: 30, nameJa: '1ヶ月ストリーク', nameEn: '1-Month Streak', descJa: '30日連続で学習した', descEn: 'Studied 30 days in a row'),
  BadgeDef(id: 'streak_100', emoji: '💯', kind: BadgeKind.streak, threshold: 100, nameJa: '100日ストリーク', nameEn: '100-Day Streak', descJa: '100日連続で学習した', descEn: 'Studied 100 days in a row'),
  // --- 学習量 ---
  BadgeDef(id: 'studied_100', emoji: '📚', kind: BadgeKind.studied, threshold: 100, nameJa: '100枚学習', nameEn: '100 Cards', descJa: '100枚のカードに着手した', descEn: 'Started 100 cards'),
  BadgeDef(id: 'studied_500', emoji: '🧠', kind: BadgeKind.studied, threshold: 500, nameJa: '500枚学習', nameEn: '500 Cards', descJa: '500枚のカードに着手した', descEn: 'Started 500 cards'),
  BadgeDef(id: 'studied_1500', emoji: '🏛️', kind: BadgeKind.studied, threshold: 1500, nameJa: '全カード学習', nameEn: 'Full Deck', descJa: 'すべてのカードに着手した', descEn: 'Started every card in the deck'),
  // --- ユニット ---
  BadgeDef(id: 'unit_1', emoji: '🚩', kind: BadgeKind.unitsCleared, threshold: 1, nameJa: '初ユニットクリア', nameEn: 'First Unit', descJa: 'はじめてユニットをクリアした', descEn: 'Cleared your first unit'),
  BadgeDef(id: 'unit_10', emoji: '⛰️', kind: BadgeKind.unitsCleared, threshold: 10, nameJa: '10ユニット', nameEn: '10 Units', descJa: 'ユニットを10個クリアした', descEn: 'Cleared 10 units'),
  BadgeDef(id: 'unit_30', emoji: '🏔️', kind: BadgeKind.unitsCleared, threshold: 30, nameJa: '30ユニット', nameEn: '30 Units', descJa: 'ユニットを30個クリアした', descEn: 'Cleared 30 units'),
  // --- パーフェクト ---
  BadgeDef(id: 'perfect_1', emoji: '⭐', kind: BadgeKind.perfect, threshold: 1, nameJa: '初パーフェクト', nameEn: 'First Perfect', descJa: '全問1発「覚えてた」でセッションを終えた', descEn: 'Finished a session with every card right first try'),
  BadgeDef(id: 'perfect_10', emoji: '🌟', kind: BadgeKind.perfect, threshold: 10, nameJa: 'パーフェクト×10', nameEn: 'Perfect ×10', descJa: 'パーフェクトセッションを10回達成した', descEn: 'Achieved 10 perfect sessions'),
  // --- 称号到達（rankForLevel の閾値と同期させること） ---
  BadgeDef(id: 'rank_junior', emoji: '🎓', kind: BadgeKind.rank, threshold: 5, nameJa: 'Junior Engineer', nameEn: 'Junior Engineer', descJa: 'レベル5に到達した', descEn: 'Reached level 5'),
  BadgeDef(id: 'rank_engineer', emoji: '💻', kind: BadgeKind.rank, threshold: 10, nameJa: 'Engineer', nameEn: 'Engineer', descJa: 'レベル10に到達した', descEn: 'Reached level 10'),
  BadgeDef(id: 'rank_senior', emoji: '🚀', kind: BadgeKind.rank, threshold: 16, nameJa: 'Senior Engineer', nameEn: 'Senior Engineer', descJa: 'レベル16に到達した', descEn: 'Reached level 16'),
  BadgeDef(id: 'rank_staff', emoji: '🛠️', kind: BadgeKind.rank, threshold: 24, nameJa: 'Staff Engineer', nameEn: 'Staff Engineer', descJa: 'レベル24に到達した', descEn: 'Reached level 24'),
  BadgeDef(id: 'rank_principal', emoji: '👑', kind: BadgeKind.rank, threshold: 34, nameJa: 'Principal Engineer', nameEn: 'Principal Engineer', descJa: 'レベル34に到達した', descEn: 'Reached level 34'),
  BadgeDef(id: 'rank_distinguished', emoji: '🏆', kind: BadgeKind.rank, threshold: 50, nameJa: 'Distinguished', nameEn: 'Distinguished', descJa: 'レベル50に到達した', descEn: 'Reached level 50'),
];

/// バッジ [badge] が現在値 [input] で獲得条件を満たしているか。
bool isBadgeEarned(BadgeDef badge, BadgeInput input) {
  final value = switch (badge.kind) {
    BadgeKind.streak => input.streak,
    BadgeKind.studied => input.studied,
    BadgeKind.unitsCleared => input.unitsCleared,
    BadgeKind.perfect => input.perfectCount,
    BadgeKind.rank => input.level,
  };
  return value >= badge.threshold;
}

/// 未獲得のうち、今回の統計で新たに条件を満たしたバッジ（表示順）。
List<BadgeDef> newlyEarnedBadges(BadgeInput input, Set<String> earnedIds) {
  return allBadges
      .where((b) => !earnedIds.contains(b.id) && isBadgeEarned(b, input))
      .toList();
}
