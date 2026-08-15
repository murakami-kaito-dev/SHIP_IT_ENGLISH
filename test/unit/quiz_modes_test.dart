import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/quiz.dart';

TechCard _card({
  String id = 'cr_001',
  String phrase = 'take this offline',
  String example = "Let's take this offline after the meeting.",
}) =>
    TechCard(
      id: id,
      phrase: phrase,
      translation: '別途話す',
      example: example,
      exampleTranslation: '会議のあとで別途話しましょう。',
      context: 'ctx',
      category: 'meetings',
      difficulty: 1,
      createdAt: DateTime(2026, 1, 1),
    );

List<TechCard> _distractors() => [
      _card(id: 'd1', phrase: 'ship it'),
      _card(id: 'd2', phrase: 'LGTM'),
      _card(id: 'd3', phrase: 'nit'),
    ];

void main() {
  group('quizModeFor（出題形式の決定）', () {
    test('新規カード・再出題カードは必ず flip', () {
      for (var i = 0; i < 50; i++) {
        expect(
          quizModeFor(
              cardId: 'c$i', isNewCard: true, isRetry: false, sessionSeed: i),
          QuizMode.flip,
        );
        expect(
          quizModeFor(
              cardId: 'c$i', isNewCard: false, isRetry: true, sessionSeed: i),
          QuizMode.flip,
        );
      }
    });

    test('同じシード×カードなら常に同じ形式（決定的）', () {
      for (var i = 0; i < 30; i++) {
        final a = quizModeFor(
            cardId: 'c$i', isNewCard: false, isRetry: false, sessionSeed: 42);
        final b = quizModeFor(
            cardId: 'c$i', isNewCard: false, isRetry: false, sessionSeed: 42);
        expect(a, b);
      }
    });

    test('復習カード100枚なら複数の形式が出る（単調にならない）', () {
      final modes = <QuizMode>{};
      for (var i = 0; i < 100; i++) {
        modes.add(quizModeFor(
            cardId: 'card_$i', isNewCard: false, isRetry: false, sessionSeed: 7));
      }
      expect(modes.length, greaterThanOrEqualTo(3),
          reason: '100枚で3形式以上出るはず: $modes');
    });
  });

  group('clozeExample（例文の空欄化）', () {
    test('フレーズが例文にあれば空欄に置き換える', () {
      final blanked = clozeExample(_card());
      expect(blanked, isNotNull);
      expect(blanked, isNot(contains('take this offline')));
      expect(blanked, contains('＿'));
    });

    test('大文字小文字が違っても置き換えられる', () {
      final card = _card(
          phrase: 'Take This Offline',
          example: "let's take this offline now.");
      expect(clozeExample(card), isNotNull);
    });

    test('フレーズが例文に無ければ null（choice にフォールバック）', () {
      final card = _card(example: 'A completely unrelated sentence.');
      expect(clozeExample(card), isNull);
    });
  });

  group('buildQuizQuestion（設問と選択肢）', () {
    test('選択肢は4つ・正解はちょうど1つ', () {
      final q = buildQuizQuestion(
        card: _card(),
        distractors: _distractors(),
        quizMode: QuizMode.choice,
        languageMode: LanguageMode.ja,
        sessionSeed: 1,
      );
      expect(q.options.length, QuizConfig.optionCount);
      expect(q.options.where((o) => o.correct).length, 1);
    });

    test('jaモード choice: 設問=英語フレーズ・正解=和訳', () {
      final card = _card();
      final q = buildQuizQuestion(
        card: card,
        distractors: _distractors(),
        quizMode: QuizMode.choice,
        languageMode: LanguageMode.ja,
        sessionSeed: 1,
      );
      expect(q.prompt, card.phrase);
      expect(q.options.firstWhere((o) => o.correct).text, card.translation);
    });

    test('enモード choice: 設問=和訳・正解=英語フレーズ', () {
      final card = _card();
      final q = buildQuizQuestion(
        card: card,
        distractors: _distractors(),
        quizMode: QuizMode.choice,
        languageMode: LanguageMode.en,
        sessionSeed: 1,
      );
      expect(q.prompt, card.translation);
      expect(q.options.firstWhere((o) => o.correct).text, card.phrase);
    });

    test('jaモード audio: 読み上げは英語フレーズ・設問テキストなし', () {
      final card = _card();
      final q = buildQuizQuestion(
        card: card,
        distractors: _distractors(),
        quizMode: QuizMode.audio,
        languageMode: LanguageMode.ja,
        sessionSeed: 1,
      );
      expect(q.audioText, card.phrase);
      expect(q.prompt, isNull);
    });

    test('cloze: 設問=空欄化した例文・補助=例文訳・選択肢=フレーズ', () {
      final card = _card();
      final q = buildQuizQuestion(
        card: card,
        distractors: _distractors(),
        quizMode: QuizMode.cloze,
        languageMode: LanguageMode.ja,
        sessionSeed: 1,
      );
      expect(q.prompt, contains('＿'));
      expect(q.promptCaption, card.exampleTranslation);
      expect(q.options.firstWhere((o) => o.correct).text, card.phrase);
    });

    test('選択肢の並びは同じシードで安定・正解の位置が固定でない', () {
      final card = _card();
      final a = buildQuizQuestion(
          card: card,
          distractors: _distractors(),
          quizMode: QuizMode.choice,
          languageMode: LanguageMode.ja,
          sessionSeed: 5);
      final b = buildQuizQuestion(
          card: card,
          distractors: _distractors(),
          quizMode: QuizMode.choice,
          languageMode: LanguageMode.ja,
          sessionSeed: 5);
      expect(a.options.map((o) => o.text).toList(),
          b.options.map((o) => o.text).toList());

      // 100カードぶんの正解位置がすべて同じにはならない
      final positions = <int>{};
      for (var i = 0; i < 100; i++) {
        final q = buildQuizQuestion(
            card: _card(id: 'p$i'),
            distractors: _distractors(),
            quizMode: QuizMode.choice,
            languageMode: LanguageMode.ja,
            sessionSeed: 5);
        positions.add(q.options.indexWhere((o) => o.correct));
      }
      expect(positions.length, greaterThan(1));
    });
  });
}
