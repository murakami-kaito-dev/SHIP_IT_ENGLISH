import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/features/gamification/domain/quests.dart';
import 'package:ship_it_english/features/gamification/providers/quests_providers.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('questsForDate（日替わり生成）', () {
    test('同じ日付なら常に同じ3クエスト（決定的）', () {
      final date = DateTime(2026, 8, 15);
      final a = questsForDate(date);
      final b = questsForDate(date);
      expect(a, b);
      expect(a.length, QuestConfig.questsPerDay);
    });

    test('1つ目は必ず「N枚学習」クエスト', () {
      for (var day = 1; day <= 28; day++) {
        final quests = questsForDate(DateTime(2026, 9, day));
        expect(quests.first.type, QuestType.studyCards);
        expect(QuestConfig.studyTargets, contains(quests.first.target));
      }
    });

    test('種類は重複しない・目標値は候補リストの範囲内', () {
      for (var day = 1; day <= 28; day++) {
        final quests = questsForDate(DateTime(2026, 10, day));
        final types = quests.map((q) => q.type).toSet();
        expect(types.length, quests.length, reason: '種類が重複している');
        for (final q in quests) {
          final targets = switch (q.type) {
            QuestType.studyCards => QuestConfig.studyTargets,
            QuestType.comboReach => QuestConfig.comboTargets,
            QuestType.remembered => QuestConfig.rememberedTargets,
            QuestType.listenLines => QuestConfig.listenTargets,
          };
          expect(targets, contains(q.target));
        }
      }
    });
  });

  group('QuestProgress（進捗判定）', () {
    const quest = Quest(type: QuestType.studyCards, target: 10);

    test('目標到達で isDone', () {
      const p = QuestProgress(date: '2026-08-15', studied: 10);
      expect(p.isDone(quest), true);
      expect(
          const QuestProgress(date: '2026-08-15', studied: 9).isDone(quest),
          false);
    });

    test('JSON往復で値が保たれる', () {
      const p = QuestProgress(
        date: '2026-08-15',
        studied: 5,
        comboMax: 3,
        remembered: 2,
        listenLines: 7,
        chestClaimed: true,
        claimedXp: 42,
      );
      final restored = QuestProgress.fromJson(p.toJson());
      expect(restored.date, p.date);
      expect(restored.studied, p.studied);
      expect(restored.comboMax, p.comboMax);
      expect(restored.remembered, p.remembered);
      expect(restored.listenLines, p.listenLines);
      expect(restored.chestClaimed, p.chestClaimed);
      expect(restored.claimedXp, p.claimedXp);
    });
  });

  group('rollChestReward（宝箱の可変報酬）', () {
    test('XPは範囲内・凍結は不可なら絶対に出ない', () {
      for (var i = 0; i < 200; i++) {
        final r = rollChestReward(canGrantFreeze: false, rng: Random(i));
        expect(r.xp, inInclusiveRange(QuestConfig.chestXpMin, QuestConfig.chestXpMax));
        expect(r.streakFreeze, false);
      }
    });

    test('凍結可なら一定確率で出る（200回で少なくとも1回）', () {
      var any = false;
      for (var i = 0; i < 200; i++) {
        if (rollChestReward(canGrantFreeze: true, rng: Random(i)).streakFreeze) {
          any = true;
          break;
        }
      }
      expect(any, true);
    });
  });

  group('QuestsNotifier（記録・宝箱・日付切替）', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('recordAnswer で学習数・覚えてた数・コンボ最大値が進む', () async {
      final notifier = QuestsNotifier(now: () => DateTime(2026, 8, 15, 10));
      await notifier.recordAnswer(rating: Rating.remembered, combo: 1);
      await notifier.recordAnswer(rating: Rating.uncertain, combo: 2);
      await notifier.recordAnswer(rating: Rating.forgot, combo: 0);
      final p = notifier.state.progress;
      expect(p.studied, 3);
      expect(p.remembered, 1);
      expect(p.comboMax, 2);
    });

    test('宝箱は全達成まで開かず、達成後は一度だけ開く', () async {
      final notifier = QuestsNotifier(now: () => DateTime(2026, 8, 15, 10));
      expect(
          await notifier.claimChest(canGrantFreeze: false, rng: Random(1)),
          isNull);

      // 全クエストを強制的に満たす（最大目標値まで記録）
      for (var i = 0; i < 30; i++) {
        await notifier.recordAnswer(rating: Rating.remembered, combo: i + 1);
      }
      for (var i = 0; i < 20; i++) {
        await notifier.recordListenLine();
      }
      expect(notifier.state.allDone, true);

      final reward =
          await notifier.claimChest(canGrantFreeze: false, rng: Random(1));
      expect(reward, isNotNull);
      expect(notifier.state.progress.chestClaimed, true);
      expect(notifier.state.progress.claimedXp, reward!.xp);

      // 2回目は開かない
      expect(
          await notifier.claimChest(canGrantFreeze: false, rng: Random(2)),
          isNull);
    });

    test('日付が変わると進捗がリセットされ新しいクエストになる', () async {
      var current = DateTime(2026, 8, 15, 23);
      final notifier = QuestsNotifier(now: () => current);
      await notifier.recordAnswer(rating: Rating.remembered, combo: 1);
      expect(notifier.state.progress.studied, 1);

      current = DateTime(2026, 8, 16, 0, 5);
      notifier.ensureToday();
      expect(notifier.state.progress.studied, 0);
      expect(notifier.state.progress.date, '2026-08-16');
      expect(notifier.state.quests, questsForDate(current));
    });

    test('同日の再起動で進捗が復元される', () async {
      final now = DateTime(2026, 8, 15, 12);
      final first = QuestsNotifier(now: () => now);
      await first.recordAnswer(rating: Rating.remembered, combo: 1);
      await first.recordListenLine();

      final second = QuestsNotifier(now: () => now);
      // _load は非同期なので1フレーム待つ
      await Future<void>.delayed(Duration.zero);
      expect(second.state.progress.studied, 1);
      expect(second.state.progress.listenLines, 1);
    });
  });
}
