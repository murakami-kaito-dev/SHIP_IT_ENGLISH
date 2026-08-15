/// ユニット制：カテゴリを約20枚ごとの「ユニット」に区切り、ユニットごとの
/// 卒業テスト（クイズのみ）でクリアしていく。
///
/// SRS（終わりのない復習サイクル）と並走する「終わりのある道」を作るのが目的。
/// カテゴリ一覧が「130枚のリスト」ではなく「7つの関門」に見えるようになり、
/// クリアの区切り（達成感）が生まれる。
class UnitConfig {
  /// 1ユニットあたりのカード数（カテゴリ内の通し番号で区切る）。
  static const int unitSize = 20;

  /// クリアと判定する許容ミス数（これ以下ならクリア）。
  static const int maxMistakes = 2;

  /// ユニットクリアのボーナスXP。
  static const int clearXp = 50;
}

/// カテゴリ内の1ユニット（カード番号 [from]〜[to]・1始まり）。
class StudyUnit {
  /// 1始まりのユニット番号。
  final int index;
  final int from;
  final int to;

  const StudyUnit({required this.index, required this.from, required this.to});

  int get cardCount => to - from + 1;

  @override
  bool operator ==(Object other) =>
      other is StudyUnit &&
      other.index == index &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(index, from, to);
}

/// カテゴリの総カード数 [totalCards] からユニット一覧を作る。
/// 端数は最後のユニットに含める（例: 130枚 → 6×20 + 最後10枚の計7ユニット）。
List<StudyUnit> unitsForCount(int totalCards) {
  if (totalCards <= 0) return const [];
  final units = <StudyUnit>[];
  var from = 1;
  var index = 1;
  while (from <= totalCards) {
    final to = (from + UnitConfig.unitSize - 1).clamp(1, totalCards);
    units.add(StudyUnit(index: index, from: from, to: to));
    from = to + 1;
    index++;
  }
  return units;
}

/// クリア済みユニットの保存キー（prefs の Set 要素）。
String unitKey(String categoryId, int unitIndex) => '$categoryId:$unitIndex';

/// ユニットテストの合否判定（ミス数 ≤ 許容数でクリア）。
bool unitTestPassed(int mistakes) => mistakes <= UnitConfig.maxMistakes;
