import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:ship_it_english/core/services/sound_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/confetti_celebration.dart';

/// レベルアップ時に「LEVEL UP!」を Scale-up + Bounce(Spring) で豪華に出すモーダル。
/// 背後で紙吹雪も発火し、ハプティクス＋SFXフックを鳴らす。
Future<void> showLevelUpModal(
  BuildContext context, {
  required int newLevel,
  required String title,
  required String levelLabel,
  required String continueLabel,
}) {
  SoundService.instance.levelUp();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'level-up',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, __, child) {
      // 拡大しながら弾む（elasticOut）。フェードも併用。
      final scale = CurvedAnimation(parent: anim, curve: Curves.elasticOut);
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: ScaleTransition(
          scale: scale,
          child: _LevelUpCard(
            newLevel: newLevel,
            title: title,
            levelLabel: levelLabel,
            continueLabel: continueLabel,
          ),
        ),
      );
    },
  );
}

class _LevelUpCard extends StatefulWidget {
  final int newLevel;
  final String title;
  final String levelLabel;
  final String continueLabel;
  const _LevelUpCard({
    required this.newLevel,
    required this.title,
    required this.levelLabel,
    required this.continueLabel,
  });

  @override
  State<_LevelUpCard> createState() => _LevelUpCardState();
}

class _LevelUpCardState extends State<_LevelUpCard> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ConfettiCelebration(autoPlay: false, controller: _confetti),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.heroShadow,
              border: Border.all(color: AppTheme.primary.withOpacity(0.25), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: Text(
                    '${widget.levelLabel} ${widget.newLevel}',
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(widget.continueLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
