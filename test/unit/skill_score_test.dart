import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:ship_it_english/features/study/domain/skill_score.dart';

void main() {
  group('SkillScore（技術英語カバレッジ）', () {
    test('全カード未学習なら 0%', () {
      const s = SkillScore(
          newCount: 100, learningCount: 0, reviewCount: 0, masteredCount: 0);
      expect(s.percent, 0);
      expect(s.display, '0.0');
    });

    test('全カード習得済みなら 100%', () {
      const s = SkillScore(
          newCount: 0, learningCount: 0, reviewCount: 0, masteredCount: 50);
      expect(s.percent, 100);
      expect(s.display, '100.0');
    });

    test('重み付き（learning=0.25 / review=0.6 / mastered=1.0）', () {
      // 100枚中: learning 20枚 + review 10枚 + mastered 10枚
      const s = SkillScore(
          newCount: 60, learningCount: 20, reviewCount: 10, masteredCount: 10);
      // (20*0.25 + 10*0.6 + 10*1.0) / 100 * 100 = 21.0
      expect(s.percent, closeTo(21.0, 0.001));
      expect(s.display, '21.0');
    });

    test('カード0枚でもゼロ除算しない', () {
      expect(SkillScore.empty.percent, 0);
    });

    test('studiedCount は new 以外の合計', () {
      const s = SkillScore(
          newCount: 5, learningCount: 1, reviewCount: 2, masteredCount: 3);
      expect(s.studiedCount, 6);
      expect(s.totalCount, 11);
    });
  });

  group('placementKnownProgress（初期診断の「知ってる」）', () {
    test('復習状態・間隔7日・次回復習は7日後・評価=覚えてた', () {
      final now = DateTime(2026, 8, 15, 10);
      final p = placementKnownProgress('cr_001', now);
      expect(p.cardId, 'cr_001');
      expect(p.status, CardStatus.review);
      expect(p.intervalDays, SkillScoreConfig.placementKnownIntervalDays);
      expect(p.repetitions, 1);
      expect(p.nextReview, now.add(const Duration(days: 7)));
      expect(p.lastReviewed, now);
      expect(p.lastRating, Rating.remembered);
    });
  });
}
