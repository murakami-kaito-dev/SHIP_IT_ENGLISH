import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/services/tts_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/quiz.dart';
import 'package:ship_it_english/shared/widgets/gradient_button.dart';

/// クイズ形式の出題カード（4択・音声・穴埋め）。
/// 選択肢をタップ→正誤ハイライト＋答え合わせパネル→「つづける」で
/// [onAnswered] に正誤を返す（呼び出し側が SRS 評価に変換する）。
class QuizCard extends StatefulWidget {
  final TechCard card;
  final QuizQuestion question;
  final AppStrings strings;
  final LanguageMode mode;
  final ValueChanged<bool> onAnswered;

  const QuizCard({
    super.key,
    required this.card,
    required this.question,
    required this.strings,
    required this.mode,
    required this.onAnswered,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? _selected;

  bool get _answered => _selected != null;

  bool get _correct =>
      _selected != null && widget.question.options[_selected!].correct;

  @override
  void initState() {
    super.initState();
    // 音声クイズは表示と同時に1回再生する
    final audioText = widget.question.audioText;
    if (audioText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  void _play() {
    final audioText = widget.question.audioText;
    if (audioText != null) {
      TtsService().speakTarget(audioText, widget.mode);
    }
  }

  void _select(int index) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
  }

  String get _promptHint => switch (widget.question.mode) {
        QuizMode.choice => widget.strings.quizChoicePrompt,
        QuizMode.audio => widget.strings.quizAudioPrompt,
        QuizMode.cloze => widget.strings.quizClozePrompt,
        QuizMode.flip => '',
      };

  /// カテゴリ名タグ（FlipCard と同じ見た目のバッジ）。
  Widget _categoryTag() {
    final def = categoryDefs.firstWhere(
      (d) => d['id'] == widget.card.category,
      orElse: () => const <String, String>{},
    );
    final name = def['name'] ?? widget.card.category;
    final number =
        widget.card.cardNumber > 0 ? '  #${widget.card.cardNumber}' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$name$number',
        style: AppTheme.monoLabel.copyWith(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF7F8FE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: AppTheme.cardBorder,
        boxShadow: AppTheme.heroShadow,
      ),
      child: SingleChildScrollView(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _categoryTag()),
            const SizedBox(height: 14),
            Text(
              _promptHint,
              textAlign: TextAlign.center,
              style: AppTheme.captionText.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // --- 設問 ---
            if (q.mode == QuizMode.audio)
              Center(
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(48),
                      onTap: _play,
                      child: Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.buttonShadow,
                        ),
                        child: const Icon(Icons.volume_up_rounded,
                            size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.strings.quizTapToReplay,
                        style: AppTheme.captionText),
                  ],
                ),
              )
            else ...[
              Text(
                q.prompt ?? '',
                textAlign: TextAlign.center,
                style: q.mode == QuizMode.cloze
                    ? AppTheme.bodyText.copyWith(
                        fontStyle: FontStyle.italic, fontSize: 16, height: 1.5)
                    : AppTheme.phraseText,
              ),
              if (q.promptCaption != null) ...[
                const SizedBox(height: 8),
                Text(
                  q.promptCaption!,
                  textAlign: TextAlign.center,
                  style: AppTheme.captionText,
                ),
              ],
            ],
            const SizedBox(height: 18),
            // --- 選択肢 ---
            for (var i = 0; i < q.options.length; i++) ...[
              _OptionTile(
                text: q.options[i].text,
                state: _tileState(i),
                onTap: () => _select(i),
              ),
              const SizedBox(height: 10),
            ],
            // --- 答え合わせパネル ---
            if (_answered) ...[
              const SizedBox(height: 4),
              _AnswerPanel(
                correct: _correct,
                card: widget.card,
                strings: widget.strings,
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: widget.strings.continueButton,
                onPressed: () => widget.onAnswered(_correct),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _TileState _tileState(int index) {
    if (!_answered) return _TileState.idle;
    if (widget.question.options[index].correct) return _TileState.correct;
    if (index == _selected) return _TileState.wrong;
    return _TileState.dimmed;
  }
}

enum _TileState { idle, correct, wrong, dimmed }

/// 選択肢1つ（回答後は正解=緑・誤選択=赤・他=淡色）。
class _OptionTile extends StatelessWidget {
  final String text;
  final _TileState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (Color border, Color bg, Color fg) = switch (state) {
      _TileState.idle => (
          AppTheme.surfaceBorder,
          AppTheme.surface,
          AppTheme.textPrimary
        ),
      _TileState.correct => (
          AppTheme.ratingRemembered,
          AppTheme.ratingRemembered.withOpacity(0.10),
          AppTheme.ratingRemembered
        ),
      _TileState.wrong => (
          AppTheme.ratingForgot,
          AppTheme.ratingForgot.withOpacity(0.10),
          AppTheme.ratingForgot
        ),
      _TileState.dimmed => (
          AppTheme.surfaceBorder,
          AppTheme.surface,
          AppTheme.textTertiary
        ),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: AppTheme.bodyText.copyWith(
                    color: fg,
                    fontWeight: state == _TileState.idle
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
              ),
              if (state == _TileState.correct)
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: AppTheme.ratingRemembered),
              if (state == _TileState.wrong)
                const Icon(Icons.cancel_rounded,
                    size: 20, color: AppTheme.ratingForgot),
            ],
          ),
        ),
      ),
    );
  }
}

/// 回答後の答え合わせ（正誤メッセージ＋フレーズと意味のミニまとめ）。
class _AnswerPanel extends StatelessWidget {
  final bool correct;
  final TechCard card;
  final AppStrings strings;

  const _AnswerPanel({
    required this.correct,
    required this.card,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        correct ? AppTheme.ratingRemembered : AppTheme.ratingUncertain;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? '🎉 ${strings.quizCorrect}' : '💡 ${strings.quizWrong}',
            style: AppTheme.captionText
                .copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '"${card.phrase}"',
            style: AppTheme.bodyText.copyWith(
                fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(card.translation, style: AppTheme.bodyText),
        ],
      ),
    );
  }
}
