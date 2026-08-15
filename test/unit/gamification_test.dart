import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

void main() {
  group('GamificationSnapshot（レベル算出）', () {
    test('XP 0 は レベル1・進捗0', () {
      final s = GamificationSnapshot.fromTotalXp(0);
      expect(s.level, 1);
      expect(s.xpIntoLevel, 0);
      expect(s.progress, 0.0);
    });

    test('レベル1に必要なXPちょうどでレベル2に上がる', () {
      final need = GamificationConfig.xpForLevel(1); // 100
      final s = GamificationSnapshot.fromTotalXp(need);
      expect(s.level, 2);
      expect(s.xpIntoLevel, 0);
    });

    test('レベルは単調増加し、レベル内進捗は必要XP未満', () {
      var prev = 1;
      for (final xp in [50, 100, 250, 500, 1000, 5000]) {
        final s = GamificationSnapshot.fromTotalXp(xp);
        expect(s.level, greaterThanOrEqualTo(prev));
        expect(s.xpIntoLevel, lessThan(s.xpForNextLevel));
        expect(s.progress, inInclusiveRange(0.0, 1.0));
        prev = s.level;
      }
    });
  });

  group('AnswerOutcome（コンボ/FEVER/XP の意味づけ）', () {
    test('isCorrect は remembered/uncertain が true、forgot が false', () {
      AnswerOutcome make(Rating r) => AnswerOutcome(
            rating: r,
            firstTryCorrect: false,
            xpGained: 0,
            combo: 0,
            fever: false,
            leveledUp: false,
            newLevel: 1,
          );
      expect(make(Rating.remembered).isCorrect, true);
      expect(make(Rating.uncertain).isCorrect, true);
      expect(make(Rating.forgot).isCorrect, false);
    });
  });

  group('GamificationConfig（チューニングの前提）', () {
    test('FEVERは5コンボ・倍率1.5', () {
      expect(GamificationConfig.feverThreshold, 5);
      expect(GamificationConfig.feverMultiplier, 1.5);
    });

    test('レベルに必要なXPはレベルが上がるほど増える', () {
      expect(GamificationConfig.xpForLevel(2),
          greaterThan(GamificationConfig.xpForLevel(1)));
    });
  });

  group('EngineerRank（称号）', () {
    test('レベルに応じて称号が上がる（帯の下限。長期目標として重めの閾値）', () {
      expect(rankForLevel(1), EngineerRank.intern);
      expect(rankForLevel(4), EngineerRank.intern);
      expect(rankForLevel(5), EngineerRank.junior);
      expect(rankForLevel(10), EngineerRank.engineer);
      expect(rankForLevel(16), EngineerRank.senior);
      expect(rankForLevel(24), EngineerRank.staff);
      expect(rankForLevel(34), EngineerRank.principal);
      expect(rankForLevel(50), EngineerRank.distinguished);
      // 閾値の直前では前の称号に留まる
      expect(rankForLevel(9), EngineerRank.junior);
      expect(rankForLevel(49), EngineerRank.principal);
    });

    test('レベルが上がると称号は後退しない（単調非減少）', () {
      var prev = -1;
      for (var lv = 1; lv <= 60; lv++) {
        final idx = rankForLevel(lv).index;
        expect(idx, greaterThanOrEqualTo(prev));
        prev = idx;
      }
    });
  });

  group('ストリーク保護の交換ゲート（GamificationState）', () {
    GamificationState state(
            {required int totalXp, int spentXp = 0, int freezes = 0}) =>
        GamificationState(
          snapshot: GamificationSnapshot.fromTotalXp(totalXp),
          combo: 0,
          sessionXp: 0,
          spentXp: spentXp,
          streakFreezes: freezes,
        );

    test('使えるXP = 通算 − 使用済み（負にはならない）', () {
      expect(state(totalXp: 500, spentXp: 200).availableXp, 300);
      expect(state(totalXp: 100, spentXp: 999).availableXp, 0);
    });

    test('残高が足りて上限未満なら交換可能', () {
      final s = state(
          totalXp: GamificationConfig.streakFreezeCost, spentXp: 0, freezes: 0);
      expect(s.canBuyStreakFreeze, true);
    });

    test('残高不足なら交換不可', () {
      final s = state(totalXp: GamificationConfig.streakFreezeCost - 1);
      expect(s.canBuyStreakFreeze, false);
    });

    test('上限に達していたら交換不可', () {
      final s = state(
          totalXp: 100000,
          spentXp: 0,
          freezes: GamificationConfig.maxStreakFreezes);
      expect(s.canBuyStreakFreeze, false);
    });
  });
}
