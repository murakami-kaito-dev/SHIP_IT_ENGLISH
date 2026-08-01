import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 画面全体に敷く淡い背景グラデーション。奥行きの土台になる。
/// Scaffold の body をこれで包む（Scaffold 自体は透明にする）。
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: child,
    );
  }
}
