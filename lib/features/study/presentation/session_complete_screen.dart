import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/providers/progress_refresh.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/services/home_widget_service.dart';
import 'package:ship_it_english/core/services/review_service.dart';
import 'package:ship_it_english/core/services/sound_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/confetti_celebration.dart';
import 'package:ship_it_english/features/gamification/presentation/badges_screen.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';
import 'package:ship_it_english/features/gamification/providers/badges_providers.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/xp_progress_bar.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';
import 'package:ship_it_english/features/home/providers/home_providers.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/features/study/providers/study_providers.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';
import 'package:ship_it_english/shared/widgets/gradient_button.dart';

class SessionCompleteScreen extends ConsumerStatefulWidget {
  const SessionCompleteScreen({super.key});

  @override
  ConsumerState<SessionCompleteScreen> createState() =>
      _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends ConsumerState<SessionCompleteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // セッションで進捗が変わったので、ホーム・カテゴリの集計を作り直す。
      // これを忘れると「習得済み 0/195」「復習するカードはありません」の
      // 古い表示が残る
      invalidateProgressProviders(ref);

      // ホーム画面ウィジェットにも最新のストリーク・今日の枚数を反映
      HomeWidgetService.sync(
          ref.read(cardRepositoryProvider) as LocalCardRepository);

      // セレブレーション（紙吹雪は画面側で自動発火・ここで音と振動）
      SoundService.instance.celebrate();

      // マイルストーンバッジの判定（新規獲得があれば少し置いてお祝い）
      checkAndAwardBadges(ref).then((newBadges) {
        if (newBadges.isEmpty || !mounted) return;
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          showNewBadgesModal(
            context,
            badges: newBadges,
            strings: ref.read(stringsProvider),
            mode: ref.read(languageModeProvider),
          );
        });
      });

      // 結果表示が落ち着いたタイミングでアプリ内レビューを依頼
      // （ストリーク3日以上・過去に未依頼の場合のみ表示される）
      final result = ref.read(lastSessionResultProvider);
      if (result != null) {
        Future.delayed(const Duration(seconds: 2), () {
          ReviewService().maybeRequestReview(streakCount: result.streakCount);
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(lastSessionResultProvider);
    final strings = ref.watch(stringsProvider);

    if (result == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/'),
            child: Text(strings.backToHome),
          ),
        ),
      );
    }

    final accuracy =
        result.studiedCount > 0
            ? (result.correctCount / result.studiedCount * 100).round()
            : 0;

    // 今日の目標達成でストリークの炎を強発光させる
    final studiedToday = ref.watch(dailySessionInfoProvider).asData?.value
            .cardsStudiedToday ??
        0;
    final goalAchieved = studiedToday >= GamificationConfig.dailyGoalCards;
    // このセッションで獲得したXP
    final sessionXp = ref.watch(gamificationProvider).sessionXp;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(lastSessionResultProvider.notifier).state = null;
          context.go('/');
        }
      },
      child: AppBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
          // 端末が小さくても必ず下の「ホームへ」ボタンまで到達できるよう
          // 全体をスクロール可能にする（以前は Column 固定で溢れると戻れなかった）
          child: SingleChildScrollView(
            padding: AppTheme.screenPadding,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // お祝いのヒーローはダッキー1体に集約
                // （以前は ✓サークル＋ダッキー＋PERFECT帯＋大きな🔥が縦に並び、
                //  お祝い要素が3段重なってくどかった）
                DuckMascot(
                  size: 76,
                  mood: DuckMood.cheer,
                  rank: rankForLevel(
                      ref.watch(gamificationProvider).snapshot.level),
                ),
                const SizedBox(height: 14),
                Text(strings.sessionCompleteTitle,
                    style: AppTheme.headingLarge),
                const SizedBox(height: 14),
                // お祝いバッジはコンパクトなチップ1行にまとめる
                // （PERFECT と 🔥ストリークを横並び・折り返し）
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (result.perfect)
                      _CelebrationChip(
                        label:
                            '\u2b50 ${strings.perfectTitle} +${GamificationConfig.perfectBonusXp} XP',
                        color: const Color(0xFFB47D00),
                        background: const Color(0xFFFFE9A8),
                        border: const Color(0xFFF3CD5E),
                      ),
                    _CelebrationChip(
                      label: '\ud83d\udd25 ${strings.streak(result.streakCount)}'
                          '${goalAchieved ? ' \u2713' : ''}',
                      color: AppTheme.streakFire,
                      background: AppTheme.streakFire.withOpacity(0.10),
                      border: AppTheme.streakFire.withOpacity(0.40),
                    ),
                  ],
                ),
                if (goalAchieved) ...[
                  const SizedBox(height: 8),
                  Text(strings.streakGoalReached,
                      style: AppTheme.captionText
                          .copyWith(color: AppTheme.streakFire)),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: AppTheme.cardDecoration,
                  padding: AppTheme.cardPadding,
                  child: Column(
                    children: [
                      _StatRow(
                        label: strings.statStudied,
                        value: strings.cardsCount(result.studiedCount),
                      ),
                      _StatRow(
                        label: strings.statCorrect,
                        value: strings.correctWithAccuracy(
                            result.correctCount, accuracy),
                      ),
                      _StatRow(
                        label: strings.statTime,
                        value: _formatDuration(result.duration),
                      ),
                      _StatRow(
                        label: strings.xpEarned,
                        value: '+$sessionXp XP',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // レベル＆XPゲージ（獲得XPが反映された状態）
                const XPProgressBar(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${result.newCardsCount}',
                          style: AppTheme.monoNumberLarge
                              .copyWith(color: AppTheme.primary),
                        ),
                        Text(strings.newWordsLearned,
                            style: AppTheme.captionText),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${result.reviewCardsCount}',
                          style: AppTheme.monoNumberLarge
                              .copyWith(color: AppTheme.primaryDark),
                        ),
                        Text(
                          strings.reviewsCompleted,
                          style: AppTheme.captionText,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                GradientButton(
                  label: strings.backToHome,
                  icon: Icons.home_rounded,
                  onPressed: () {
                    ref.read(lastSessionResultProvider.notifier).state = null;
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ),
            // セッション完了の紙吹雪（表示時に自動で発火）
            const ConfettiCelebration(),
          ],
        ),
        ),
      ),
    );
  }
}

/// お祝いチップ（PERFECT / 🔥ストリーク）。完了画面の祝辞を1行にまとめる部品。
class _CelebrationChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final Color? border;

  const _CelebrationChip({
    required this.label,
    required this.color,
    required this.background,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border ?? background, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyText),
          Text(value, style: AppTheme.monoNumber),
        ],
      ),
    );
  }
}
