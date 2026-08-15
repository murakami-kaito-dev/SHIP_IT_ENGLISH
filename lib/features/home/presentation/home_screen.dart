
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/services/streak_manager.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/home/presentation/widgets/skill_score_card.dart';
import 'package:ship_it_english/features/home/providers/home_providers.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';
import 'package:ship_it_english/features/study/presentation/widgets/range_study_sheet.dart';
import 'package:ship_it_english/shared/widgets/gradient_button.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/streak_widget.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/xp_progress_bar.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/daily_quests_card.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';
import 'package:ship_it_english/features/gamification/providers/quests_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 起動時にストリーク保護が自動消費されていたら一度だけ知らせる
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showStreakFreezeNoticeIfAny());
    // 日付が変わっていたら今日のクエストに切り替える（冪等）
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(dailyQuestsProvider.notifier).ensureToday());
  }

  Future<void> _showStreakFreezeNoticeIfAny() async {
    final n = await StreakManager().takeStreakFreezeUsedNotice();
    if (n <= 0 || !mounted) return;
    // 消費後の最新の所持数をゲーミフィケーション状態にも反映
    await ref.read(gamificationProvider.notifier).refreshStreakFreezes();
    if (!mounted) return;
    final strings = ref.read(stringsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.streakFreezeUsedNotice(n))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionInfo = ref.watch(dailySessionInfoProvider);
    final skill = ref.watch(skillScoreProvider);
    final weekly = ref.watch(weeklyStatsProvider);
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ターミナルのプロンプトを想わせるブランドマーク
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: const Text(
                '>_',
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('ShipIt English'),
          ],
        ),
        centerTitle: false,
        actions: const [
          // マスコット「ダッキー」（タップで一言。今日学習済みならご機嫌に弾む）
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: _HomeDuck(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailySessionInfoProvider);
          ref.invalidate(skillScoreProvider);
          ref.invalidate(weeklyStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sessionInfo.when(
                // 新規カード数を変更すると settings に依存する当プロバイダーが
                // 再計算される。その間ローディングに落とすと画面がちらつくため、
                // 再取得中は前回の値を出したまま滑らかに差し替える
                skipLoadingOnReload: true,
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text(
                  strings.loadError,
                  style: AppTheme.bodyText.copyWith(color: AppTheme.ratingForgot),
                ),
                data: (info) =>
                    _buildSessionSection(context, ref, info, strings),
              ),
              const SizedBox(height: 24),
              // 日替わりのお題＋宝箱（今日開く理由を作るデイリークエスト）
              const DailyQuestsCard(),
              const SizedBox(height: 16),
              // 通算で獲得した経験値（XP）とレベルを確認できるカード
              _LevelCard(strings: strings),
              const SizedBox(height: 16),
              // XPで交換する特典：ストリーク保護
              _StreakShieldCard(strings: strings),
              const SizedBox(height: 24),
              weekly.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (days) =>
                    _WeeklySummaryCard(days: days, strings: strings),
              ),
              const SizedBox(height: 24),
              // 技術英語カバレッジ（実力の単一スコア。続けると上がる）
              skill.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (s) => SkillScoreCard(score: s, strings: strings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionSection(
    BuildContext context,
    WidgetRef ref,
    DailySessionInfo info,
    AppStrings strings,
  ) {
    final allMastered =
        ref.watch(overallProgressProvider).asData?.value.let((p) =>
            p.totalCount > 0 && p.masteredCount == p.totalCount) ??
        false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreakWidget(
              count: info.streakCount,
              label: strings.streak(info.streakCount),
              // 今日の目標カード数を達成したら炎が強発光＋チェック
              goalAchieved:
                  info.cardsStudiedToday >= GamificationConfig.dailyGoalCards,
              // タップで学習カレンダー（いつ学習したかの記録）を開く
              onTap: () => context.push('/history'),
            ),
            Text(
              strings.todayDate(DateTime.now()),
              style: AppTheme.captionText,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (allMastered)
          _AllMasteredCard(strings: strings)
        else
          // 完了マーク・各行・合計・操作ボタンをすべて白カード内にまとめる
          _TodaySessionCard(info: info, strings: strings),
      ],
    );
  }

}

