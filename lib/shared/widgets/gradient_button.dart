import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 主要CTA用の「下エッジで押すと沈む」立体ボタン（デザイン案H＝骨格:案F）。
///
/// 通常時は下に濃色の厚み（5px）があり、押すとボタン本体が沈んで厚みが薄くなる
/// （物理的に「押した」感触）。離すと素早く戻る。[onPressed] が null のときは
/// 淡色で無効表示にする。名前は歴史的経緯で GradientButton のまま
/// （呼び出し側60箇所超のAPI互換を維持）。
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
  /// 下エッジの厚み（沈み込みの深さでもある）。
  static const double _edge = 5.0;

  // value 0 = 通常（浮いている）, 1 = 押下（沈んでいる）。
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 70),
    reverseDuration: const Duration(milliseconds: 160),
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
        final t = Curves.easeOut.transform(_press.value);
        final dy = _edge * 0.8 * t; // 沈む量
        return Padding(
          // 沈んでも下端の占有高さが変わらないよう、浮き分を上に確保する
          padding: EdgeInsets.only(top: dy, bottom: _edge - dy),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: enabled ? AppTheme.primary : AppTheme.primaryLight,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryDark,
                        offset: Offset(0, _edge - dy),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onHighlightChanged: widget.onPressed != null
              ? (down) => down ? _press.forward() : _press.reverse()
              : null,
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onPressed!();
                }
              : null,
          child: SizedBox(
            height: AppTheme.buttonHeight - _edge,
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
    );
  }
}
