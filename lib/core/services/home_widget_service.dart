import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ship_it_english/core/services/streak_manager.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/features/study/domain/skill_score.dart';

/// iOSホーム画面ウィジェットへのデータ供給。
///
/// App Group の UserDefaults にストリーク・今日の学習・カバレッジを書き、
/// WidgetKit にタイムライン更新を要求するだけ（**通信なし**・
/// 「データ収集なし」申告に影響しない）。アプリを開かない日もホーム画面に
/// 🔥ストリークが見える＝Duolingoのウィジェットと同じ継続効果を狙う。
class HomeWidgetService {
  static const String appGroupId = 'group.jp.co.shipitenglish.app';
  static const String iosWidgetName = 'ShipItWidget';

  /// 現在の学習状態を集めてウィジェットに反映する。
  /// 失敗してもアプリの動作には影響させない（ウィジェットは飾り）。
  static Future<void> sync(LocalCardRepository repo) async {
    try {
      final todayStr = DateTime.now().toDateString();
      final streak = await StreakManager().getStreakCount();
      final studiedToday = await repo.getCardsStudiedToday(todayStr);
      final counts = await repo.getStatusCounts();
      final score = SkillScore(
        newCount: counts['new'] ?? 0,
        learningCount: counts['learning'] ?? 0,
        reviewCount: counts['review'] ?? 0,
        masteredCount: counts['mastered'] ?? 0,
      );

      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<int>('hw_streak', streak);
      await HomeWidget.saveWidgetData<int>('hw_today', studiedToday);
      await HomeWidget.saveWidgetData<int>(
          'hw_goal', GamificationConfig.dailyGoalCards);
      await HomeWidget.saveWidgetData<double>('hw_score', score.percent);
      await HomeWidget.updateWidget(iOSName: iosWidgetName);
    } catch (e) {
      debugPrint('[HomeWidgetService] sync failed: $e');
    }
  }
}