/// 通算で獲得した経験値（XP）と現在のレベルを表示するカード。
/// 学習の積み上げが一目で分かる「経験値を確認する場所」。
class _LevelCard extends ConsumerWidget {
  final AppStrings strings;
  const _LevelCard({required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(gamificationProvider).snapshot;
    final remaining = (snap.xpForNextLevel - snap.xpIntoLevel).clamp(0, 1 << 30);
    final rank = rankForLevel(snap.level);

    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 18, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(strings.levelTitle, style: AppTheme.headingMedium),
                ],
              ),
              // 通算XP（積み上げの総量）
              Text(
                strings.totalXpValue(snap.totalXp),
                style: AppTheme.monoNumber.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 現在の称号（キャリアラダー）＝レベルの意味づけ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    size: 15, color: AppTheme.primary),
                const SizedBox(width: 5),
                Text(
                  strings.rankName(rank),
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // LVバッジ＋イージング付きXPゲージ（現在レベル内の進捗）
          const XPProgressBar(),
          const SizedBox(height: 10),
          Text(
            strings.xpToNext(remaining, snap.level + 1),
            style: AppTheme.captionText,
          ),
          const SizedBox(height: 2),
          Text(strings.levelCaption, style: AppTheme.captionText),
        ],
      ),
    );
  }
}

