import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/features/study/domain/quiz.dart';
import 'package:ship_it_english/features/study/domain/units.dart';
import 'package:ship_it_english/features/study/providers/units_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('unitsForCount（ユニット分割）', () {
    test('130枚 → 7ユニット（最後は #121–130）', () {
      final units = unitsForCount(130);
      expect(units.length, 7);
      expect(units.first, const StudyUnit(index: 1, from: 1, to: 20));
      expect(units.last, const StudyUnit(index: 7, from: 121, to: 130));
      expect(units.last.cardCount, 10);
    });

    test('ちょうど20枚 → 1ユニット', () {
      final units = unitsForCount(20);
      expect(units.length, 1);
      expect(units.single, const StudyUnit(index: 1, from: 1, to: 20));
    });

    test('0枚 → ユニットなし', () {
      expect(unitsForCount(0), isEmpty);
    });

    test('全ユニットを連結するとカード全体を過不足なく覆う', () {
      for (final total in [1, 19, 20, 21, 105, 110, 1500]) {
        final units = unitsForCount(total);
        var expectedFrom = 1;
        for (final u in units) {
          expect(u.from, expectedFrom);
          expectedFrom = u.to + 1;
        }
        expect(units.last.to, total);
      }
    });
  });

  group('unitTestPassed（合否判定）', () {
    test('許容ミス数以下ならクリア', () {
      expect(unitTestPassed(0), true);
      expect(unitTestPassed(UnitConfig.maxMistakes), true);
      expect(unitTestPassed(UnitConfig.maxMistakes + 1), false);
    });
  });

  group('unitTestModeFor（卒業テストの出題形式）', () {
    test('flip は絶対に出ない・決定的', () {
      for (var i = 0; i < 100; i++) {
        final m = unitTestModeFor(cardId: 'c$i', sessionSeed: 9);
        expect(m, isNot(QuizMode.flip));
        expect(unitTestModeFor(cardId: 'c$i', sessionSeed: 9), m);
      }
    });
  });

  group('ClearedUnitsNotifier（クリア記録の永続化）', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('markCleared で記録され、再生成で復元される', () async {
      final first = ClearedUnitsNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(first.isCleared('meetings', 2), false);

      await first.markCleared('meetings', 2);
      expect(first.isCleared('meetings', 2), true);
      expect(first.isCleared('meetings', 1), false);
      expect(first.isCleared('slack', 2), false);

      final second = ClearedUnitsNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(second.isCleared('meetings', 2), true);
    });

    test('二重 markCleared でも1件のまま', () async {
      final n = ClearedUnitsNotifier();
      await Future<void>.delayed(Duration.zero);
      await n.markCleared('meetings', 1);
      await n.markCleared('meetings', 1);
      expect(n.state.length, 1);
    });
  });
}
