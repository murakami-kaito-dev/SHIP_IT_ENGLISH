import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

/// ゲーミフィケーションの状態（永続XPスナップショット＋現在のコンボ）。
class GamificationState {
  final GamificationSnapshot snapshot;
  final int combo;

  /// 現在のセッションで獲得したXPの累計（完了画面の「獲得XP」表示用）。
  final int sessionXp;

  /// これまでに交換で使ったXPの累計。
  final int spentXp;

  /// 所持しているストリーク保護の数。
  final int streakFreezes;

  const GamificationState({
    required this.snapshot,
    required this.combo,
    required this.sessionXp,
    required this.spentXp,
    required this.streakFreezes,
  });

  bool get fever => combo >= GamificationConfig.feverThreshold;

  /// 交換に使える残高XP（通算 − 使用済み）。レベルは通算XPで決まるので減らない。
  int get availableXp {
    final v = snapshot.totalXp - spentXp;
    return v < 0 ? 0 : v;
  }

  /// もう1つストリーク保護を交換できるか（残高＋上限の両方を満たす）。
  bool get canBuyStreakFreeze =>
      availableXp >= GamificationConfig.streakFreezeCost &&
      streakFreezes < GamificationConfig.maxStreakFreezes;

  GamificationState copyWith({
    GamificationSnapshot? snapshot,
    int? combo,
    int? sessionXp,
    int? spentXp,
    int? streakFreezes,
  }) =>
      GamificationState(
        snapshot: snapshot ?? this.snapshot,
        combo: combo ?? this.combo,
        sessionXp: sessionXp ?? this.sessionXp,
        spentXp: spentXp ?? this.spentXp,
        streakFreezes: streakFreezes ?? this.streakFreezes,
      );

  static const initial = GamificationState(
      snapshot: GamificationSnapshot.empty,
      combo: 0,
      sessionXp: 0,
      spentXp: 0,
      streakFreezes: 0);
}

/// XP・レベル・コンボ・FEVERを管理する。XP総量のみ shared_preferences に永続化し、
/// レベルとレベル内進捗は都度算出する（[GamificationSnapshot.fromTotalXp]）。
/// コンボはセッション内の一時状態なので永続化しない。
class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier() : super(GamificationState.initial) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final totalXp = prefs.getInt(AppConstants.keyTotalXp) ?? 0;
    // ストリーク保護は StreakManager が起動時に自動消費するため、prefs を正とする
    state = state.copyWith(
      snapshot: GamificationSnapshot.fromTotalXp(totalXp),
      spentXp: prefs.getInt(AppConstants.keySpentXp) ?? 0,
      streakFreezes: prefs.getInt(AppConstants.keyStreakFreezes) ?? 0,
    );
  }

  /// 使えるXPを消費してストリーク保護を1つ交換する。成功で true。
  /// 通算XP（レベルの基準）は減らさず、使用済みXP（`spentXp`）を増やす。
  Future<bool> buyStreakFreeze() async {
    if (!state.canBuyStreakFreeze) return false;
    final newSpent = state.spentXp + GamificationConfig.streakFreezeCost;
    final newFreezes = state.streakFreezes + 1;
    state = state.copyWith(spentXp: newSpent, streakFreezes: newFreezes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keySpentXp, newSpent);
    await prefs.setInt(AppConstants.keyStreakFreezes, newFreezes);
    return true;
  }

  /// ボーナスXPを直接付与する（デイリークエストの宝箱・ユニットクリア・
  /// パーフェクトセッションなど）。通常の評価XPと同じく通算XPに積み、
  /// レベルアップも起こり得る。[addToSession] を true にすると完了画面の
  /// 「獲得XP」（sessionXp）にも合算される（パーフェクトボーナス用）。
  Future<void> grantBonusXp(int xp, {bool addToSession = false}) async {
    if (xp <= 0) return;
    final newTotal = state.snapshot.totalXp + xp;
    state = state.copyWith(
      snapshot: GamificationSnapshot.fromTotalXp(newTotal),
      sessionXp: addToSession ? state.sessionXp + xp : state.sessionXp,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyTotalXp, newTotal);
  }

  /// ストリーク保護を無償で1つ付与する（宝箱のおまけ用。上限は交換と共通）。
  Future<bool> grantStreakFreeze() async {
    if (state.streakFreezes >= GamificationConfig.maxStreakFreezes) return false;
    final newFreezes = state.streakFreezes + 1;
    state = state.copyWith(streakFreezes: newFreezes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyStreakFreezes, newFreezes);
    return true;
  }

  /// 起動時に StreakManager が保護を自動消費した後、最新値を prefs から読み直す。
  Future<void> refreshStreakFreezes() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      streakFreezes: prefs.getInt(AppConstants.keyStreakFreezes) ?? 0,
    );
  }

  /// 評価を1件反映し、演出用の結果を返す。
  /// - コンボ: 1回で正解（remembered/uncertain かつ [firstTry]）なら+1、忘れたら0。
  /// - XP: 基礎XP + コンボボーナス、FEVER中は倍率。
  /// - レベルアップ判定つき。
  Future<AnswerOutcome> registerAnswer({
    required Rating rating,
    required bool firstTry,
  }) async {
    final isCorrect = rating == Rating.remembered || rating == Rating.uncertain;
    final firstTryCorrect = isCorrect && firstTry;

    // コンボ更新
    final newCombo = rating == Rating.forgot
        ? 0
        : (firstTryCorrect ? state.combo + 1 : state.combo);
    final fever = newCombo >= GamificationConfig.feverThreshold;

    // 基礎XP
    final baseXp = switch (rating) {
      Rating.remembered => GamificationConfig.xpRemembered,
      Rating.uncertain => GamificationConfig.xpUncertain,
      Rating.forgot => GamificationConfig.xpForgot,
    };
    // コンボボーナス（連続正解数に比例・上限あり）
    final comboBonus = (newCombo * GamificationConfig.xpPerCombo)
        .clamp(0, GamificationConfig.xpComboBonusCap);
    var gained = baseXp + comboBonus;
    if (fever) gained = (gained * GamificationConfig.feverMultiplier).round();

    final beforeLevel = state.snapshot.level;
    final newTotal = state.snapshot.totalXp + gained;
    final newSnap = GamificationSnapshot.fromTotalXp(newTotal);

    state = state.copyWith(
      snapshot: newSnap,
      combo: newCombo,
      sessionXp: state.sessionXp + gained,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyTotalXp, newTotal);

    return AnswerOutcome(
      rating: rating,
      firstTryCorrect: firstTryCorrect,
      xpGained: gained,
      combo: newCombo,
      fever: fever,
      leveledUp: newSnap.level > beforeLevel,
      newLevel: newSnap.level,
    );
  }

  /// セッション開始時にコンボとセッションXPをリセットする。
  void startSession() {
    state = state.copyWith(combo: 0, sessionXp: 0);
  }
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>(
  (ref) => GamificationNotifier(),
);