/// XP（使えるXP）を消費してストリーク保護を交換するカード。
/// 連続記録を絶やさないための特典＝経験値の使い道を提供する。
class _StreakShieldCard extends ConsumerWidget {
  final AppStrings strings;
  const _StreakShieldCard({required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gamificationProvider);
    final canBuy = g.canBuyStreakFreeze;
    final atMax = g.streakFreezes >= GamificationConfig.maxStreakFreezes;

    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      size: 18, color: AppTheme.streakFire),
                  const SizedBox(width: 6),
                  Text(strings.streakShieldTitle,
                      style: AppTheme.headingMedium),
                ],
              ),
              // 使えるXP（交換に使える残高）
              Text(
                strings.availableXpLabel(g.availableXp),
                style: AppTheme.monoNumber.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 所持数を盾アイコンで可視化
          Row(
            children: [
              for (var i = 0; i < GamificationConfig.maxStreakFreezes; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 26,
                    color: i < g.streakFreezes
                        ? AppTheme.streakFire
                        : AppTheme.surfaceBorder,
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                strings.streakShieldOwned(
                    g.streakFreezes, GamificationConfig.maxStreakFreezes),
                style: AppTheme.captionText,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(strings.streakShieldDesc, style: AppTheme.captionText),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: canBuy
                  ? () async {
                      final ok = await ref
                          .read(gamificationProvider.notifier)
                          .buyStreakFreeze();
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(strings.streakShieldPurchased)),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.add_moderator_rounded, size: 18),
              label: Text(
                atMax
                    ? strings.streakShieldMax
                    : (canBuy
                        ? strings.exchangeForXp(
                            GamificationConfig.streakFreezeCost)
                        : strings.streakShieldNotEnough),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySessionCard extends ConsumerWidget {
  final DailySessionInfo info;
  final AppStrings strings;

  const _TodaySessionCard({required this.info, required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // 学習範囲（新規のみ/復習のみ/両方）に応じて合計枚数を出し分ける
    final scope = settings.studyScope;
    final scopedTotal = switch (scope) {
      StudyScope.newOnly => info.newCardsCount,
      StudyScope.reviewOnly => info.reviewCardsCount,
      StudyScope.both => info.totalCount,
    };

    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(strings.todaysSession, style: AppTheme.headingMedium),
              // 今日の学習が済んでいたら、タイトル横の余白に小さく完了を示す
              if (info.hasStudiedToday) ...[
                const SizedBox(width: 10),
                _SessionDoneChip(label: strings.sessionDoneChip),
              ],
              const Spacer(),
              // 仕様がわかりにくいので「?」でヘルプを開けるようにする
              IconButton(
                icon: const Icon(Icons.help_outline_rounded, size: 20),
                color: AppTheme.textTertiary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: strings.sessionHelpTooltip,
                onPressed: () => _showSessionHelp(context, strings),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 学習範囲の選択（新規のみ / 復習のみ / 両方）。合計はこの選択で変わる。
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<StudyScope>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: AppTheme.captionText,
              ),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: StudyScope.newOnly,
                    label: Text(strings.studyScopeNewOnly)),
                ButtonSegment(
                    value: StudyScope.reviewOnly,
                    label: Text(strings.studyScopeReviewOnly)),
                ButtonSegment(
                    value: StudyScope.both,
                    label: Text(strings.studyScopeBoth)),
              ],
              selected: {scope},
              onSelectionChanged: (s) =>
                  ref.read(settingsProvider.notifier).setStudyScope(s.first),
            ),
          ),
          const SizedBox(height: 14),
          // 新規（復習のみ選択時は薄く）
          Opacity(
            opacity: scope == StudyScope.reviewOnly ? 0.35 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.bolt_rounded,
                  iconColor: AppTheme.primary,
                  label: strings.newCards,
                  value: strings.newCardsRemainingOfLimit(
                      info.newCardsCount, info.newCardsLimit),
                ),
                if (info.newCardsStudiedToday > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 2, bottom: 2),
                    child: Text(
                      strings.newCardsStudiedNote(info.newCardsStudiedToday),
                      style: AppTheme.captionText,
                    ),
                  ),
              ],
            ),
          ),
          // 復習（新規のみ選択時は薄く）
          Opacity(
            opacity: scope == StudyScope.newOnly ? 0.35 : 1.0,
            child: _InfoRow(
              icon: Icons.refresh_rounded,
              iconColor: AppTheme.ratingUncertain,
              label: strings.reviewCards,
              value: strings.cardsCount(info.reviewCardsCount),
            ),
          ),
          const Divider(height: 22),
          // 合計（＝選んだ範囲の枚数）
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(strings.sessionTotalLabel, style: AppTheme.bodyText),
              const SizedBox(width: 8),
              Text(
                strings.cardsCount(scopedTotal),
                style: AppTheme.monoNumberLarge.copyWith(
                  color: AppTheme.primary,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 操作ボタン群もこのカード内にまとめる（学習を始める / 範囲指定 / もう一度復習）
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  // 新規カードを設定枚数だけ出題する通常セッション
                  label: strings.startLearning,
                  icon: Icons.play_arrow_rounded,
                  onPressed:
                      info.totalCount > 0 ? () => context.push('/study') : null,
                ),
              ),
              const SizedBox(width: 10),
              // カテゴリと番号範囲を指定して学習する（範囲フィルタ）
              OutlinedButton(
                onPressed: () => showRangeStudySheet(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(56, AppTheme.buttonHeight),
                ),
                child: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              // 今日学習したカードだけをもう一度出題する
              onPressed: info.practiceCardsCount > 0
                  ? () => context.push('/study?mode=practice')
                  : null,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                '${strings.reviewAgain} (${info.practiceCardsCount})',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「今日のセッション」タイトル横に置く小さな完了マーク。
/// 以前は大きな緑バナーで別枠表示していたが、控えめにカード内へ収めた。
class _SessionDoneChip extends StatelessWidget {
  final String label;
  const _SessionDoneChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.ratingRemembered.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 13, color: AppTheme.ratingRemembered),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.captionText.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.ratingRemembered,
            ),
          ),
        ],
      ),
    );
  }
}

