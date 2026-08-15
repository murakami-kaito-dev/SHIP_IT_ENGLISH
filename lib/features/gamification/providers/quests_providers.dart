import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';
import 'package:ship_it_english/features/gamification/domain/quests.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

/// デイリークエストの状態（今日のクエスト3件＋進捗カウンタ）。
class QuestsState {
  final List<Quest> quests;
  final QuestProgress progress;

  const QuestsState({required this.quests, required this.progress});

  bool get allDone => progress.allDone(quests);
  bool get chestReady => allDone && !progress.chestClaimed;
  int get doneCount => quests.where(progress.isDone).length;

  QuestsState copyWith({List<Quest>? quests, QuestProgress? progress}) =>
      QuestsState(
        quests: quests ?? this.quests,
        progress: progress ?? this.progress,
      );
}

/// デイリークエストの進捗を記録し、宝箱の受け取りを管理する。
/// - クエストの選定は日付から決定的に生成（保存しない）
/// - 進捗カウンタのみ prefs にJSONで永続化（日付が変わると自動リセット）
class QuestsNotifier extends StateNotifier<QuestsState> {
  /// テストで日付を固定できるようにする（既定は現在時刻）。
  final DateTime Function() _now;

  QuestsNotifier({DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(QuestsState(
          quests: questsForDate((now ?? DateTime.now)()),
          progress:
              QuestProgress(date: (now ?? DateTime.now)().toDateString()),
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyQuestProgress);
    if (raw == null) return;
    try {
      final stored =
          QuestProgress.fromJson(json.decode(raw) as Map<String, dynamic>);
      // 保存されていた進捗が今日の分ならそれを採用（昨日以前なら捨てる）
      if (stored.date == _now().toDateString()) {
        state = state.copyWith(progress: stored);
      }
    } catch (_) {
      // 壊れたJSONは無視して今日ゼロから（クエストは学習の飾りであり、失敗で
      // アプリを止めない）
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.keyQuestProgress, json.encode(state.progress.toJson()));
  }

  /// 日付が変わっていたら今日のクエスト・進捗に切り替える（冪等）。
  /// ホーム表示時・アプリ復帰時に呼ぶ。
  void ensureToday() {
    final today = _now().toDateString();
    if (state.progress.date == today) return;
    state = QuestsState(
      quests: questsForDate(_now()),
      progress: QuestProgress(date: today),
    );
    _persist();
  }

  /// 学習セッションでの評価1件を反映する。
  /// [combo] は評価後の連続正解数（AnswerOutcome.combo）。
  Future<void> recordAnswer({required Rating rating, required int combo}) async {
    ensureToday();
    final p = state.progress;
    state = state.copyWith(
      progress: p.copyWith(
        studied: p.studied + 1,
        remembered:
            rating == Rating.remembered ? p.remembered + 1 : p.remembered,
        comboMax: combo > p.comboMax ? combo : p.comboMax,
      ),
    );
    await _persist();
  }

  /// 耳学でクリップ（行）を1つ聴き切ったときに呼ぶ。
  Future<void> recordListenLine() async {
    ensureToday();
    final p = state.progress;
    state = state.copyWith(progress: p.copyWith(listenLines: p.listenLines + 1));
    await _persist();
  }

  /// 宝箱を開ける。全クエスト達成済み・未受領のときだけ成功し、報酬を返す。
  /// XP付与・ストリーク保護付与は呼び出し側（UI）が gamificationProvider 経由で行う
  /// （このNotifierは進捗の記録に専念する）。
  Future<ChestReward?> claimChest(
      {required bool canGrantFreeze, Random? rng}) async {
    ensureToday();
    if (!state.chestReady) return null;
    final reward = rollChestReward(canGrantFreeze: canGrantFreeze, rng: rng);
    state = state.copyWith(
      progress:
          state.progress.copyWith(chestClaimed: true, claimedXp: reward.xp),
    );
    await _persist();
    return reward;
  }
}

final dailyQuestsProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>((ref) {
  return QuestsNotifier();
});
