import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 正解時にカード周辺から小さな粒子が弾け飛ぶ軽量パーティクル
/// （SKILL animation-effects「Particle/Sparkle」）。外部パッケージ不使用・
/// CustomPainter で十数粒だけ描くので軽い。[key] 変更で再生される。
class SparkleBurst extends StatefulWidget {
  final Color color;

  /// 粒の数（コンボが乗るほど増やすと豪華になる）。
  final int count;
  const SparkleBurst({super.key, this.color = AppTheme.ratingRemembered, this.count = 12});

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  )..forward();

  late final List<_Particle> _particles = List.generate(widget.count, (i) {
    final rnd = math.Random(i * 7 + widget.count);
    final angle = (i / widget.count) * 2 * math.pi + rnd.nextDouble() * 0.5;
    return _Particle(
      angle: angle,
      distance: 60 + rnd.nextDouble() * 70,
      size: 3 + rnd.nextDouble() * 4,
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _SparklePainter(_particles, _c.value, widget.color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  const _Particle({required this.angle, required this.distance, required this.size});
}

class _SparklePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final Color color;
  _SparklePainter(this.particles, this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOutCubic.transform(t);
    final opacity = t < 0.6 ? 1.0 : (1.0 - (t - 0.6) / 0.4);
    final paint = Paint()..color = color.withOpacity(opacity.clamp(0.0, 1.0));
    final glow = Paint()
      ..color = color.withOpacity(0.5 * opacity.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final p in particles) {
      final d = p.distance * eased;
      final pos = center + Offset(math.cos(p.angle) * d, math.sin(p.angle) * d);
      final r = p.size * (1.0 - 0.4 * eased);
      canvas.drawCircle(pos, r + 1.5, glow);
      canvas.drawCircle(pos, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}
