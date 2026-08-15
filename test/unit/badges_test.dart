import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/features/gamification/domain/badges.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/providers/badges_providers.dart';

BadgeInput _input({
  int streak = 0,
  int studied = 0,
  int units = 0,
  int perfect = 0,
  int level = 1,
}) =>
    BadgeInput(
      streak: streak,
      studied: studied,
      unitsCleared: units,
      perfectCount: perfect,
      level: level,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('バッジ定義の健全性', () {
    test('idは一意', () {
      final ids = allBadges.map((b) => b.id).toSet();
      expect(ids.length, allBadges.length);
    });

    test('称号バッジの閾値は rankForLevel の閾値と同期している', () {
      // 各称号バッジのレベル閾値で、ちょうどその称号に到達していること
      expect(rankForLevel(5), EngineerRank.junior);
      expect(rankForLevel(10), EngineerRank.engineer);
      expect(rankForLevel(16), EngineerRank.senior);
      expect(rankForLevel(24), EngineerRank.staff);
      expect(rankForLevel(34), EngineerRank.principal);
      expect(rankForLevel(50), EngineerRank.distinguished);
      final rankThresholds = allBadges
          .where((b) => b.kind == BadgeKind.rank)
          .map((b) => b.threshold)
          .toList();
      expect(rankThresholds, [5, 10, 16, 24, 34, 50]);
    });
  });

  group('isBadgeEarned / newlyEarnedBadges', () {
    test('しきい値ちょうどで獲得・未満は未獲得', () {
      final streak3 = allBadges.firstWhere((b) => b.id == 'streak_3');
      expect(isBadgeEarned(streak3, _input(streak: 3)), true);
      expect(isBadgeEarned(streak3, _input(streak: 2)), false);
    });

    test('新規獲得は未獲得のものだけ返す', () {
      final input = _input(streak: 7, studied: 100, perfect: 1);
      final newly = newlyEarnedBadges(input, {'streak_3'});
      final ids = newly.map((b) => b.id).toList();
      expect(ids, containsAll(['streak_7', 'studied_100', 'perfect_1']));
      expect(ids, isNot(contains('streak_3'))); // 獲得済みは含めない
      expect(ids, isNot(contains('streak_30'))); // 条件未達は含めない
    });

    test('何も達していなければ空', () {
      expect(newlyEarnedBadges(_input(), {}), isEmpty);
    });
  });

  group('EarnedBadgesNotifier（永続化）', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('checkAndAward で記録され、再生成で復元・重複付与しない', () async {
      final first = EarnedBadgesNotifier();
      await Future<void>.delayed(Duration.zero);

      final newly = await first.checkAndAward(_input(streak: 3));
      expect(newly.map((b) => b.id), ['streak_3']);
      expect(first.state.keys, contains('streak_3'));

      // 同じ条件で再判定しても二重に付与しない
      expect(await first.checkAndAward(_input(streak: 3)), isEmpty);

      // 再生成（アプリ再起動相当）で復元される
      final second = EarnedBadgesNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(second.state.keys, contains('streak_3'));
    });
  });
}
