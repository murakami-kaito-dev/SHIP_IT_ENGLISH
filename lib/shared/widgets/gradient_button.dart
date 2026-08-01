import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 主要CTA用のグラデーションボタン（インディゴのグローで奥行きを出す）。
/// [onPressed] が null のときは淡色で無効表示にする。
class GradientButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(AppTheme.buttonBorderRadius);

    return DecoratedBox(
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
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                }
              : null,
          child: SizedBox(
            height: AppTheme.buttonHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: enabled ? Colors.white : AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
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
