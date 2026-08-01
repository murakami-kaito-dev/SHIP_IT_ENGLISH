import 'package:flutter/material.dart';
import 'package:ship_it_english/core/services/sound_service.dart';

/// タップすると `scale(0.95)` にキュッと縮み、離すと Spring 物理で弾んで戻る
/// 汎用ラッパー（SKILL animation-effects「タップ＆レスポンス」）。
/// 触っていて気持ち良い操作感を全ボタン/カードに与えるための再利用部品。
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  /// タップ時にタップ音＋セレクションハプティクスを鳴らすか。
  final bool haptics;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.haptics = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    lowerBound: 0.0,
    upperBound: 1.0,
    value: 0.0,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 320),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) => _c.forward();
  // 離すときは elasticOut で弾ませて 1.0 に戻す。
  void _up(_) => _c.reverse();
  void _cancel() => _c.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? _down : null,
      onTapUp: widget.onTap != null ? _up : null,
      onTapCancel: widget.onTap != null ? _cancel : null,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptics) SoundService.instance.tap();
              widget.onTap!();
            },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // forward中は素早く縮み、reverse中は elasticOut で弾んで戻る。
          final t = _c.status == AnimationStatus.reverse ||
                  _c.status == AnimationStatus.dismissed
              ? Curves.elasticOut.transform(_c.value)
              : _c.value;
          final scale = 1.0 - (1.0 - widget.pressedScale) * t;
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
