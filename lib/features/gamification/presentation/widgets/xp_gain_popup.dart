import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 「+12 XP」がカード付近から立ち上がり、**画面上部のXPバーへ吸い込まれる**演出。
///
/// もとはその場でふわっと消えるだけだったため、獲得したXPとゲージの増加が
/// 結びついて見えなかった。バーまで飛ばして吸い込ませることで「answer → XP →
/// ゲージが伸びる」という因果を目に見せる（SKILL gamification「XP獲得演出」）。
///
/// [key] を変えるたびに再生される（study_screen が effectTick で作り直す）。
/// 親を `Positioned.fill` にして使うこと（内部で縦位置を動かすため）。
class XpFlyToBar extends StatefulWidget {
  final int amount;
  final bool fever;

  /// 飛び始めの縦位置（body 座標）。カードの上端付近を想定。
  final double startTop;

  /// 飛び終わりの縦位置（body 座標）。XPバーの中心を想定。
  final double endTop;

  const XpFlyToBar({
    super.key,
    required this.amount,
    required this.fever,
    this.startTop = 190,
    this.endTop = 26,
  });

  @override
  State<XpFlyToBar> createState() => _XpFlyToBarState();
}

class _XpFlyToBarState extends State<XpFlyToBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
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

          // 前半: その場でポップして存在を主張する（獲得の実感）。
          // 後半: バーへ向かって加速しながら縮み、到達と同時に消える（吸い込み）。
          const popEnd = 0.35;
          final double top;
          final double scale;
          final double opacity;

          if (t < popEnd) {
            final p = t / popEnd;
            top = widget.startTop - 18 * Curves.easeOutQuart.transform(p);
            scale = 0.7 + 0.45 * Curves.elasticOut.transform(p);
            opacity = (p / 0.4).clamp(0.0, 1.0);
          } else {
            final p = (t - popEnd) / (1 - popEnd);
            final eased = Curves.easeInCubic.transform(p); // 吸い込まれる加速
            top = (widget.startTop - 18) +
                (widget.endTop - (widget.startTop - 18)) * eased;
            scale = 1.15 - 0.75 * eased; // 到達時に小さくなってバーへ収まる
            opacity = p < 0.75 ? 1.0 : (1.0 - (p - 0.75) / 0.25);
          }

          return Stack(
            children: [
              Positioned(
                top: top,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
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
                            Shadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
