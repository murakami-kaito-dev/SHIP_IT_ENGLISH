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
/// にちなんだ、このアプリの相棒。本体は滑らかなイラスト
/// （assets/images/ducky.png。マスターは assets/icon/app_icon_master.svg）で、
/// 称号ランクのアクセサリーだけを CustomPainter のベクター描画で上書きする。
/// 旧ドット絵版は git 履歴（feat/design-h-screens 以前）参照。
class DuckMascot extends StatefulWidget {
  final double size;
  final DuckMood mood;

  /// 称号ランク。上がるとダッキーの見た目が進化する（帽子→メガネ→
  /// ヘッドホン→ネクタイ→王冠→王冠＋サングラス）。
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
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ducky.png',
              filterQuality: FilterQuality.medium,
            ),
            if (widget.rank != EngineerRank.intern)
              CustomPaint(painter: _AccessoryPainter(rank: widget.rank)),
          ],
        ),
      ),
    );
  }
}

/// ランクのアクセサリー（進化差分）を、ダッキー画像の上にベクターで描く。
///
/// 座標はすべて元イラスト（1024×1024 viewBox）に対する正規化値。
/// 目安: 頭の中心 (0.51, 0.31)・頭の上端 y≈0.145・目の中心 (0.62, 0.30)・
/// くちばしの付け根 (0.72, 0.36)・胸の前面 (0.60, 0.55)。
class _AccessoryPainter extends CustomPainter {
  final EngineerRank rank;

  const _AccessoryPainter({required this.rank});

  static const Color _blue = Color(0xFF1E88E5); // キャップ
  static const Color _blueDark = Color(0xFF1565C0); // キャップのつば
  static const Color _dark = Color(0xFF2D2C32); // ゴーグル・サングラス
  static const Color _gray = Color(0xFF546E7A); // ヘッドホン
  static const Color _red = Color(0xFFE53935); // ネクタイ
  static const Color _redDark = Color(0xFFC62828); // ネクタイの結び目
  static const Color _gold = Color(0xFFFFC107); // 王冠
  static const Color _white = Color(0xFFFFFFFF); // きらめき

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    double x(double v) => v * s;
    double y(double v) => v * s;
    final paint = Paint()..isAntiAlias = true;

    switch (rank) {
      case EngineerRank.intern:
        break;

      case EngineerRank.junior:
        // 青いキャップ（頭頂のドーム＋くちばし側のつば）
        paint
          ..style = PaintingStyle.fill
          ..color = _blue;
        final dome = Path()
          ..moveTo(x(0.335), y(0.235))
          ..quadraticBezierTo(x(0.36), y(0.09), x(0.53), y(0.10))
          ..quadraticBezierTo(x(0.67), y(0.11), x(0.685), y(0.225))
          ..close();
        canvas.drawPath(dome, paint);
        paint.color = _blueDark;
        canvas.drawRRect(
          RRect.fromLTRBR(
              x(0.60), y(0.195), x(0.80), y(0.245), Radius.circular(s * 0.02)),
          paint,
        );
        break;

      case EngineerRank.engineer:
        // 四角いゴーグル眼鏡（目を囲む枠＋後頭部へのバンド）
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.028
          ..color = _dark;
        canvas.drawRRect(
          RRect.fromLTRBR(
              x(0.545), y(0.235), x(0.715), y(0.375), Radius.circular(s * 0.045)),
          paint,
        );
        canvas.drawLine(Offset(x(0.545), y(0.30)), Offset(x(0.33), y(0.28)),
            paint..strokeWidth = s * 0.022);
        break;

      case EngineerRank.senior:
        // ヘッドホン（頭上のバンド＋両側のパッド）
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..color = _gray;
        final band = Path()
          ..moveTo(x(0.345), y(0.30))
          ..quadraticBezierTo(x(0.49), y(0.055), x(0.665), y(0.27));
        canvas.drawPath(band, paint);
        paint.style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromLTRBR(
              x(0.315), y(0.265), x(0.385), y(0.375), Radius.circular(s * 0.025)),
          paint,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(
              x(0.635), y(0.245), x(0.705), y(0.355), Radius.circular(s * 0.025)),
          paint,
        );
        break;

      case EngineerRank.staff:
        // 赤いネクタイ（胸元の結び目＋下に伸びるタイ）
        paint
          ..style = PaintingStyle.fill
          ..color = _redDark;
        final knot = Path()
          ..moveTo(x(0.585), y(0.525))
          ..lineTo(x(0.645), y(0.535))
          ..lineTo(x(0.625), y(0.585))
          ..lineTo(x(0.575), y(0.575))
          ..close();
        canvas.drawPath(knot, paint);
        paint.color = _red;
        final tie = Path()
          ..moveTo(x(0.585), y(0.575))
          ..lineTo(x(0.635), y(0.585))
          ..lineTo(x(0.615), y(0.71))
          ..lineTo(x(0.565), y(0.69))
          ..close();
        canvas.drawPath(tie, paint);
        break;

      case EngineerRank.principal:
        _drawCrown(canvas, s, paint);
        break;

      case EngineerRank.distinguished:
        _drawCrown(canvas, s, paint);
        // サングラス（目を覆う濃色バー）
        paint
          ..style = PaintingStyle.fill
          ..color = _dark;
        canvas.drawRRect(
          RRect.fromLTRBR(
              x(0.535), y(0.26), x(0.725), y(0.35), Radius.circular(s * 0.03)),
          paint,
        );
        canvas.drawLine(
          Offset(x(0.535), y(0.29)),
          Offset(x(0.345), y(0.275)),
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.02,
        );
        // きらめき（白の4点スター）
        paint.style = PaintingStyle.fill;
        _drawSparkle(canvas, Offset(x(0.85), y(0.17)), s * 0.045, paint);
        _drawSparkle(canvas, Offset(x(0.77), y(0.075)), s * 0.03, paint);
        break;
    }
  }

  void _drawCrown(Canvas canvas, double s, Paint paint) {
    double x(double v) => v * s;
    double y(double v) => v * s;
    paint
      ..style = PaintingStyle.fill
      ..color = _gold;
    final crown = Path()
      ..moveTo(x(0.40), y(0.155))
      ..lineTo(x(0.415), y(0.045))
      ..lineTo(x(0.475), y(0.105))
      ..lineTo(x(0.525), y(0.025))
      ..lineTo(x(0.575), y(0.10))
      ..lineTo(x(0.63), y(0.04))
      ..lineTo(x(0.64), y(0.15))
      ..close();
    canvas.drawPath(crown, paint);
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    paint.color = _white;
    final star = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy - r * 0.18, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy + r * 0.18, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy + r * 0.18, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy - r * 0.18, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(covariant _AccessoryPainter oldDelegate) =>
      oldDelegate.rank != rank;
}
