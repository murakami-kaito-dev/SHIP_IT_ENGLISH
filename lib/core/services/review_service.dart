import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';

/// App Store / Google Play のアプリ内レビューダイアログを表示する。
/// 表示条件: ストリークが一定日数以上 かつ 過去に依頼していないこと。
/// （OS側でも表示回数は年数回に制限されるため、二重に安全）
class ReviewService {
  Future<void> maybeRequestReview({required int streakCount}) async {
    if (streakCount < AppConstants.reviewRequestMinStreak) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.keyReviewRequested) ?? false) return;

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      await prefs.setBool(AppConstants.keyReviewRequested, true);
    }
  }
}
