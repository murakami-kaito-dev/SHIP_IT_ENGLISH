import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/services/notification_service.dart';
import 'package:ship_it_english/core/services/streak_manager.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';
import 'package:ship_it_english/features/study/data/card_repository.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:ship_it_english/features/study/domain/srs_engine.dart';

enum StudyPhase { studying, completed }

class SessionResult {
  final int studiedCount;
  final int correctCount;
  final int newCardsCount;
  final int reviewCardsCount;
  final Duration duration;
  final int streakCount;

  /// 全カードを1回で「覚えてた」で終えた（パーフェクトセッション）。
  /// 完了画面でPERFECT演出＋ボーナスXPの対象になる。
  final bool perfect;

  const SessionResult({
    required this.studiedCount,
    required this.correctCount,
    required this.newCardsCount,
    required this.reviewCardsCount,
    required this.duration,
    required this.streakCount,
    this.perfect = false,
  });
}

class StudySessionState {
  final List<TechCard> queue;
  final TechCard? currentCard;
  final bool isFlipped;
  final int completedUniqueCount;
  final int totalUniqueCount;
  final StudySession session;
  final Map<String, int> retryCount;
  final StudyPhase phase;
  final Set<String> newCardIds;
  final Set<String> reviewCardIds;

  /// 表示中カードの現在のSRS状態。評価ボタンに「各評価を選んだら次はいつ復習
  /// するか」を表示するために使う。カードをめくったときに読み込む。
  final LearningProgress? currentProgress;

  /// ユニットテスト（卒業テスト）モード。true のとき「忘れた」でも
  /// 再出題しない（1周で終えてミス数を数え、合否を判定する）。
  final bool unitTest;

  const StudySessionState({
    required this.queue,
    required this.currentCard,
    required this.isFlipped,
    required this.completedUniqueCount,
    required this.totalUniqueCount,
    required this.session,
    required this.retryCount,
    required this.phase,
    required this.newCardIds,
    required this.reviewCardIds,
    this.currentProgress,
    this.unitTest = false,
  });

  /// currentCard を「変更なし」と「null にする」で区別するためのセンチネル。
  /// `currentCard: null` を渡すと本当に null になる（セッション完了時に必要）。
  static const Object _keep = Object();

  StudySessionState copyWith({
    List<TechCard>? queue,
    Object? currentCard = _keep,
    bool? isFlipped,
    int? completedUniqueCount,
    int? totalUniqueCount,
    StudySession? session,
    Map<String, int>? retryCount,
    StudyPhase? phase,
    Set<String>? newCardIds,
    Set<String>? reviewCardIds,
    Object? currentProgress = _keep,
    bool? unitTest,
  }) {
    return StudySessionState(
      queue: queue ?? this.queue,
      currentCard: identical(currentCard, _keep)
          ? this.currentCard
          : currentCard as TechCard?,
      isFlipped: isFlipped ?? this.isFlipped,
      completedUniqueCount: completedUniqueCount ?? this.completedUniqueCount,
      totalUniqueCount: totalUniqueCount ?? this.totalUniqueCount,
      session: session ?? this.session,
      retryCount: retryCount ?? this.retryCount,
      phase: phase ?? this.phase,
      newCardIds: newCardIds ?? this.newCardIds,
      reviewCardIds: reviewCardIds ?? this.reviewCardIds,
      currentProgress: identical(currentProgress, _keep)
          ? this.currentProgress
          : currentProgress as LearningProgress?,
      unitTest: unitTest ?? this.unitTest,
    );
  }
}

class StudySessionNotifier extends StateNotifier<StudySessionState> {
  final CardRepository _repo;
  final SrsEngine _srs;

  StudySessionNotifier(this._repo, this._srs)
    : super(
        StudySessionState(
          queue: [],
          currentCard: null,
          isFlipped: false,
          completedUniqueCount: 0,
          totalUniqueCount: 0,
          session: StudySession(startedAt: DateTime.now()),
          retryCount: {},
          phase: StudyPhase.studying,
          newCardIds: {},
          reviewCardIds: {},
        ),
      );

