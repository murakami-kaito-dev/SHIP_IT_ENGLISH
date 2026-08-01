import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';

/// レベルバッジ＋XPゲージ。XP変化時に easeOutQuart で滑らかにバーが伸び、
/// レベル数値はポップして切り替わる（SKILL: イージング付きプログレスバー）。
class XPProgressBar extends ConsumerWidget {
  /// FEVER中は枠がほんのり発光する。
  final bool fever;
  const XPProgressBar({super.key, this.fever = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(gamificationProvider).snapshot;

    return Row(
      children: [
        // LV バッジ
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
            child: child,
          ),
          child: Container(
            key: ValueKey(snap.level),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: Text(
              'LV ${snap.level}',
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ゲージ本体
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: snap.progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutQuart,
            builder: (context, value, _) => _Bar(value: value, fever: fever),
          ),
        ),
        const SizedBox(width: 8),
        // XP カウント（現在/必要）
        Text(
          '${snap.xpIntoLevel}/${snap.xpForNextLevel}',
          style: AppTheme.captionText.copyWith(
            fontFamily: AppTheme.monoFont,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final bool fever;
  const _Bar({required this.value, required this.fever});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(6),
        boxShadow: fever
            ? [BoxShadow(color: AppTheme.streakFire.withOpacity(0.5), blurRadius: 10)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: fever
                  ? const LinearGradient(
                      colors: [AppTheme.ratingUncertain, AppTheme.streakFire])
                  : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
