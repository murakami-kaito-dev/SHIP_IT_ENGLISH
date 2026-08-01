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

  const GamificationState({
    required this.snapshot,
    required this.combo,
    required this.sessionXp,
  });

  bool get fever => combo >= GamificationConfig.feverThreshold;

  GamificationState copyWith(
          {GamificationSnapshot? snapshot, int? combo, int? sessionXp}) =>
      GamificationState(
        snapshot: snapshot ?? this.snapshot,
        combo: combo ?? this.combo,
        sessionXp: sessionXp ?? this.sessionXp,
      );

  static const initial = GamificationState(
      snapshot: GamificationSnapshot.empty, combo: 0, sessionXp: 0);
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
    state = state.copyWith(snapshot: GamificationSnapshot.fromTotalXp(totalXp));
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
