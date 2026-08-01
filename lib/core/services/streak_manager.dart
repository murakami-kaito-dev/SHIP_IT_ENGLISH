import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';

class StreakManager {
  /// アプリ起動時に呼び出す
  /// 2日以上空いていればストリークをリセット
  Future<void> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(AppConstants.keyLastStudyDate);
    final today = DateTime.now().toDateString();

    if (lastDateStr == null) return; // 初回起動

    final daysDiff = today.daysDifferenceTo(lastDateStr);
    if (daysDiff >= 2) {
      await prefs.setInt(AppConstants.keyStreakCount, 0);
    }
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
