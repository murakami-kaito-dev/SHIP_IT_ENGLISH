import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';

void main() {
  group('DateTimeExtension', () {
    test('toDateString() は YYYY-MM-DD 形式を返す', () {
      final dt = DateTime(2024, 3, 5);
      expect(dt.toDateString(), '2024-03-05');
    });

    test('toDateString() は月・日をゼロパディングする', () {
      final dt = DateTime(2024, 1, 9);
      expect(dt.toDateString(), '2024-01-09');
    });
  });

  group('StringDateExtension', () {
    test('daysDifferenceTo() は日数差を正の数で返す', () {
      const a = '2024-03-01';
      const b = '2024-03-03';
      expect(a.daysDifferenceTo(b), 2);
    });

    test('daysDifferenceTo() は逆順でも正の数を返す', () {
      const a = '2024-03-03';
      const b = '2024-03-01';
      expect(a.daysDifferenceTo(b), 2);
    });

    test('daysDifferenceTo() は同日なら0を返す', () {
      const a = '2024-03-01';
      expect(a.daysDifferenceTo(a), 0);
    });
  });

  group('ストリーク管理ロジック', () {
    test('1日空いた場合はストリーク継続（差分=1）', () {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toDateString();
      final today = DateTime.now().toDateString();
      final diff = today.daysDifferenceTo(yesterday);
      expect(diff, 1);
      // 差分が1ならリセットしない（diff < 2）
      expect(diff < 2, true);
    });

    test('2日空いた場合はストリークリセット（差分>=2）', () {
      final twoDaysAgo = DateTime.now()
          .subtract(const Duration(days: 2))
          .toDateString();
      final today = DateTime.now().toDateString();
      final diff = today.daysDifferenceTo(twoDaysAgo);
      expect(diff, 2);
      expect(diff >= 2, true);
    });
  });
}
