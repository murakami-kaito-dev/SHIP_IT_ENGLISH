import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/services/streak_manager.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';

class DailySessionInfo {
  /// 今日のセッションで出題する新規カード数（＝今日の残り新規枠）
  final int newCardsCount;

  /// 1日に追加する新規カードの上限（設定値。無料プランはクランプ後）
  final int newCardsLimit;

  /// 今日すでに学習した新規カード数（残り枠が減った理由の明示に使う）
  final int newCardsStudiedToday;

  final int reviewCardsCount;
  final int totalCount;
  final int estimatedSeconds;
  final int streakCount;
  final bool hasStudiedToday;

  /// 今日学習したカードの総枚数（デイリー目標判定・ストリーク強発光用）。
  final int cardsStudiedToday;

  /// 「もう一度復習」で出題できる枚数
  /// （今日学習した未習得カード＋期限切れカード）
  final int practiceCardsCount;

  const DailySessionInfo({
    required this.newCardsCount,
    required this.newCardsLimit,
    required this.newCardsStudiedToday,
    required this.reviewCardsCount,
    required this.totalCount,
    required this.estimatedSeconds,
    required this.streakCount,
    required this.hasStudiedToday,
    required this.cardsStudiedToday,
    required this.practiceCardsCount,
  });
}

class OverallProgress {
  /// 21日間隔に到達した「習得済み」カード
  final int masteredCount;

  /// 一度でも学習したカード（学習中・復習中・習得済みの合計）
  final int studiedCount;
  final int totalCount;

  const OverallProgress({
    required this.masteredCount,
    required this.studiedCount,
    required this.totalCount,
  });

  /// 進捗バーは「学習に着手したカードの割合」を示す。
  /// mastered は到達に数週間かかるため、日々の手応えが出るこちらを使う。
  double get percentage => totalCount > 0 ? studiedCount / totalCount : 0.0;

  double get masteredPercentage =>
      totalCount > 0 ? masteredCount / totalCount : 0.0;
}

final dailySessionInfoProvider = FutureProvider<DailySessionInfo>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  final settings = ref.watch(settingsProvider);
  final isPro = ref.watch(isProProvider);
  final localRepo = repo as LocalCardRepository;

  final today = DateTime.now();
  final reviewCount = await localRepo.getReviewCardsCount(today);
  // 無料プランは新規カードの出所と枚数が制限される（サブスク無効時は素通し）
  final newCount = await localRepo.getNewCardsCount(
    allowedCategories: isPro ? null : MonetizationConfig.freeCategoryIds,
  );
  final planMax = isPro
      ? settings.newCardsPerDay
      : settings.newCardsPerDay
          .clamp(0, MonetizationConfig.freeMaxNewCardsPerDay);
  // その日の残り新規枠 = 1日の上限 − 今日すでに学習した新規カード。
  // 途中でやめて再開しても、消化した分だけ「今日のセッション」の新規が減る。
  final studiedNewToday =
      await localRepo.getNewCardsStudiedToday(today.toDateString());
  final maxNew = (planMax - studiedNewToday).clamp(0, planMax);
  final cappedNew = newCount.clamp(0, maxNew);
  final total = reviewCount + cappedNew;
  final streak = await StreakManager().getStreakCount();
  final hasStudied = await localRepo.hasStudiedToday(today.toDateString());
  final studiedTodayCount =
      await localRepo.getCardsStudiedToday(today.toDateString());
  final practiceCount = await localRepo.getPracticeCardsCount(
    todayStr: today.toDateString(),
    allowedCategories: isPro ? null : MonetizationConfig.freeCategoryIds,
  );

  return DailySessionInfo(
    newCardsCount: cappedNew,
    newCardsLimit: planMax,
    newCardsStudiedToday: studiedNewToday,
    reviewCardsCount: reviewCount,
    totalCount: total,
    estimatedSeconds: total * 30,
    streakCount: streak,
    hasStudiedToday: hasStudied,
    cardsStudiedToday: studiedTodayCount,
    practiceCardsCount: practiceCount,
  );
});

/// 直近7日の学習状況（ホームの週間サマリー用。古い日→今日の順）
class DayStudy {
  final DateTime date;
  final int cardsStudied;
  final bool isToday;

  const DayStudy({
    required this.date,
    required this.cardsStudied,
    required this.isToday,
  });
}

/// 今週（日曜始まり・土曜終わり）の学習状況。
/// 直近7日のローリングではなく暦の週で表示する。
final weeklyStatsProvider = FutureProvider<List<DayStudy>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;
  final counts = await repo.getRecentStudyCounts(days: 14);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // DateTime.weekday は月=1..日=7。日曜を週の先頭にするため 7 は 0 として扱う
  final offsetFromSunday = today.weekday % 7;
  final sunday = today.subtract(Duration(days: offsetFromSunday));

  return List.generate(7, (i) {
    final date = sunday.add(Duration(days: i));
    return DayStudy(
      date: date,
      cardsStudied: counts[date.toDateString()] ?? 0,
      isToday: date == today,
    );
  });
});

final overallProgressProvider = FutureProvider<OverallProgress>((ref) async {
  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;
  final mastered = await repo.getTotalMasteredCount();
  final studied = await repo.getStudiedCardCount();
  final total = await repo.getTotalCardCount();
  return OverallProgress(
    masteredCount: mastered,
    studiedCount: studied,
    totalCount: total,
  );
});
