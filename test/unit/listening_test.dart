import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/features/listening/domain/listening_state.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';

TechCard _card() => TechCard(
      id: 'x1',
      phrase: 'Ship it',
      translation: 'リリースしよう',
      example: 'Let us ship it today.',
      exampleTranslation: '今日リリースしよう。',
      context: 'ctx',
      category: 'code_review',
      difficulty: 1,
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  group('speechLinesFor（1枚=4行の読み上げ順）', () {
    test('日本語モード: 英語→日本語→英語例文→日本語例文', () {
      final lines = speechLinesFor(_card(), LanguageMode.ja);
      expect(lines.map((l) => l.text).toList(), [
        'Ship it',
        'リリースしよう',
        'Let us ship it today.',
        '今日リリースしよう。',
      ]);
      expect(lines.map((l) => l.locale).toList(),
          ['en-US', 'ja-JP', 'en-US', 'ja-JP']);
      // 学習対象（強調）は英語側
      expect(lines.map((l) => l.isTarget).toList(),
          [true, false, true, false]);
    });

    test('英語モード: 日本語→英語→日本語例文→英語例文', () {
      final lines = speechLinesFor(_card(), LanguageMode.en);
      expect(lines.map((l) => l.text).toList(), [
        'リリースしよう',
        'Ship it',
        '今日リリースしよう。',
        'Let us ship it today.',
      ]);
      expect(lines.map((l) => l.locale).toList(),
          ['ja-JP', 'en-US', 'ja-JP', 'en-US']);
      // 学習対象（強調）は日本語側
      expect(lines.map((l) => l.isTarget).toList(),
          [true, false, true, false]);
    });
  });

  group('lineAtGlobal（カード全体の秒→行変換）', () {
    // 各行 1000ms（合計4000ms）
    final durs = List.filled(4, const Duration(milliseconds: 1000));

    test('先頭は行0・オフセット0', () {
      final r = lineAtGlobal(durs, Duration.zero);
      expect(r.line, 0);
      expect(r.offset, Duration.zero);
    });

    test('行の途中はその行＋行内オフセット', () {
      final r = lineAtGlobal(durs, const Duration(milliseconds: 2500));
      expect(r.line, 2);
      expect(r.offset, const Duration(milliseconds: 500));
    });

    test('境界ちょうどは次の行の頭', () {
      final r = lineAtGlobal(durs, const Duration(milliseconds: 2000));
      expect(r.line, 2);
      expect(r.offset, Duration.zero);
    });

    test('総和を超えたら最終行の末尾に丸める', () {
      final r = lineAtGlobal(durs, const Duration(milliseconds: 99999));
      expect(r.line, 3);
      expect(r.offset, const Duration(milliseconds: 1000));
    });

    test('負値は先頭に丸める', () {
      final r = lineAtGlobal(durs, const Duration(milliseconds: -500));
      expect(r.line, 0);
      expect(r.offset, Duration.zero);
    });
  });

  group('ListeningState', () {
    test('初期状態は空・停止・1.0倍', () {
      const s = ListeningState.initial;
      expect(s.isEmpty, true);
      expect(s.isPlaying, false);
      expect(s.speed, 1.0);
      expect(s.repeat, false);
      expect(s.current, isNull);
    });

    test('current は index の位置のカードを返す', () {
      final s = ListeningState.initial.copyWith(queue: [_card()], index: 0);
      expect(s.current?.id, 'x1');
    });
  });
}
