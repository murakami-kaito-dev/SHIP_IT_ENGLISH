import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 「+10 XP」がふわっと浮き上がって消える演出（SKILL gamification「XP獲得演出」）。
/// [key] を変えるたびに再生される（study_screen が effectTick で作り直す）。
class XpGainPopup extends StatefulWidget {
  final int amount;
  final bool fever;
  const XpGainPopup({super.key, required this.amount, required this.fever});

  @override
  State<XpGainPopup> createState() => _XpGainPopupState();
}

class _XpGainPopupState extends State<XpGainPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.fever ? AppTheme.streakFire : AppTheme.ratingRemembered;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // 立ち上がりで軽くオーバーシュート → 上昇しながらフェードアウト。
          final rise = Curves.easeOutQuart.transform(t) * 46;
          final opacity = t < 0.15
              ? t / 0.15
              : (t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3));
          final scale = 0.7 + 0.3 * Curves.elasticOut.transform(t.clamp(0, 1));
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -rise),
              child: Transform.scale(
                scale: scale,
                child: Text(
                  '+${widget.amount} XP',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                    shadows: [
                      Shadow(color: color.withOpacity(0.6), blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
