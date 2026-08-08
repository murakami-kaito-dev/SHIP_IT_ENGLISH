import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 画面全体に紙吹雪を降らせるセレブレーション（SKILL: セッション完了/レベルアップで発火）。
/// 上部中央から下向きに吹き出す。[autoPlay] が true なら表示時に自動で発火。
/// 外部から制御したい場合は [controller] を渡す。
class ConfettiCelebration extends StatefulWidget {
  final bool autoPlay;
  final ConfettiController? controller;

  /// 吹き出しの継続時間（autoPlay時）。
  final Duration duration;

  const ConfettiCelebration({
    super.key,
    this.autoPlay = true,
    this.controller,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration> {
  late final ConfettiController _own =
      widget.controller ?? ConfettiController(duration: widget.duration);

  static const _colors = [
    AppTheme.primary,
    AppTheme.primaryGlow,
    AppTheme.ratingRemembered,
    AppTheme.ratingUncertain,
    AppTheme.streakFire,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay && widget.controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _own.play());
    }
  }

  @override
  void dispose() {
    // 外部controllerは持ち主が破棄する。自前生成時のみ破棄。
    if (widget.controller == null) _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _own,
          blastDirection: math.pi / 2, // 下向き
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 18,
          maxBlastForce: 22,
          minBlastForce: 8,
          gravity: 0.28,
          colors: _colors,
        ),
      ),
    );
  }
}
