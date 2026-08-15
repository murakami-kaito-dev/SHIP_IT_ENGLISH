import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';

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

  /// 称号ランク。上がるとダッキーの見た目が進化する（帽子→メガネ→
  /// ヘッドホン→ネクタイ→王冠→王冠＋サングラス）。ドット絵の差分のみ。
  final EngineerRank rank;

  const DuckMascot({
    super.key,
    this.size = 44,
    this.mood = DuckMood.idle,
    this.rank = EngineerRank.intern,
  });

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
        painter: _DuckPainter(rank: widget.rank),
      ),
    );
  }
}

/// ドット絵のラバーダック（16×14グリッド）。称号ランクに応じた
/// アクセサリー（進化差分）を上書きで描く。
class _DuckPainter extends CustomPainter {
  final EngineerRank rank;

  const _DuckPainter({required this.rank});

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
  static const Color _blue = Color(0xFF1E88E5); // キャップ
  static const Color _gray = Color(0xFF546E7A); // ヘッドホン
  static const Color _red = Color(0xFFE53935); // ネクタイ
  static const Color _gold = Color(0xFFFFC107); // 王冠
  static const Color _white = Color(0xFFFFFFFF); // きらめき

  /// ランクごとのアクセサリー（(row, col, color) の上書きピクセル）。
  List<(int, int, Color)> get _accessory => switch (rank) {
        EngineerRank.intern => const [],
        // Junior: 青いキャップ（つばは くちばし側）
        EngineerRank.junior => const [
            (0, 6, _blue), (0, 7, _blue), (0, 8, _blue), (0, 9, _blue),
            (1, 5, _blue), (1, 6, _blue), (1, 7, _blue), (1, 8, _blue),
            (1, 9, _blue), (1, 10, _blue),
            (2, 10, _blue), (2, 11, _blue), (2, 12, _blue),
          ],
        // Engineer: 四角いゴーグル眼鏡
        EngineerRank.engineer => const [
            (2, 4, _eye), (2, 5, _eye), (2, 6, _eye),
            (3, 4, _eye), (3, 6, _eye),
            (4, 4, _eye), (4, 5, _eye), (4, 6, _eye),
          ],
        // Senior: ヘッドホン（バンド＋両パッド）
        EngineerRank.senior => const [
            (0, 5, _gray), (0, 6, _gray), (0, 7, _gray), (0, 8, _gray),
            (0, 9, _gray), (0, 10, _gray),
            (1, 4, _gray), (2, 4, _gray), (3, 4, _gray),
            (1, 11, _gray), (2, 11, _gray), (3, 11, _gray),
          ],
        // Staff: 赤いネクタイ
        EngineerRank.staff => const [
            (7, 7, _red), (8, 7, _red), (9, 7, _red), (10, 8, _red),
          ],
        // Principal: 金の王冠
        EngineerRank.principal => const [
            (0, 5, _gold), (0, 7, _gold), (0, 9, _gold),
            (1, 5, _gold), (1, 6, _gold), (1, 7, _gold), (1, 8, _gold),
            (1, 9, _gold),
          ],
        // Distinguished: 王冠＋サングラス＋きらめき
        EngineerRank.distinguished => const [
            (0, 5, _gold), (0, 7, _gold), (0, 9, _gold),
            (1, 5, _gold), (1, 6, _gold), (1, 7, _gold), (1, 8, _gold),
            (1, 9, _gold),
            (3, 4, _eye), (3, 5, _eye), (3, 6, _eye), (3, 7, _eye),
            (2, 13, _white), (5, 14, _white),
          ],
      };

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

    // ランクのアクセサリー（進化差分）を上書きで描く
    for (final (r, c, color) in _accessory) {
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(c * cell, top + r * cell, cell + 0.5, cell + 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DuckPainter oldDelegate) =>
      oldDelegate.rank != rank;
}
