import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 主要CTA用のグラデーションボタン（インディゴのグローで奥行きを出す）。
/// [onPressed] が null のときは淡色で無効表示にする。
/// 押下中は `scale(0.95)` に縮み、離すと Spring(elasticOut) で弾んで戻る
/// （SKILL animation-effects「タップ＆レスポンス」）。
class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  // value 0 = 通常, 1 = 押下（0.95）。離すと elasticOut で戻す。
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 340),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(AppTheme.buttonBorderRadius);

    return AnimatedBuilder(
      animation: _press,
      builder: (context, child) {
        final t = _press.status == AnimationStatus.reverse ||
                _press.status == AnimationStatus.dismissed
            ? Curves.elasticOut.transform(_press.value)
            : _press.value;
        return Transform.scale(scale: 1.0 - 0.05 * t, child: child);
      },
      child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: enabled ? AppTheme.primaryGradient : null,
        color: enabled ? null : AppTheme.primaryLight,
        boxShadow: enabled ? AppTheme.buttonShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onHighlightChanged: enabled
              ? (down) => down ? _press.forward() : _press.reverse()
              : null,
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onPressed!();
                }
              : null,
          child: SizedBox(
            height: AppTheme.buttonHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 20,
                    color: enabled ? Colors.white : AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTheme.buttonText.copyWith(
                    color: enabled ? Colors.white : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
