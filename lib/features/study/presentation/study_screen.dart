import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/providers/progress_refresh.dart';
import 'package:ship_it_english/core/services/sound_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/combo_overlay.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/fever_frame.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/level_up_modal.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/sparkle_burst.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/xp_gain_popup.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/xp_progress_bar.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:ship_it_english/features/study/presentation/widgets/flip_card.dart';
import 'package:ship_it_english/features/study/presentation/widgets/rating_buttons.dart';
import 'package:ship_it_english/features/study/presentation/widgets/swipe_card_wrapper.dart';
import 'package:ship_it_english/features/study/providers/study_providers.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';

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

  // === ゲーミフィケーション演出用の一時状態 ===
  /// 直近の評価結果（コンボ数・獲得XP・FEVER・レベルアップ判定）。
  AnswerOutcome? _lastOutcome;

  /// エフェクト（XP+ポップ・スパークル）を作り直すためのキー。
  /// 評価のたびに +1 して XpFlyToBar / SparkleBurst を再生する。
  int _effectTick = 0;

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
        // 「もう一度復習」＝今日学習したカードを重複なく全部出題（枚数上限なし）。
        // ボタンの件数（getPracticeCardsCount・全件）と一致させる。
        await notifier.loadPracticeSession(
          limit: 100000,
          allowedCategories: allowed,
        );
      } else {
        // 今日のセッションは学習範囲（新規のみ/復習のみ/両方）を設定から反映
        await notifier.loadSession(
          maxNewCards: maxNew,
          categoryId: widget.categoryId,
          allowedNewCategories: allowed,
          scope: ref.read(settingsProvider).studyScope,
        );
      }
      // 新しいセッションの開始時はコンボ・セッションXPをリセットする
      ref.read(gamificationProvider.notifier).startSession();
      if (mounted) setState(() => _loaded = true);
    });
  }

  /// 完了処理が二重に走らないためのガード。
  /// これが無いと、遷移が完了する前にもう一度評価されたときに
  /// _completeSession が多重起動してしまう。
  bool _completing = false;

  Future<void> _handleRating(Rating rating) async {
    final notifier = ref.read(studySessionProvider.notifier);

    // 「1回で正解」か（＝コンボ対象）を評価前に判定する。
    // rateCard 内では再出題カードの retryCount が >0 になっている。
    final before = ref.read(studySessionProvider);
    final cardId = before.currentCard?.id;
    final firstTry = cardId == null || (before.retryCount[cardId] ?? 0) == 0;

    await notifier.rateCard(rating);

    // XP/コンボ/FEVER を反映して演出を発火
    final outcome = await ref
        .read(gamificationProvider.notifier)
        .registerAnswer(rating: rating, firstTry: firstTry);
    _fireEffects(outcome);

    // レベルアップしたらモーダルで祝う（閉じるまで待ってから完了処理へ）
    if (outcome.leveledUp && mounted) {
      final strings = ref.read(stringsProvider);
      await showLevelUpModal(
        context,
        newLevel: outcome.newLevel,
        title: strings.levelUpTitle,
        levelLabel: strings.levelWord,
        continueLabel: strings.continueButton,
        rankLabel: strings.rankName(rankForLevel(outcome.newLevel)),
      );
    }

    if (ref.read(studySessionProvider).phase == StudyPhase.completed) {
      await _completeSession();
    }
  }

  /// 評価結果に応じて音・振動・オーバーレイを発火する。
  void _fireEffects(AnswerOutcome outcome) {
    final sound = SoundService.instance;
    if (outcome.rating == Rating.forgot) {
      sound.retry(); // 暗い音は出さない（負の感情の軽減）
    } else if (outcome.fever) {
      sound.fever();
    } else if (outcome.combo >= 2) {
      sound.combo(outcome.combo);
    } else {
      sound.correct();
    }
    if (mounted) {
      setState(() {
        _lastOutcome = outcome;
        _effectTick++;
      });
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
          // 進捗の数字。単位（枚）を付け、残り枚数を添える。
          // 「9 / 15」だけでは何の数か分からず、真上のXP（171/180）と混同する。
          title: Semantics(
            label:
                '${state.completedUniqueCount} of ${state.totalUniqueCount} cards',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${state.completedUniqueCount}',
                        style: AppTheme.monoNumber.copyWith(fontSize: 18),
                      ),
                      TextSpan(
                        text: ' / ${strings.cardsCount(state.totalUniqueCount)}',
                        style: AppTheme.monoNumber.copyWith(
                          fontSize: 13,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  strings.remainingCards(
                    (state.totalUniqueCount - state.completedUniqueCount)
                        .clamp(0, state.totalUniqueCount),
                  ),
                  style: AppTheme.captionText.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          // セッション進捗は「ページ全体の進み具合」なので、AppBar直下の全幅
          // ヘアラインで表す。XPバー（カード状の面）と形が別物になり混同しない。
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: state.totalUniqueCount > 0
                    ? state.completedUniqueCount / state.totalUniqueCount
                    : 0,
                minHeight: 4,
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceBorder,
              ),
            ),
          ),
        ),
        body: state.currentCard == null
            ? const SizedBox.shrink()
            : Stack(
                children: [
                  Column(
                children: [
                  // XPゲージ（レベル＋経験値＋次の到達点。FEVER中は炎色に発光）。
                  // セッション進捗は AppBar 直下のヘアラインへ移したので、
                  // ここに横棒を2本並べない（同じ形が並ぶと区別できないため）。
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                    child: XPProgressBar(
                      fever: _lastOutcome?.fever ?? false,
                      combo: _lastOutcome?.combo ?? 0,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: AppTheme.screenPadding,
                      child: Stack(
                        children: [
                          SwipeCardWrapper(
                            isFlipped: state.isFlipped,
                            onSwipe: _handleRating,
                            child: FlipCard(
                              card: state.currentCard!,
                              isFlipped: state.isFlipped,
                              mode: mode,
                              onFlip: () => ref
                                  .read(studySessionProvider.notifier)
                                  .flipCard(),
                            ),
                          ),
                          // 正解時のスパークル（カード中心から弾ける）
                          if (_lastOutcome?.isCorrect ?? false)
                            Positioned.fill(
                              key: ValueKey('spark$_effectTick'),
                              child: SparkleBurst(
                                color: _lastOutcome!.fever
                                    ? AppTheme.streakFire
                                    : AppTheme.ratingRemembered,
                                count:
                                    (8 + _lastOutcome!.combo * 2).clamp(8, 26),
                              ),
                            ),
                          // COMBO 表示（中央上）
                          Positioned(
                            top: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: ComboOverlay(
                                  combo: _lastOutcome?.combo ?? 0),
                            ),
                          ),
                          // 「どんまい！」（中央）。XP獲得ポップはカードのStackだと
                          // クリップされてバーまで飛べないため、外側のStackへ移した。
                          Positioned(
                            top: 96,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _lastOutcome?.rating == Rating.forgot
                                  ? _KeepGoingChip(
                                      key: ValueKey('kg$_effectTick'),
                                      text: strings.keepGoing,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
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
                  // 獲得XPがカード付近から立ち上がり、上のXPバーへ吸い込まれる。
                  // カード内のStackはクリップされるため、外側のStackに置く。
                  if (_lastOutcome != null && _lastOutcome!.xpGained > 0)
                    Positioned.fill(
                      child: XpFlyToBar(
                        key: ValueKey('xpfly$_effectTick'),
                        amount: _lastOutcome!.xpGained,
                        fever: _lastOutcome!.fever,
                        // 終点＝XPバーの中心（上パディング10 + カード高の約半分）
                        endTop: 34,
                      ),
                    ),
                  // FEVER中は画面枠がパルス発光する
                  Positioned.fill(
                    child: FeverFrame(
                        active: _lastOutcome?.fever ?? false),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

/// 「どんまい！」の前向きなナッジ（不正解時）。elasticOut でポップして
/// 数百ミリ秒後にフェードアウトする。暗い印象を与えない（SKILL: 負の感情の軽減）。
class _KeepGoingChip extends StatefulWidget {
  final String text;
  const _KeepGoingChip({super.key, required this.text});

  @override
  State<_KeepGoingChip> createState() => _KeepGoingChipState();
}

class _KeepGoingChipState extends State<_KeepGoingChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          final scale = 0.7 + 0.3 * Curves.elasticOut.transform(t.clamp(0, 1));
          final opacity =
              t < 0.15 ? t / 0.15 : (t < 0.75 ? 1.0 : (1.0 - (t - 0.75) / 0.25));
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.ratingUncertain.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.ratingUncertain, width: 1.4),
          ),
          child: Text(
            '😉 ${widget.text}',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.ratingUncertain,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