  /// [categoryId] を指定するとそのカテゴリのカードだけでセッションを組む
  /// （復習期限が来ているカード + 未学習カード。ストリーク・統計には通常どおり反映）
  ///
  /// [allowedNewCategories] は無料プランのゲート（新規カードの出所を無料
  /// カテゴリに限定する）。復習カードは既存の学習進捗を守るため制限しない。
  Future<void> loadSession({
    required int maxNewCards,
    String? categoryId,
    Set<String>? allowedNewCategories,
    StudyScope scope = StudyScope.both,
  }) async {
    final today = DateTime.now();
    // 学習範囲: reviewOnly は新規を、newOnly は復習を除外する（SRSの予定日は不変）。
    final reviewCards = scope == StudyScope.newOnly
        ? <TechCard>[]
        : await _repo.getCardsForReview(today, categoryId: categoryId);

    // その日の新規カード枠は「1日の上限 − 今日すでに学習した新規」。
    // 途中でやめて再開しても、消化した分だけ残り枠が減る（0/40 に戻らない）。
    var remainingNew = scope == StudyScope.reviewOnly ? 0 : maxNewCards;
    final repo = _repo;
    if (scope != StudyScope.reviewOnly && repo is LocalCardRepository) {
      final studiedNewToday =
          await repo.getNewCardsStudiedToday(today.toDateString());
      remainingNew = (maxNewCards - studiedNewToday).clamp(0, maxNewCards);
    }
    final newCards = await _repo.getNewCards(
      limit: remainingNew,
      categoryId: categoryId,
      allowedCategories: allowedNewCategories,
    );

    final allCards = [...reviewCards, ...newCards]..shuffle();

    final newCardIds = newCards.map((c) => c.id).toSet();
    final reviewCardIds = reviewCards.map((c) => c.id).toSet();

    state = state.copyWith(
      queue: allCards,
      currentCard: allCards.isNotEmpty ? allCards.first : null,
      totalUniqueCount: allCards.length,
      completedUniqueCount: 0,
      isFlipped: false,
      session: StudySession(startedAt: DateTime.now()),
      retryCount: {},
      phase: StudyPhase.studying,
      newCardIds: newCardIds,
      reviewCardIds: reviewCardIds,
      unitTest: false,
    );
  }

  /// 「もう一度復習」用のセッション。
  /// SRSの次回予定日を待たず、今日学習した未習得カード＋期限切れカードを
  /// 苦手な順に出題する（評価結果は通常どおりSRSに反映される）。
  Future<void> loadPracticeSession({
    required int limit,
    Set<String>? allowedCategories,
  }) async {
    final repo = _repo;
    if (repo is! LocalCardRepository) return;

    final cards = await repo.getPracticeCards(
      limit: limit,
      todayStr: DateTime.now().toDateString(),
      allowedCategories: allowedCategories,
    );

    state = state.copyWith(
      queue: cards,
      currentCard: cards.isNotEmpty ? cards.first : null,
      totalUniqueCount: cards.length,
      completedUniqueCount: 0,
      isFlipped: false,
      session: StudySession(startedAt: DateTime.now()),
      retryCount: {},
      phase: StudyPhase.studying,
      newCardIds: {},
      reviewCardIds: cards.map((c) => c.id).toSet(),
      unitTest: false,
    );
  }

  /// カテゴリ学習セッション。
  /// カテゴリ内の通し番号 [from]〜[to]、学習状況 [statuses]（空なら全状況）で絞り、
  /// [random] で番号順／ランダム順を切り替えて出題する。
  /// 枚数の上限はなく、条件に一致する全カードが対象。評価は通常どおりSRSに反映される。
  Future<void> loadCategoryStudySession({
    required String categoryId,
    required int from,
    required int to,
    required Set<String> statuses,
    required bool random,
  }) async {
    final repo = _repo;
    if (repo is! LocalCardRepository) return;

    final cards = await repo.getCategoryStudyCards(
      categoryId: categoryId,
      from: from,
      to: to,
      statuses: statuses,
      random: random,
    );

    state = state.copyWith(
      queue: cards,
      currentCard: cards.isNotEmpty ? cards.first : null,
      totalUniqueCount: cards.length,
      completedUniqueCount: 0,
      isFlipped: false,
      session: StudySession(startedAt: DateTime.now()),
      retryCount: {},
      phase: StudyPhase.studying,
      newCardIds: {},
      reviewCardIds: cards.map((c) => c.id).toSet(),
      unitTest: false,
    );
  }

  /// ユニットテスト（卒業テスト）セッション。
  /// カテゴリ内の通し番号 [from]〜[to] の全カードをランダム順に**1周だけ**出題する
  /// （「忘れた」でも再出題しない）。評価は通常どおりSRSに反映される。
  Future<void> loadUnitTestSession({
    required String categoryId,
    required int from,
    required int to,
  }) async {
    final repo = _repo;
    if (repo is! LocalCardRepository) return;

    final cards = await repo.getCategoryStudyCards(
      categoryId: categoryId,
      from: from,
      to: to,
      statuses: const {},
      random: true,
    );

    state = state.copyWith(
      queue: cards,
      currentCard: cards.isNotEmpty ? cards.first : null,
      totalUniqueCount: cards.length,
      completedUniqueCount: 0,
      isFlipped: false,
      session: StudySession(startedAt: DateTime.now()),
      retryCount: {},
      phase: StudyPhase.studying,
      newCardIds: {},
      reviewCardIds: cards.map((c) => c.id).toSet(),
      unitTest: true,
    );
  }

  Future<void> flipCard() async {
    if (state.isFlipped) return;
    final card = state.currentCard;
    // 評価ボタンに次回復習間隔を出すため、めくった時点で現在のSRS状態を読む
    // （新規カードは進捗が無いので初期値）。フリップ表示と同時に反映させる。
    final progress = card == null
        ? null
        : (await _repo.getProgress(card.id) ??
            LearningProgress.initial(card.id));
    state = state.copyWith(isFlipped: true, currentProgress: progress);
  }

