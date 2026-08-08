import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';

/// 連続正解時に「COMBO xN」を Spring 物理で弾ませて表示するオーバーレイ。
/// コンボ数が増えるほどネオンカラーが派手になり、FEVER到達で専用表示になる。
/// [combo] が変化するたびに再アニメーションする。非インタラクティブ。
class ComboOverlay extends StatefulWidget {
  final int combo;
  const ComboOverlay({super.key, required this.combo});

  @override
  State<ComboOverlay> createState() => _ComboOverlayState();
}

class _ComboOverlayState extends State<ComboOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  // ネオンのゆらぎ（グロー用に無限ループ）。
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(covariant ComboOverlay old) {
    super.didUpdateWidget(old);
    if (widget.combo != old.combo && widget.combo >= 2) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _glow.dispose();
    super.dispose();
  }

  // コンボ段階に応じたネオン色（2-3:青紫 → 4:琥珀 → FEVER:ローズ/炎）。
  Color _neon() {
    if (widget.combo >= GamificationConfig.feverThreshold) {
      return AppTheme.streakFire;
    }
    if (widget.combo >= 4) return AppTheme.ratingUncertain;
    return AppTheme.primaryGlow;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo < 2) return const SizedBox.shrink();
    final fever = widget.combo >= GamificationConfig.feverThreshold;
    final neon = _neon();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _glow]),
        builder: (context, _) {
          // pop: elasticOut で拡大しながら弾む。終盤で少しフェード。
          final p = _pop.value;
          final scale = 0.4 + 1.0 * Curves.elasticOut.transform(p.clamp(0, 1));
          final opacity = p < 0.85 ? 1.0 : (1.0 - (p - 0.85) / 0.15);
          final glowT = 0.5 + 0.5 * _glow.value;

          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fever)
                    _FeverTag(neon: neon, glowT: glowT),
                  Text(
                    'COMBO',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 15,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '×${widget.combo}',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 56,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        // ネオン発光（内→外の二重グロー）
                        Shadow(color: neon, blurRadius: 12 + 16 * glowT),
                        Shadow(color: neon.withOpacity(0.8), blurRadius: 28 + 24 * glowT),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeverTag extends StatelessWidget {
  final Color neon;
  final double glowT;
  const _FeverTag({required this.neon, required this.glowT});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.streakFire, AppTheme.ratingForgot],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: neon.withOpacity(0.6 * glowT), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: const Text(
        '🔥 FEVER ×1.5',
        style: TextStyle(
          fontFamily: AppTheme.monoFont,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
