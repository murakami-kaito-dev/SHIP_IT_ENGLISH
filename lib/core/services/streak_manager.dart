import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';

class StreakManager {
  /// アプリ起動時に呼び出す
  /// 2日以上空いていればストリークをリセット。
  /// ただし**ストリーク保護（freeze）を所持していれば、空いた日数分を自動消費して
  /// 連続記録を維持する**（1日サボっても途切れさせない特典）。
  Future<void> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(AppConstants.keyLastStudyDate);
    final today = DateTime.now().toDateString();

    if (lastDateStr == null) return; // 初回起動

    final daysDiff = today.daysDifferenceTo(lastDateStr);
    if (daysDiff < 2) return; // 昨日までに学習済み＝継続

    // 空いた「まる1日」の数（daysDiff=2 で1日サボり）
    final missedDays = daysDiff - 1;
    final streak = prefs.getInt(AppConstants.keyStreakCount) ?? 0;
    final freezes = prefs.getInt(AppConstants.keyStreakFreezes) ?? 0;

    if (streak > 0 && freezes >= missedDays) {
      // 保護で埋められる：昨日学習したことにして連続を維持し、保護を消費する
      await prefs.setInt(AppConstants.keyStreakFreezes, freezes - missedDays);
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toDateString();
      await prefs.setString(AppConstants.keyLastStudyDate, yesterday);
      // ホームで「守りました」と一度だけ知らせるための保留カウント
      final pending =
          prefs.getInt(AppConstants.keyStreakFreezeUsedPending) ?? 0;
      await prefs.setInt(
          AppConstants.keyStreakFreezeUsedPending, pending + missedDays);
    } else {
      // 保護が足りない／無い → 従来どおりリセット
      await prefs.setInt(AppConstants.keyStreakCount, 0);
    }
  }

  /// 起動時の自動消費で「守った」枚数を取り出し、保留カウントを0に戻す。
  /// ホームが一度だけ通知に使う。
  Future<int> takeStreakFreezeUsedNotice() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(AppConstants.keyStreakFreezeUsedPending) ?? 0;
    if (n > 0) {
      await prefs.setInt(AppConstants.keyStreakFreezeUsedPending, 0);
    }
    return n;
  }

  /// セッション完了時に呼び出す
  Future<void> recordStudyCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toDateString();
    final lastDateStr = prefs.getString(AppConstants.keyLastStudyDate);

    if (lastDateStr != today) {
      final currentStreak = prefs.getInt(AppConstants.keyStreakCount) ?? 0;
      await prefs.setInt(AppConstants.keyStreakCount, currentStreak + 1);
      await prefs.setString(AppConstants.keyLastStudyDate, today);
    }
    // lastDateStr == today の場合: 2回目以降のセッション。ストリーク加算しない
  }

  /// 現在のストリーク数を取得
  Future<int> getStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyStreakCount) ?? 0;
  }
}