  Future<void> rateCard(Rating rating) async {
    final card = state.currentCard;
    if (card == null || !state.isFlipped) return;

    // 現在の学習進捗を取得（なければ初期値）
    final progress =
        await _repo.getProgress(card.id) ??
        LearningProgress.initial(card.id);

    final updated = _srs.processReview(current: progress, rating: rating);
    await _repo.saveProgress(updated);

    final isRetry = (state.retryCount[card.id] ?? 0) > 0;
    final result = CardResult(
      cardId: card.id,
      rating: rating,
      answeredAt: DateTime.now(),
      isRetry: isRetry,
    );
    state.session.results.add(result);

    final newQueue = List<TechCard>.from(state.queue.skip(1));
    final newRetryCount = Map<String, int>.from(state.retryCount);

    // 「忘れた」の場合: キュー末尾に再追加（上限2回まで）。
    // ユニットテストは1周で合否を判定するため再出題しない。
    if (rating == Rating.forgot && !state.unitTest) {
      final currentRetries = newRetryCount[card.id] ?? 0;
      if (currentRetries < AppConstants.maxRetriesPerSession) {
        newQueue.add(card);
        newRetryCount[card.id] = currentRetries + 1;
      }
    }

    // 再出題でなければ完了カウントを増やす
    final newCompletedCount =
        isRetry
            ? state.completedUniqueCount
            : state.completedUniqueCount + 1;

    if (newQueue.isEmpty) {
      state = state.copyWith(
        queue: newQueue,
        currentCard: null,
        isFlipped: false,
        completedUniqueCount: newCompletedCount,
        retryCount: newRetryCount,
        phase: StudyPhase.completed,
      );
    } else {
      state = state.copyWith(
        queue: newQueue,
        currentCard: newQueue.first,
        isFlipped: false,
        completedUniqueCount: newCompletedCount,
        retryCount: newRetryCount,
        // 次のカードをめくるまで前カードの間隔予測を消す
        currentProgress: null,
      );
    }
  }

  Future<SessionResult> buildSessionResult() async {
    final session = state.session;
    final results = session.results;

    // ユニークカードごとの最終評価を集計
    final latestRatings = <String, Rating>{};
    for (final r in results) {
      latestRatings[r.cardId] = r.rating;
    }

    final studiedCount = latestRatings.length;
    final correctCount = latestRatings.values
        .where(
          (r) => r == Rating.remembered || r == Rating.uncertain,
        )
        .length;

    // 新規/復習の仕訳
    int newCount = 0;
    int reviewCount = 0;
    for (final cardId in latestRatings.keys) {
      if (state.newCardIds.contains(cardId)) {
        newCount++;
      } else {
        reviewCount++;
      }
    }

    // ストリーク更新
    await StreakManager().recordStudyCompletion();
    final streakCount = await StreakManager().getStreakCount();

    // 今日は学習済みなので、今夜のストリーク危機通知は不要
    await NotificationService().cancelStreakReminderForToday();

    // daily_stats に保存
    final todayStr = session.startedAt.toDateString();
    await _repo.saveDailyStats(
      DailyStats(
        date: todayStr,
        cardsStudied: studiedCount,
        cardsCorrect: correctCount,
        newCards: newCount,
        reviewCards: reviewCount,
        studyTimeSeconds: session.duration.inSeconds,
      ),
    );

    return SessionResult(
      studiedCount: studiedCount,
      correctCount: correctCount,
      newCardsCount: newCount,
      reviewCardsCount: reviewCount,
      duration: session.duration,
      streakCount: streakCount,
      perfect: isPerfectSession(
        results: results,
        uniqueCount: latestRatings.length,
        unitTest: state.unitTest,
        minCards: GamificationConfig.perfectMinCards,
      ),
    );
  }
}

final studySessionProvider = StateNotifierProvider.autoDispose<
    StudySessionNotifier,
    StudySessionState
>((ref) {
  final repo = ref.watch(cardRepositoryProvider);
  final srs = ref.watch(srsEngineProvider);
  return StudySessionNotifier(repo, srs);
});

final lastSessionResultProvider = StateProvider<SessionResult?>((ref) => null);

final studyModeProvider = Provider<int>((ref) {
  final configured = ref.watch(settingsProvider).newCardsPerDay;
  // 「今日だけ追加で学ぶ」の当日限りの枠（日付が変わると0に戻る）
  final extraToday = ref.watch(todayExtraNewCardsProvider);
  // 無料プランは新規カード枚数に上限がかかる（サブスク無効時は素通し）
  if (!ref.watch(isProProvider)) {
    return configured.clamp(0, MonetizationConfig.freeMaxNewCardsPerDay) +
        extraToday;
  }
  return configured + extraToday;
});
