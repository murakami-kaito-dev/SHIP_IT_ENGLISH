import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/study/domain/skill_score.dart';

/// 「技術英語カバレッジ」カード。
/// XP（努力量）とは別の**実力の単一スコア**をリングゲージで見せる。
/// 続けるとこの数字が上がる＝上達の実感が継続の動機になる。
class SkillScoreCard extends StatelessWidget {
  final SkillScore score;
  final AppStrings strings;

  const SkillScoreCard({super.key, required this.score, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // リングゲージ＋中央の%（実力を1つの数字で示す主役）
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _RingPainter(progress: score.percent / 100),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.display,
                      style: AppTheme.monoNumberLarge.copyWith(
                        fontSize: 22,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text('%',
                        style: AppTheme.monoLabel
                            .copyWith(color: AppTheme.textTertiary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.skillScoreTitle,
                  style:
                      AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(strings.skillScoreCaption, style: AppTheme.captionText),
                const SizedBox(height: 10),
                Text(
                  strings.studiedOf(score.studiedCount, score.totalCount),
                  style: AppTheme.monoLabel,
                ),
                const SizedBox(height: 2),
                Text(
                  strings.masteredCountLabel(score.masteredCount),
                  style:
                      AppTheme.monoLabel.copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// スコアのリングゲージ（背景の淡い環＋primaryの進捗弧）。
class _RingPainter extends CustomPainter {
  final double progress;

  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.primaryLight;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped > 0) {
      final fg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryGlow],
        ).createShader(rect);
      // 12時の位置から時計回りに
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * clamped, false, fg);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
