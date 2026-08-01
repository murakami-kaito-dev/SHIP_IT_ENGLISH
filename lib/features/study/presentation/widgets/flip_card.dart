import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/services/tts_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';

/// フリップカード。言語モードによって裏面の構成が変わる。
/// - ja: 表=英語フレーズ → 裏=和訳・例文・使用場面（日本語）
/// - en: 表=英語フレーズ → 裏=日本語表現（学習対象）・例文・使用場面（英語）
class FlipCard extends StatefulWidget {
  final TechCard card;
  final bool isFlipped;
  final LanguageMode mode;
  final VoidCallback onFlip;

  const FlipCard({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.mode,
    required this.onFlip,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  AppStrings get _strings => AppStrings.of(widget.mode);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.flipDuration,
    );
    _animation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    // カードが変わったらアニメーションリセット
    if (widget.card.id != oldWidget.card.id) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    TtsService().stop();
    _controller.dispose();
    super.dispose();
  }

  void _speak(String text) {
    TtsService().speakTarget(text, widget.mode);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isFlipped
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onFlip();
            },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value;
          final isShowingBack = angle > math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isShowingBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  )
                : _buildFront(),
          );
        },
      ),
    );
  }

  /// カテゴリ名と通し番号を「Git / CI/CD  #15」形式のタグとして描く。
  /// セクションの表示名（categoryDefs の name）を使い、以前の "// ..." の
  /// コメント風プレフィックスは付けない。
  Widget _fileTag() {
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

  Widget _buildFront() {
    return Semantics(
      label: 'Card front: ${widget.card.phrase}',
      child: Container(
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
        padding: AppTheme.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _fileTag(),
            const SizedBox(height: 26),
            Text(
              '“${widget.card.phrase}”',
              style: AppTheme.phraseText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            // めくり操作のさりげないヒント（下向きシェブロン）
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textTertiary.withOpacity(0.6),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    final isJa = widget.mode == LanguageMode.ja;
    final card = widget.card;

    // 学習対象（音声読み上げの対象でもある）
    final answerText = card.translation;
    // 例文: jaモードは英語例文がメイン、enモードは日本語例文訳がメイン
    final mainExample = isJa ? card.example : card.exampleTranslation;
    final subExample = isJa ? card.exampleTranslation : card.example;
    final usage = isJa
        ? card.context
        : (card.contextEn.isNotEmpty ? card.contextEn : card.context);

    return Semantics(
      label: 'Card back: ${card.translation}',
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          border: AppTheme.cardBorder,
          boxShadow: AppTheme.heroShadow,
        ),
        child: SingleChildScrollView(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fileTag(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '"${card.phrase}"',
                      style: AppTheme.bodyText
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                  if (isJa)
                    _SpeakerButton(onTap: () => _speak(card.phrase)),
                ],
              ),
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(answerText, style: AppTheme.translationText),
                  ),
                  if (!isJa)
                    _SpeakerButton(onTap: () => _speak(answerText)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _strings.exampleLabel,
                style: AppTheme.captionText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      isJa ? '"$mainExample"' : mainExample,
                      style: AppTheme.bodyText
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                  _SpeakerButton(
                    onTap: () =>
                        _speak(isJa ? card.example : card.exampleTranslation),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subExample, style: AppTheme.bodyText),
              const SizedBox(height: 20),
              Text(
                _strings.usageLabel,
                style: AppTheme.captionText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(usage, style: AppTheme.bodyText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SpeakerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Play audio',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.volume_up_outlined,
            size: 22,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
