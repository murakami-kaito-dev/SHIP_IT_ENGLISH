import 'dart:math' as math;

import 'package:flutter/material.dart';

/// マスコットの機嫌（アニメーションの強さが変わる）。
enum DuckMood {
  /// ふわふわ上下する待機（ホーム常駐）
  idle,

  /// 今日の学習が済んでいる等、ご機嫌な弾み
  happy,

  /// セッション完了などのお祝い（大きく弾む＋わずかに揺れる）
  cheer,
}

/// ラバーダックのマスコット「ダッキー」。
///
/// エンジニア文化の「ラバーダック・デバッグ」（アヒルに説明すると頭が整理される）
/// にちなんだ、このアプリの相棒。CustomPainter によるドット絵（画像アセット不要・
/// オフライン・Terminal-grade デザインとも同居するピクセル調）で描く。
class DuckMascot extends StatefulWidget {
  final double size;
  final DuckMood mood;

  const DuckMascot({super.key, this.size = 44, this.mood = DuckMood.idle});

  @override
  State<DuckMascot> createState() => _DuckMascotState();
}

class _DuckMascotState extends State<DuckMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _durationFor(widget.mood),
  )..repeat();

  static Duration _durationFor(DuckMood mood) => switch (mood) {
        DuckMood.idle => const Duration(milliseconds: 1800),
        DuckMood.happy => const Duration(milliseconds: 800),
        DuckMood.cheer => const Duration(milliseconds: 550),
      };

  double get _amplitude => switch (widget.mood) {
        DuckMood.idle => 1.6,
        DuckMood.happy => 3.0,
        DuckMood.cheer => 4.5,
      };

  @override
  void didUpdateWidget(DuckMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _c.duration = _durationFor(widget.mood);
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 2 * math.pi;
        // 浮き沈み（cheer はわずかな首振りも加える）
        final dy = math.sin(t) * _amplitude;
        final angle =
            widget.mood == DuckMood.cheer ? math.sin(t) * 0.06 : 0.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(angle: angle, child: child),
        );
      },
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: const _DuckPainter(),
      ),
    );
  }
}

/// ドット絵のラバーダック（16×14グリッド）。
class _DuckPainter extends CustomPainter {
  const _DuckPainter();

  // '.'=透明 / Y=からだ / S=はねの影 / O=くちばし / K=目
  static const List<String> _pixels = [
    '......YYYY......',
    '.....YYYYYY.....',
    '....YYYYYYYY....',
    '....YKYYYYYY....',
    '....YYYYYYYYOO..',
    '....YYYYYYYYO...',
    '.....YYYYYY.....',
    '..Y...YYYY......',
    '.YY..YYYYYYY....',
    '.YYYYYYYYYYYY...',
    '..YYYYYYSSYYYY..',
    '...YYYYYSSYYYY..',
    '....YYYYYYYYY...',
    '......YYYYY.....',
  ];

  static const Color _yellow = Color(0xFFFFD43B);
  static const Color _shade = Color(0xFFF0B429);
  static const Color _beak = Color(0xFFFF8A3D);
  static const Color _eye = Color(0xFF2B2B33);

  @override
  void paint(Canvas canvas, Size size) {
    final cols = _pixels.first.length;
    final rows = _pixels.length;
    final cell = size.width / cols;
    // 縦方向は中央寄せ（正方形キャンバス内で 14行 < 16列 のため）
    final top = (size.height - rows * cell) / 2;
    final paint = Paint();

    for (var r = 0; r < rows; r++) {
      final row = _pixels[r];
      for (var c = 0; c < cols; c++) {
        final ch = row[c];
        if (ch == '.') continue;
        paint.color = switch (ch) {
          'Y' => _yellow,
          'S' => _shade,
          'O' => _beak,
          'K' => _eye,
          _ => _yellow,
        };
        canvas.drawRect(
          Rect.fromLTWH(c * cell, top + r * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
