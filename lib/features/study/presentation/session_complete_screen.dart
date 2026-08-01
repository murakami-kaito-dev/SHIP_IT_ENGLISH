import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/providers/progress_refresh.dart';
import 'package:ship_it_english/core/services/review_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
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
        body: SafeArea(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // グラデーションの円に載せたチェックマーク（達成感）
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text(strings.sessionCompleteTitle,
                    style: AppTheme.headingLarge),
                const SizedBox(height: 32),
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
                        label: strings.statStreak,
                        value: strings.streakDays(result.streakCount),
                      ),
                    ],
                  ),
                ),
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
