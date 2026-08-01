import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// FEVER中に画面の枠がパルス発光するオーバーレイ。
/// [active] が true の間だけ、内側に向かって脈打つグローを描く。非インタラクティブ。
class FeverFrame extends StatefulWidget {
  final bool active;
  const FeverFrame({super.key, required this.active});

  @override
  State<FeverFrame> createState() => _FeverFrameState();
}

class _FeverFrameState extends State<FeverFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant FeverFrame old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = 0.35 + 0.65 * _c.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  AppTheme.streakFire.withOpacity(0.02 * t),
                  AppTheme.streakFire.withOpacity(0.20 * t),
                ],
                stops: const [0.72, 0.9, 1.0],
              ),
              border: Border.all(
                color: AppTheme.streakFire.withOpacity(0.55 * t),
                width: 3,
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
