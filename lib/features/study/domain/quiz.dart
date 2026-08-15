import 'dart:math';

import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';

/// 学習セッションでの出題形式。
/// 毎回同じ「めくって自己評価」だけだと単調で飽きるため、復習カードには
/// 客観テスト（4択・音声・穴埋め）を混ぜる。新規カード・再出題カードは
/// 必ず flip（まず学ぶ／学び直す）。
enum QuizMode {
  /// フリップカード＋自己評価（従来の形式）
  flip,

  /// 4択：フレーズ → 意味を選ぶ
  choice,

  /// 音声：発音を聴いて意味を選ぶ（同梱音声を活用）
  audio,

  /// 穴埋め：例文の空欄に入るフレーズを選ぶ
  cloze,
}

/// 出題形式のチューニング値。
class QuizConfig {
  /// 復習カードに占める各形式のおおよその割合（%）。残りが cloze。
  static const int flipPercent = 40;
  static const int choicePercent = 25; // 40..65
  static const int audioPercent = 20; // 65..85

  /// クイズの選択肢数（正解1＋誤答3）。
  static const int optionCount = 4;
  static const int distractorCount = optionCount - 1;
}

/// このカードの出題形式を決める（セッション内で決定的＝リビルドで変わらない）。
/// - 新規カード（初見）と再出題（忘れた後）: 必ず flip
/// - 復習カード: セッションシード×cardId から抽選
QuizMode quizModeFor({
  required String cardId,
  required bool isNewCard,
  required bool isRetry,
  required int sessionSeed,
}) {
  if (isNewCard || isRetry) return QuizMode.flip;
  final roll = Random(sessionSeed ^ cardId.hashCode).nextInt(100);
  if (roll < QuizConfig.flipPercent) return QuizMode.flip;
  if (roll < QuizConfig.flipPercent + QuizConfig.choicePercent) {
    return QuizMode.choice;
  }
  if (roll <
      QuizConfig.flipPercent +
          QuizConfig.choicePercent +
          QuizConfig.audioPercent) {
    return QuizMode.audio;
  }
  return QuizMode.cloze;
}

/// ユニットテスト（卒業テスト）用の出題形式。**flip は出さず必ずクイズ**
/// （客観テストで合否を判定するため）。抽選はセッション内決定的。
QuizMode unitTestModeFor({required String cardId, required int sessionSeed}) {
  const modes = [QuizMode.choice, QuizMode.audio, QuizMode.cloze];
  return modes[Random(sessionSeed ^ cardId.hashCode ^ 0x5eed)
      .nextInt(modes.length)];
}

/// 例文からフレーズを空欄化したテキストを返す。
/// フレーズが例文に（大文字小文字を無視して）現れない場合は null
/// （呼び出し側は choice にフォールバックする）。
String? clozeExample(TechCard card) {
  final example = card.example;
  final idx = example.toLowerCase().indexOf(card.phrase.toLowerCase());
  if (idx < 0) return null;
  return example.replaceRange(idx, idx + card.phrase.length, '＿＿＿＿');
}

/// クイズの選択肢1つ。
class QuizOption {
  final String text;
  final bool correct;

  const QuizOption({required this.text, required this.correct});
}

/// 1問ぶんのクイズ（設問＋選択肢）。UIはこれを描画するだけにする。
class QuizQuestion {
  final QuizMode mode;

  /// 設問テキスト（choice=学習対象言語のフレーズ / cloze=空欄化した例文）。
  /// audio では null（音声が設問）。
  final String? prompt;

  /// cloze の補助（例文の訳）。答えの手がかりとして表示する。
  final String? promptCaption;

  /// audio で読み上げるテキスト（speakTarget に渡す＝学習対象言語）。
  final String? audioText;

  final List<QuizOption> options;

  const QuizQuestion({
    required this.mode,
    required this.prompt,
    required this.promptCaption,
    required this.audioText,
    required this.options,
  });
}

/// カード＋誤答カード3枚からクイズを組み立てる（選択肢順は決定的シャッフル）。
///
/// 言語モードによる向き:
/// - ja（日本語話者）: 設問=英語（フレーズ/音声）→ 選択肢=和訳
/// - en（英語話者）: 設問=日本語（和訳/音声）→ 選択肢=英語フレーズ
/// - cloze は英語例文の穴埋め（jaモードのみ。enモードは呼び出し側で choice に
///   フォールバックする）
QuizQuestion buildQuizQuestion({
  required TechCard card,
  required List<TechCard> distractors,
  required QuizMode quizMode,
  required LanguageMode languageMode,
  required int sessionSeed,
}) {
  assert(quizMode != QuizMode.flip, 'flip はクイズではない');
  final ja = languageMode == LanguageMode.ja;

  // 選択肢のテキスト（ユーザーの母語側。cloze だけはフレーズそのもの）
  String optionText(TechCard c) => switch (quizMode) {
        QuizMode.cloze => c.phrase,
        _ => ja ? c.translation : c.phrase,
      };

  final options = <QuizOption>[
    QuizOption(text: optionText(card), correct: true),
    for (final d in distractors.take(QuizConfig.distractorCount))
      QuizOption(text: optionText(d), correct: false),
  ]..shuffle(Random(sessionSeed ^ card.id.hashCode));

  return switch (quizMode) {
    QuizMode.choice => QuizQuestion(
        mode: quizMode,
        prompt: ja ? card.phrase : card.translation,
        promptCaption: null,
        audioText: null,
        options: options,
      ),
    QuizMode.audio => QuizQuestion(
        mode: quizMode,
        prompt: null,
        promptCaption: null,
        // speakTarget と同じ向き（ja→英語フレーズ / en→和訳）
        audioText: ja ? card.phrase : card.translation,
        options: options,
      ),
    QuizMode.cloze => QuizQuestion(
        mode: quizMode,
        prompt: clozeExample(card),
        promptCaption: card.exampleTranslation,
        audioText: null,
        options: options,
      ),
    QuizMode.flip => throw StateError('unreachable'),
  };
}
