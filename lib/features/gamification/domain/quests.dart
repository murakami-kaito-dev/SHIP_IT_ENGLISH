import 'dart:math';

/// デイリークエストの種類。
/// 「今日開く理由」を作る日替わりのお題。学習行動そのものを対象にする
/// （IT英語学習という核は変えず、行動の枠組みだけを与える）。
enum QuestType {
  /// カードを N 枚学習する（形式は問わない）
  studyCards,

  /// コンボ（連続1回正解）を N まで伸ばす
  comboReach,

  /// 「覚えてた」評価を N 回出す
  remembered,

  /// 耳学で N クリップ（行）を聴き切る
  listenLines,
}

/// クエスト1件（種類＋目標値）。
class Quest {
  final QuestType type;
  final int target;

  const Quest({required this.type, required this.target});

  @override
  bool operator ==(Object other) =>
      other is Quest && other.type == type && other.target == target;

  @override
  int get hashCode => Object.hash(type, target);
}

/// クエストのチューニング値（目標値の候補・宝箱の報酬）を1か所に集約。
class QuestConfig {
  /// 1日のクエスト数（1つ目は必ず studyCards＝入口を低く）。
  static const int questsPerDay = 3;

  static const List<int> studyTargets = [10, 15, 20];
  static const List<int> comboTargets = [4, 5, 6];
  static const List<int> rememberedTargets = [6, 8, 10];
  static const List<int> listenTargets = [6, 10, 14];

  /// 宝箱XPの範囲（可変報酬：毎回同じ額にしない）。
  static const int chestXpMin = 30;
  static const int chestXpMax = 60;

  /// 宝箱からストリーク保護が出る確率（所持上限未満のときだけ）。
  static const double chestFreezeChance = 0.10;
}

/// その日のクエスト3件を決定的に生成する（日付が同じなら常に同じ結果）。
/// 保存不要・端末間でも同日なら同じお題になる。
List<Quest> questsForDate(DateTime date) {
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final rng = Random(seed);

  Quest pick(QuestType type, List<int> targets) =>
      Quest(type: type, target: targets[rng.nextInt(targets.length)]);

  // 1つ目は必ず「N枚学習」（達成しやすい入口クエスト）
  final quests = <Quest>[pick(QuestType.studyCards, QuestConfig.studyTargets)];

  // 残り2つは他の種類からランダムに（重複なし）
  final pool = <QuestType>[
    QuestType.comboReach,
    QuestType.remembered,
    QuestType.listenLines,
  ]..shuffle(rng);
  for (final type in pool.take(QuestConfig.questsPerDay - 1)) {
    final targets = switch (type) {
      QuestType.comboReach => QuestConfig.comboTargets,
      QuestType.remembered => QuestConfig.rememberedTargets,
      QuestType.listenLines => QuestConfig.listenTargets,
      QuestType.studyCards => QuestConfig.studyTargets,
    };
    quests.add(pick(type, targets));
  }
  return quests;
}

/// 宝箱の中身（可変報酬）。
class ChestReward {
  final int xp;

  /// ストリーク保護が当たったか（所持上限未満のときだけ true になり得る）。
  final bool streakFreeze;

  const ChestReward({required this.xp, required this.streakFreeze});
}

/// 宝箱を開けた結果を抽選する（テストのため Random を注入可能）。
ChestReward rollChestReward({required bool canGrantFreeze, Random? rng}) {
  final r = rng ?? Random();
  final xp = QuestConfig.chestXpMin +
      r.nextInt(QuestConfig.chestXpMax - QuestConfig.chestXpMin + 1);
  final freeze =
      canGrantFreeze && r.nextDouble() < QuestConfig.chestFreezeChance;
  return ChestReward(xp: xp, streakFreeze: freeze);
}

/// 今日のクエスト進捗（カウンタ）。prefs に日付付きJSONで保存し、日付が変わったら
/// リセットされる。カウンタはクエストに採用されていない指標も常に記録する
/// （どの組み合わせが選ばれても正しく進むように）。
class QuestProgress {
  final String date; // YYYY-MM-DD
  final int studied;
  final int comboMax;
  final int remembered;
  final int listenLines;
  final bool chestClaimed;

  /// 受け取った宝箱XP（表示用。未受領は0）。
  final int claimedXp;

  const QuestProgress({
    required this.date,
    this.studied = 0,
    this.comboMax = 0,
    this.remembered = 0,
    this.listenLines = 0,
    this.chestClaimed = false,
    this.claimedXp = 0,
  });

  QuestProgress copyWith({
    int? studied,
    int? comboMax,
    int? remembered,
    int? listenLines,
    bool? chestClaimed,
    int? claimedXp,
  }) =>
      QuestProgress(
        date: date,
        studied: studied ?? this.studied,
        comboMax: comboMax ?? this.comboMax,
        remembered: remembered ?? this.remembered,
        listenLines: listenLines ?? this.listenLines,
        chestClaimed: chestClaimed ?? this.chestClaimed,
        claimedXp: claimedXp ?? this.claimedXp,
      );

  /// クエスト [quest] の現在値。
  int valueFor(Quest quest) => switch (quest.type) {
        QuestType.studyCards => studied,
        QuestType.comboReach => comboMax,
        QuestType.remembered => remembered,
        QuestType.listenLines => listenLines,
      };

  bool isDone(Quest quest) => valueFor(quest) >= quest.target;

  bool allDone(List<Quest> quests) => quests.every(isDone);

  Map<String, dynamic> toJson() => {
        'date': date,
        'studied': studied,
        'comboMax': comboMax,
        'remembered': remembered,
        'listenLines': listenLines,
        'chestClaimed': chestClaimed,
        'claimedXp': claimedXp,
      };

  factory QuestProgress.fromJson(Map<String, dynamic> json) => QuestProgress(
        date: json['date'] as String? ?? '',
        studied: json['studied'] as int? ?? 0,
        comboMax: json['comboMax'] as int? ?? 0,
        remembered: json['remembered'] as int? ?? 0,
        listenLines: json['listenLines'] as int? ?? 0,
        chestClaimed: json['chestClaimed'] as bool? ?? false,
        claimedXp: json['claimedXp'] as int? ?? 0,
      );
}
