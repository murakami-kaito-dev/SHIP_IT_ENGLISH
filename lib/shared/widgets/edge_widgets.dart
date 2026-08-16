import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 案H（Soft Arcade Warm）の「下エッジで押すと沈む」共通部品群。
///
/// Material の SegmentedButton / OutlinedButton は影を持てずフラットに見えるため、
/// 押下可能な操作には必ずこのファイルの部品を使う（デモ design_h_home.dart の
/// チップ/サブボタンの見た目を本実装に写したもの）。
/// - [EdgeChips] … 排他選択チップ列（SegmentedButton の置き換え）
/// - [EdgeButton] … 白地のサブボタン（OutlinedButton の置き換え）
/// - [EdgeIconButton] … 正方形のアイコンボタン（🎛 など）
/// 主要CTAは従来どおり GradientButton（インディゴ・エッジ5px）。

/// 下エッジ＋押下で沈むコンテナ（このファイルの部品の土台）。
class EdgePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color fill;
  final Color edgeColor;
  final Color? borderColor;
  final double edge;
  final double radius;

  const EdgePressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.fill,
    required this.edgeColor,
    this.borderColor,
    this.edge = 2.5,
    this.radius = 13,
  });

  @override
  State<EdgePressable> createState() => _EdgePressableState();
}

class _EdgePressableState extends State<EdgePressable>
    with SingleTickerProviderStateMixin {
  // value 0 = 浮いている, 1 = 沈んでいる（GradientButton と同じ物理）
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
    final radius = BorderRadius.circular(widget.radius);
    final enabled = widget.onTap != null;

    return AnimatedBuilder(
      animation: _press,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_press.value);
        final dy = widget.edge * 0.8 * t;
        return Padding(
          // 沈んでも下端の占有高さが変わらないよう、浮き分を上に確保する
          padding: EdgeInsets.only(top: dy, bottom: widget.edge - dy),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.fill,
              borderRadius: radius,
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: widget.edgeColor,
                  offset: Offset(0, widget.edge - dy),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onHighlightChanged:
              enabled ? (down) => down ? _press.forward() : _press.reverse() : null,
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                }
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 排他選択チップの1項目。
class EdgeChipItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const EdgeChipItem(this.value, this.label, {this.icon});
}

/// 押せる見た目の排他選択チップ列（SegmentedButton の案H置き換え）。
/// 選択中＝淡インディゴ＋インディゴ枠/エッジ、非選択＝白＋暖色枠/エッジ。
class EdgeChips<T> extends StatelessWidget {
  final List<EdgeChipItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  /// true（既定）: 各チップを等幅で横幅いっぱいに広げる。
  /// false: 内容幅のまま並べる（設定画面の行内配置など）。
  final bool expanded;

  const EdgeChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 7));
      final chip = _chip(items[i]);
      children.add(expanded ? Expanded(child: chip) : chip);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _chip(EdgeChipItem<T> item) {
    final isSelected = item.value == selected;
    return EdgePressable(
      onTap: isSelected ? null : () => onChanged(item.value),
      fill: isSelected ? AppTheme.primaryLight : AppTheme.surface,
      borderColor:
          isSelected ? AppTheme.chipSelectedBorder : AppTheme.surfaceBorder,
      edgeColor:
          isSelected ? AppTheme.chipSelectedEdge : AppTheme.surfaceEdge,
      radius: 11,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 16,
                color:
                    isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? AppTheme.primaryDark
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 白地のサブボタン（OutlinedButton の案H置き換え）。
/// 無効時（onPressed=null）は文字/アイコンだけ淡色にし、エッジは残す。
class EdgeButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// エッジを含めた占有高さ。
  final double height;
  final Color foreground;
  final double fontSize;

  const EdgeButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.height = AppTheme.buttonHeight,
    this.foreground = AppTheme.primary,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    const edge = 3.0;
    final enabled = onPressed != null;
    final fg = enabled ? foreground : AppTheme.textTertiary;
    return EdgePressable(
      onTap: onPressed,
      fill: AppTheme.surface,
      borderColor: AppTheme.surfaceBorder,
      edgeColor: AppTheme.surfaceEdge,
      edge: edge,
      child: SizedBox(
        height: height - edge,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 正方形のアイコンボタン（🎛 範囲指定など。EdgeButton のアイコン単体版）。
class EdgeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  const EdgeIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = AppTheme.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    const edge = 3.0;
    final enabled = onPressed != null;
    return EdgePressable(
      onTap: onPressed,
      fill: AppTheme.surface,
      borderColor: AppTheme.surfaceBorder,
      edgeColor: AppTheme.surfaceEdge,
      edge: edge,
      child: SizedBox(
        width: size,
        height: size - edge,
        child: Icon(
          icon,
          size: 21,
          color: enabled ? AppTheme.primary : AppTheme.textTertiary,
        ),
      ),
    );
  }
}
