import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';

/// レベルバッジ＋XPゲージ。
///
/// **セッション進捗バーとは別物**であることが一目で分かるよう、白いカードの上に
/// 「LVバッジ・ゲージ・次の到達点」をまとめた部品として構成する（セッション進捗は
/// AppBar直下の全幅ヘアライン＝線。こちらは面）。
///
/// ゲージが「溜まる楽しみ」を出すために:
/// - 次に何が起きるかを常に文字で出す（`あと36XPでLV4`）
/// - 25%ごとの刻み目で、1回分（+12XP程度）の増加も目で分かるようにする
/// - 85%を超えたら枠を強調して「あと少し」を煽る
class XPProgressBar extends ConsumerWidget {
  /// FEVER中は炎色＋発光にする。
  final bool fever;

  /// 現在のコンボ数（0なら非表示）。
  final int combo;

  const XPProgressBar({super.key, this.fever = false, this.combo = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(gamificationProvider).snapshot;
    final strings = ref.watch(stringsProvider);

    final remaining = (snap.xpForNextLevel - snap.xpIntoLevel).clamp(0, 1 << 30);
    // 残りわずかの状態。ここで見た目を変えて「あと少し」の高揚を作る。
    final almost = snap.progress >= 0.85;
    final accent = fever ? AppTheme.streakFire : AppTheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: fever ? const Color(0xFFFFF8F3) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (almost || fever)
              ? accent.withOpacity(0.5)
              : AppTheme.surfaceBorder,
          width: 1.5,
        ),
        boxShadow: fever
            ? [
                BoxShadow(
                  color: AppTheme.streakFire.withOpacity(0.35),
                  blurRadius: 12,
                ),
              ]
            : AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _LevelBadge(level: snap.level, fever: fever),
              const SizedBox(width: 10),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: snap.progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, _) =>
                      _Bar(value: value, fever: fever),
                ),
              ),
              const SizedBox(width: 8),
              // XPカウント。単位を必ず添える（何の数字か分からなくなるため）
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${snap.xpIntoLevel}',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    TextSpan(
                      text: '/${snap.xpForNextLevel} XP',
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // 次の到達点を常時提示（ゴール勾配効果）。残りわずかなら煽り文言に。
              Expanded(
                child: Text(
                  almost
                      ? strings.xpAlmost(remaining)
                      : strings.xpToNext(remaining, snap.level + 1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: almost ? FontWeight.w800 : FontWeight.w600,
                    color: almost ? accent : AppTheme.textSecondary,
                  ),
                ),
              ),
              if (fever)
                const _Chip(text: '×1.5 🔥', color: AppTheme.streakFire)
              else if (combo >= 2)
                _Chip(
                  text: '🔥 ${strings.comboChip(combo)}',
                  color: AppTheme.streakFire,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final bool fever;
  const _LevelBadge({required this.level, required this.fever});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: child,
      ),
      child: Container(
        key: ValueKey('$level$fever'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: fever
              ? const LinearGradient(
                  colors: [AppTheme.ratingUncertain, AppTheme.streakFire],
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: Text(
          'LV $level',
          style: const TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final bool fever;
  const _Bar({required this.value, required this.fever});

  static const double _height = 14;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          // 下地
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fever
                    ? AppTheme.streakFire.withOpacity(0.15)
                    : AppTheme.track,
                borderRadius: BorderRadius.circular(_height / 2),
              ),
            ),
          ),
          // 塗り。
          // heightFactor を必ず指定すること。省くと高さの制約が緩いまま渡り、
          // 子を持たない DecoratedBox が高さ0に潰れて**1pxも描画されない**
          // （実際にそのバグがあり、XPが溜まっても見た目が変わらなかった）。
          ClipRRect(
            borderRadius: BorderRadius.circular(_height / 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                heightFactor: 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: fever
                        ? const LinearGradient(
                            colors: [
                              AppTheme.ratingUncertain,
                              AppTheme.streakFire
                            ],
                          )
                        : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(_height / 2),
                  ),
                ),
              ),
            ),
          ),
          // 25%ごとの刻み目。のっぺりした棒だと1回分(+12XP程度)の増加が
          // 目で分からないため、区切りを入れて小さな前進を体感できるようにする。
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  for (final f in const [0.25, 0.5, 0.75])
                    Positioned(
                      left: c.maxWidth * f,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1.5,
                        color: value > f
                            ? Colors.white.withOpacity(0.55)
                            : AppTheme.textTertiary.withOpacity(0.25),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
