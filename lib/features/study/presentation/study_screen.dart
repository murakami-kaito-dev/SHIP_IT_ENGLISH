import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/providers/progress_refresh.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:ship_it_english/features/study/presentation/widgets/flip_card.dart';
import 'package:ship_it_english/features/study/presentation/widgets/rating_buttons.dart';
import 'package:ship_it_english/features/study/presentation/widgets/swipe_card_wrapper.dart';
import 'package:ship_it_english/features/study/providers/study_providers.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';
import 'package:ship_it_english/shared/widgets/progress_bar.dart';

class StudyScreen extends ConsumerStatefulWidget {
  /// nullなら通常のデイリーセッション。指定するとそのカテゴリのみで学習
  final String? categoryId;

  /// true なら「もう一度復習」モード（SRSの予定日を待たずに
  /// 今日学習した未習得カード＋期限切れカードを苦手な順に出題）
  final bool practice;

  /// カテゴリ学習: [rangeFrom]〜[rangeTo] が両方あり categoryId があるとき、
  /// そのカテゴリを [statuses] の学習状況・[random] の順序で学習する
  final int? rangeFrom;
  final int? rangeTo;

  /// 学習状況フィルタ（'new','forgot','uncertain','remembered'。空=全状況）
  final Set<String> statuses;

  /// true でランダム順、false で番号の若い順
  final bool random;

  const StudyScreen({
    super.key,
    this.categoryId,
    this.practice = false,
    this.rangeFrom,
    this.rangeTo,
    this.statuses = const {},
    this.random = false,
  });

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final maxNew = ref.read(studyModeProvider);
      final isPro = ref.read(isProProvider);
      // 無料プランの出題は無料カテゴリに限定する
      final allowed = isPro ? null : MonetizationConfig.freeCategoryIds;
      final notifier = ref.read(studySessionProvider.notifier);

      if (widget.rangeFrom != null &&
          widget.rangeTo != null &&
          widget.categoryId != null) {
        await notifier.loadCategoryStudySession(
          categoryId: widget.categoryId!,
          from: widget.rangeFrom!,
          to: widget.rangeTo!,
          statuses: widget.statuses,
          random: widget.random,
        );
      } else if (widget.practice) {
        await notifier.loadPracticeSession(
          limit: AppConstants.maxNewCardsPerDay,
          allowedCategories: allowed,
        );
      } else {
        await notifier.loadSession(
          maxNewCards: maxNew,
          categoryId: widget.categoryId,
          allowedNewCategories: allowed,
        );
      }
      if (mounted) setState(() => _loaded = true);
    });
  }

  /// 完了処理が二重に走らないためのガード。
  /// これが無いと、遷移が完了する前にもう一度評価されたときに
  /// _completeSession が多重起動してしまう。
  bool _completing = false;

  Future<void> _handleRating(Rating rating) async {
    final notifier = ref.read(studySessionProvider.notifier);
    await notifier.rateCard(rating);

    if (ref.read(studySessionProvider).phase == StudyPhase.completed) {
      await _completeSession();
    }
  }

  Future<void> _completeSession() async {
    if (_completing) return;
    _completing = true;

    // 集計の副作用（ストリーク更新・通知キャンセル・統計保存）が
    // 実機で失敗しても、必ず完了画面へ遷移させる。
    // ここで例外を握りつぶさないと context.go に到達できず、
    // 学習画面に留まって「終われない」状態になる。
    SessionResult? result;
    try {
      result =
          await ref.read(studySessionProvider.notifier).buildSessionResult();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Study] buildSessionResult failed (navigating anyway): $e');
      }
    }
    if (!mounted) return;
    ref.read(lastSessionResultProvider.notifier).state = result;
    context.go('/session-complete');
  }

  bool _exiting = false;

  /// セッションを途中で抜ける。
  /// 1枚も評価していなければ確認なしでそのまま戻る。評価済みがあれば確認の上、
  /// **その時点までの学習を記録してから**ホームへ戻る（最後までやらなくても
  /// 学習した分がストリーク・当日の統計・進捗に反映される）。
  Future<void> _exitSession() async {
    if (_exiting) return;
    final state = ref.read(studySessionProvider);

    // まだ何も評価していない → 記録するものは無いのでそのまま戻る
    if (state.completedUniqueCount == 0) {
      if (mounted) context.go('/');
      return;
    }

    final strings = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.exitDialogTitle),
        content: Text(strings.exitDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.exitDialogContinue),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              strings.exitDialogQuit,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _exiting = true;
    // 各カードのSRS状態は評価時に保存済みだが、当日の統計(daily_stats)と
    // ストリークは buildSessionResult でしか確定しない。途中離脱でも
    // ここで呼んで「途中まで学習した分」を今日の学習として記録する。
    try {
      await ref.read(studySessionProvider.notifier).buildSessionResult();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Study] partial save failed (leaving anyway): $e');
      }
    }
    invalidateProgressProviders(ref);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studySessionProvider);
    final strings = ref.watch(stringsProvider);
    final mode = ref.watch(languageModeProvider);

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 各評価を選んだら次はいつ復習するか（現在のSRS状態から予測）。
    // 表示中カードの状態はめくった時に読み込まれる（currentProgress）。
    final progress = state.currentProgress;
    final Map<Rating, Duration>? ratingIntervals = progress == null
        ? null
        : {
            for (final r in Rating.values)
              r: ref
                  .read(srsEngineProvider)
                  .projectedInterval(current: progress, rating: r),
          };

    // セッションに1枚もカードがない場合（カテゴリ学習で学習対象なし等）
    if (state.totalUniqueCount == 0 && state.phase == StudyPhase.studying) {
      return AppBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(strings.emptySession, style: AppTheme.bodyText),
            ],
          ),
        ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _exitSession();
      },
      child: AppBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _exitSession,
          ),
          title: Semantics(
            label:
                '${state.completedUniqueCount} of ${state.totalUniqueCount} cards',
            child: Text(
              '${state.completedUniqueCount} / ${state.totalUniqueCount}',
              style: AppTheme.monoNumber.copyWith(fontSize: 18),
            ),
          ),
        ),
        body: state.currentCard == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: ProgressBar(
                      value: state.totalUniqueCount > 0
                          ? state.completedUniqueCount /
                              state.totalUniqueCount
                          : 0,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: AppTheme.screenPadding,
                      child: SwipeCardWrapper(
                        isFlipped: state.isFlipped,
                        onSwipe: _handleRating,
                        child: FlipCard(
                          card: state.currentCard!,
                          isFlipped: state.isFlipped,
                          mode: mode,
                          onFlip: () =>
                              ref.read(studySessionProvider.notifier).flipCard(),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 96,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: state.isFlipped
                            ? Column(
                                key: const ValueKey('rating'),
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    strings.swipeHint,
                                    style: AppTheme.captionText,
                                  ),
                                  RatingButtons(
                                    strings: strings,
                                    onRate: _handleRating,
                                    intervals: ratingIntervals,
                                  ),
                                ],
                              )
                            : Center(
                                key: const ValueKey('hint'),
                                child: Text(
                                  strings.tapToFlip,
                                  style: AppTheme.captionText,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
