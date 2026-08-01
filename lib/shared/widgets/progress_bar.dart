import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0.0 〜 1.0
  final Color? color;
  final Color? backgroundColor;

  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${(value * 100).round()}% complete',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.progressBarBorderRadius),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: AppTheme.progressBarHeight,
          color: color ?? AppTheme.primary,
          backgroundColor: backgroundColor ?? AppTheme.surfaceBorder,
        ),
      ),
    );
  }
}
