import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
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
}