/// 「今日のセッション」の各要素の意味を説明するヘルプシート。
/// 仕様が分かりにくいので「?」ボタンから開けるようにする。
void _showSessionHelp(BuildContext context, AppStrings strings) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.surface,
    isScrollControlled: true,
    // 全画面まで伸びると閉じ方が分かりにくいので、画面の下2/3までに抑える
    // （上1/3は元の画面が見える）。中身が長ければ内部スクロールで対応。
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.66,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(strings.sessionHelpTitle, style: AppTheme.headingMedium),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in strings.sessionHelpEntries())
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 3, right: 6),
                                    child: Icon(Icons.chevron_right_rounded,
                                        size: 18, color: AppTheme.primary),
                                  ),
                                  Expanded(
                                    child: Text(
                                      e.key,
                                      style: AppTheme.bodyText.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 24),
                                child: Text(e.value, style: AppTheme.bodyText),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AllMasteredCard extends StatelessWidget {
  final AppStrings strings;

  const _AllMasteredCard({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: AppTheme.cardPadding,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            border: Border.all(color: AppTheme.primary),
          ),
          child: Text(
            strings.allMastered,
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => context.push('/study'),
          child: Text(strings.reviewWeakCards),
        ),
      ],
    );
  }
}

/// 直近7日の学習状況を棒グラフで表示するカード
class _WeeklySummaryCard extends StatelessWidget {
  final List<DayStudy> days;
  final AppStrings strings;

  const _WeeklySummaryCard({required this.days, required this.strings});

  String _dayLabel(DateTime date) {
    // DateTime.weekday は 月=1..日=7
    if (strings.mode == LanguageMode.ja) {
      const labels = ['月', '火', '水', '木', '金', '土', '日'];
      return labels[date.weekday - 1];
    }
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final maxCount =
        days.fold<int>(0, (max, d) => d.cardsStudied > max ? d.cardsStudied : max);

    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.weeklyTitle, style: AppTheme.headingMedium),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in days)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (day.cardsStudied > 0)
                        Text(
                          '${day.cardsStudied}',
                          style: AppTheme.monoLabel.copyWith(
                            fontSize: 10,
                            color: AppTheme.primary,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Container(
                        height: maxCount > 0 && day.cardsStudied > 0
                            ? 8 + 42.0 * day.cardsStudied / maxCount
                            : 4,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          gradient: day.cardsStudied > 0 && day.isToday
                              ? AppTheme.primaryGradient
                              : null,
                          color: day.cardsStudied > 0
                              ? (day.isToday
                                  ? null
                                  : AppTheme.primary.withOpacity(0.35))
                              : AppTheme.surfaceBorder,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dayLabel(day.date),
                        style: AppTheme.captionText.copyWith(
                          fontSize: 11,
                          fontWeight:
                              day.isToday ? FontWeight.w700 : FontWeight.w400,
                          color: day.isToday
                              ? AppTheme.primary
                              : AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _InfoRow({
    this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? AppTheme.textTertiary),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(label, style: AppTheme.bodyText)),
          Text(value, style: AppTheme.monoNumber),
        ],
      ),
    );
  }
}

extension _ObjectExtension<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

/// ホームAppBar常駐のダッキー。今日学習済みならご機嫌（happy）で弾む。
/// タップでランダムな一言（応援・Tips）を SnackBar で話す。
class _HomeDuck extends ConsumerWidget {
  const _HomeDuck();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final studiedToday = ref
            .watch(dailySessionInfoProvider)
            .asData
            ?.value
            .hasStudiedToday ??
        false;
    return Semantics(
      label: strings.duckName,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          final lines = strings.duckLines;
          final line = lines[math.Random().nextInt(lines.length)];
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('🦆 $line')));
        },
        child: DuckMascot(
          size: 40,
          mood: studiedToday ? DuckMood.happy : DuckMood.idle,
        ),
      ),
    );
  }
}
