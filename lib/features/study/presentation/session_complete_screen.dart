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
import 'package:ship_it_english/features/gamification/presentation/widgets/streak_widget.dart';
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
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // お祝いに弾むダッキー＋チェックマーク（達成感）
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.buttonShadow,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 42),
                    ),
                    const SizedBox(width: 10),
                    DuckMascot(
                      size: 52,
                      mood: DuckMood.cheer,
                      rank: rankForLevel(
                          ref.watch(gamificationProvider).snapshot.level),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(strings.sessionCompleteTitle,
                    style: AppTheme.headingLarge),
                if (result.perfect) ...[
                  const SizedBox(height: 10),
                  // パーフェクトセッション（全問1発「覚えてた」）の証
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFFB300),
                        Color(0xFFFFD54F),
                      ]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withOpacity(0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '\u2b50 ${strings.perfectTitle}',
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          strings.perfectCaption(
                              GamificationConfig.perfectBonusXp),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // デイリーストリーク（大・達成で炎が強発光＋チェック）
                StreakWidget(
                  count: result.streakCount,
                  label: strings.streak(result.streakCount),
                  goalAchieved: goalAchieved,
                  achievedMessage:
                      goalAchieved ? strings.streakGoalReached : null,
                  large: true,
                ),
                const SizedBox(height: 24),
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
