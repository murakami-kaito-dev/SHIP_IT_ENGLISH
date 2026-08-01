import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// デイリーストリークUI。火の玉がメラメラ揺れる（Pulse/Breathing）。
/// 今日の目標達成（[goalAchieved]）で炎が力強く発光し、チェックマークが付く。
/// [large] でホーム用（コンパクト）と完了画面用（大）を切り替える。
class StreakWidget extends StatefulWidget {
  final int count;

  /// 「7日連続」等のローカライズ済みラベル。
  final String label;

  /// 今日の目標を達成したか（達成で強発光＋チェック）。
  final bool goalAchieved;

  /// 目標達成メッセージ（達成時のみ表示。例「今日のストリーク達成！」）。null可。
  final String? achievedMessage;

  final bool large;
  final VoidCallback? onTap;

  const StreakWidget({
    super.key,
    required this.count,
    required this.label,
    this.goalAchieved = false,
    this.achievedMessage,
    this.large = false,
    this.onTap,
  });

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.count > 0;
    final iconSize = widget.large ? 64.0 : 28.0;
    final numberStyle = TextStyle(
      fontFamily: AppTheme.monoFont,
      fontSize: widget.large ? 40 : 17,
      fontWeight: FontWeight.w900,
      color: active ? AppTheme.streakFire : AppTheme.textTertiary,
    );

    final flame = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // 呼吸: ゆっくり拡縮＋グロー明滅。達成時は振幅と発光を強める。
        final breath = _c.value; // 0..1
        final amp = widget.goalAchieved ? 0.14 : 0.07;
        final scale = active ? 1.0 + amp * breath : 1.0;
        final glow = widget.goalAchieved ? (0.5 + 0.5 * breath) : (0.25 + 0.35 * breath);
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: active
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.streakFire.withOpacity(glow),
                        blurRadius: widget.large ? 26 : 12,
                        spreadRadius: widget.large ? 3 : 1,
                      ),
                    ],
                  )
                : null,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: iconSize,
              color: active ? AppTheme.streakFire : AppTheme.streakInactive,
            ),
          ),
        );
      },
    );

    // 達成チェックマーク（達成時のみ・ポップ表示）
    final flameWithCheck = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        flame,
        if (widget.goalAchieved)
          Positioned(
            right: widget.large ? -2 : -4,
            bottom: widget.large ? -2 : -4,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: Container(
                padding: EdgeInsets.all(widget.large ? 4 : 2),
                decoration: const BoxDecoration(
                  color: AppTheme.ratingRemembered,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: widget.large ? 20 : 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );

    final Widget content = widget.large
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              flameWithCheck,
              const SizedBox(height: 8),
              Text(widget.label, style: numberStyle),
              if (widget.goalAchieved && widget.achievedMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.achievedMessage!,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.ratingRemembered,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              flameWithCheck,
              const SizedBox(width: 6),
              Text(widget.label, style: numberStyle),
              if (widget.onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.calendar_month_outlined,
                    size: 18, color: AppTheme.textTertiary),
              ],
            ],
          );

    if (widget.onTap == null) return content;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: content,
      ),
    );
  }
}
