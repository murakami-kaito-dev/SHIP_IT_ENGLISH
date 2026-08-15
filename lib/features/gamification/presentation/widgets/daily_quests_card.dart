import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/services/sound_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/domain/quests.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/confetti_celebration.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';
import 'package:ship_it_english/features/gamification/providers/quests_providers.dart';
import 'package:ship_it_english/shared/widgets/gradient_button.dart';

/// ホームの「今日のクエスト」カード。日替わりの3つのお題と進捗、
/// 全達成で開けられる宝箱（可変報酬）を表示する。
class DailyQuestsCard extends ConsumerWidget {
  const DailyQuestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyQuestsProvider);
    final strings = ref.watch(stringsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                strings.dailyQuestsTitle,
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${state.doneCount} / ${state.quests.length}',
                style: AppTheme.monoNumber.copyWith(
                  color: state.allDone
                      ? AppTheme.ratingRemembered
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final quest in state.quests) ...[
            _QuestRow(
              quest: quest,
              value: state.progress.valueFor(quest),
              done: state.progress.isDone(quest),
              strings: strings,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 2),
          _ChestArea(state: state, strings: strings),
        ],
      ),
    );
  }
}

/// クエスト1行（アイコン・お題・進捗バー・達成チェック）。
class _QuestRow extends StatelessWidget {
  final Quest quest;
  final int value;
  final bool done;
  final AppStrings strings;

  const _QuestRow({
    required this.quest,
    required this.value,
    required this.done,
    required this.strings,
  });

  IconData get _icon => switch (quest.type) {
        QuestType.studyCards => Icons.style_rounded,
        QuestType.comboReach => Icons.bolt_rounded,
        QuestType.remembered => Icons.verified_rounded,
        QuestType.listenLines => Icons.headphones_rounded,
      };

  /// クエスト種類ごとの配色（タイル=soft / ゲージ=deep）。
  /// 意味で色を使い分ける（案Hの多彩色パレット）。
  (Color, Color) get _questColors => switch (quest.type) {
        QuestType.studyCards => (AppTheme.questYellowSoft, AppTheme.questYellow),
        QuestType.comboReach => (AppTheme.questBlueSoft, AppTheme.questBlue),
        QuestType.remembered => (AppTheme.questGreenSoft, AppTheme.questGreen),
        QuestType.listenLines =>
          (AppTheme.questOrangeSoft, AppTheme.questOrange),
      };

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, quest.target);
    final (softColor, deepColor) = _questColors;
    final color = done ? AppTheme.ratingRemembered : deepColor;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done
                ? AppTheme.ratingRemembered.withOpacity(0.12)
                : softColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(done ? Icons.check_rounded : _icon,
              size: 18,
              color: done ? AppTheme.ratingRemembered : AppTheme.textPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.questTitle(quest),
                style: AppTheme.captionText.copyWith(
                  color:
                      done ? AppTheme.textTertiary : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(color: AppTheme.track),
                      FractionallySizedBox(
                        widthFactor:
                            (clamped / quest.target).clamp(0.0, 1.0),
                        heightFactor: 1.0,
                        child: DecoratedBox(
                            decoration: BoxDecoration(color: color)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$clamped/${quest.target}',
          style: AppTheme.monoLabel.copyWith(
            color: done ? AppTheme.ratingRemembered : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 宝箱エリア（未達成＝ロック表示 / 達成＝開けるボタン / 受領済み＝チップ）。
class _ChestArea extends ConsumerWidget {
  final QuestsState state;
  final AppStrings strings;

  const _ChestArea({required this.state, required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.progress.chestClaimed) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppTheme.ratingRemembered),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.questChestClaimed(state.progress.claimedXp),
              style: AppTheme.captionText
                  .copyWith(color: AppTheme.ratingRemembered),
            ),
          ),
        ],
      );
    }

    if (state.chestReady) {
      return GradientButton(
        label: strings.questChestOpen,
        icon: Icons.card_giftcard_rounded,
        onPressed: () => _openChest(context, ref),
      );
    }

    return Row(
      children: [
        const Icon(Icons.lock_rounded, size: 16, color: AppTheme.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            strings.questChestLocked,
            style: AppTheme.captionText.copyWith(color: AppTheme.textTertiary),
          ),
        ),
      ],
    );
  }

  Future<void> _openChest(BuildContext context, WidgetRef ref) async {
    final gamification = ref.read(gamificationProvider.notifier);
    final canGrantFreeze = ref.read(gamificationProvider).streakFreezes <
        GamificationConfig.maxStreakFreezes;
    final reward = await ref
        .read(dailyQuestsProvider.notifier)
        .claimChest(canGrantFreeze: canGrantFreeze);
    if (reward == null) return;

    // 報酬の付与（XPは通算に積む＝レベルにも反映）
    await gamification.grantBonusXp(reward.xp);
    if (reward.streakFreeze) {
      await gamification.grantStreakFreeze();
    }

    if (!context.mounted) return;
    SoundService.instance.celebrate();
    await _showChestDialog(context, reward);
  }

  Future<void> _showChestDialog(BuildContext context, ChestReward reward) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'chest',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final scale = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeIn,
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: ConfettiCelebration()),
            ),
            ScaleTransition(
              scale: scale,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.heroShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(
                        strings.questChestTitle,
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.questChestGained(reward.xp),
                        style: AppTheme.monoNumberLarge
                            .copyWith(color: AppTheme.primary),
                      ),
                      if (reward.streakFreeze) ...[
                        const SizedBox(height: 6),
                        Text(
                          strings.questChestFreezeBonus,
                          style: AppTheme.captionText
                              .copyWith(color: AppTheme.streakFire),
                        ),
                      ],
                      const SizedBox(height: 18),
                      GradientButton(
                        label: strings.continueButton,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
