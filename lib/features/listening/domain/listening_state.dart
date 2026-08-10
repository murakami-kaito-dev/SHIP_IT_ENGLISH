import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';

/// 1回に読み上げる1行（テキストとロケール）。英語→en-US / 日本語→ja-JP。
class SpeechLine {
  final String text;
  final String locale; // 'en-US' | 'ja-JP'

  /// 学習対象言語の行か（jaモードなら英語、enモードなら日本語）。表示強調に使う。
  final bool isTarget;

  const SpeechLine(
      {required this.text, required this.locale, required this.isTarget});
}

/// カード1枚を4行に分解する。読み上げ順は言語モードで変わる。
/// - ja（日本語話者）: タイトル英語 → タイトル日本語訳 → 例文英語 → 例文日本語訳
/// - en（英語話者）  : タイトル日本語 → タイトル英語訳 → 例文日本語 → 例文英語訳
List<SpeechLine> speechLinesFor(TechCard card, LanguageMode mode) {
  const en = 'en-US';
  const ja = 'ja-JP';
  if (mode == LanguageMode.ja) {
    return [
      SpeechLine(text: card.phrase, locale: en, isTarget: true),
      SpeechLine(text: card.translation, locale: ja, isTarget: false),
      SpeechLine(text: card.example, locale: en, isTarget: true),
      SpeechLine(text: card.exampleTranslation, locale: ja, isTarget: false),
    ];
  }
  return [
    SpeechLine(text: card.translation, locale: ja, isTarget: true),
    SpeechLine(text: card.phrase, locale: en, isTarget: false),
    SpeechLine(text: card.exampleTranslation, locale: ja, isTarget: true),
    SpeechLine(text: card.example, locale: en, isTarget: false),
  ];
}

/// 耳学プレイヤーの状態。
class ListeningState {
  final List<TechCard> queue;
  final int index; // 再生中のカード（queue内の位置）
  final int line; // 再生中の行 0..3
  final bool isPlaying;
  final bool repeat; // 繰り返しモード（最後まで行ったら先頭へ）
  final double speed; // 再生速度倍率
  final bool finished; // 繰り返しOFFで最後まで再生し終えた
  final LanguageMode mode;

  const ListeningState({
    required this.queue,
    required this.index,
    required this.line,
    required this.isPlaying,
    required this.repeat,
    required this.speed,
    required this.finished,
    required this.mode,
  });

  bool get isEmpty => queue.isEmpty;
  TechCard? get current =>
      (index >= 0 && index < queue.length) ? queue[index] : null;

  static const initial = ListeningState(
    queue: [],
    index: 0,
    line: 0,
    isPlaying: false,
    repeat: false,
    speed: 1.0,
    finished: false,
    mode: LanguageMode.ja,
  );

  ListeningState copyWith({
    List<TechCard>? queue,
    int? index,
    int? line,
    bool? isPlaying,
    bool? repeat,
    double? speed,
    bool? finished,
    LanguageMode? mode,
  }) =>
      ListeningState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        line: line ?? this.line,
        isPlaying: isPlaying ?? this.isPlaying,
        repeat: repeat ?? this.repeat,
        speed: speed ?? this.speed,
        finished: finished ?? this.finished,
        mode: mode ?? this.mode,
      );
}

/// 選べる再生速度。
const List<double> kListenSpeeds = [0.75, 1.0, 1.25, 1.5];
