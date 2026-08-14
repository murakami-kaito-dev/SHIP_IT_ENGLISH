import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/services/notification_service.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';

/// OSレベルで通知が許可されているか。
///
/// アプリ内のトグルがオンでも、OS側で切られていれば1通も届かない。
/// 設定画面はこの値を見て「オンと表示されているのに鳴らない」状態を避ける。
///
/// iOSの許可はアプリの外（設定アプリ）で変えられるため、起動時に一度読むだけ
/// では足りない。`app.dart` がフォアグラウンド復帰のたびに [refresh] を呼ぶ。
class NotificationPermissionNotifier extends StateNotifier<bool> {
  final Ref _ref;

  /// 判定できるまでは true（＝制限なし）で始める。
  /// false 始まりにすると、起動直後の一瞬だけ警告バナーが出てしまう。
  NotificationPermissionNotifier(this._ref) : super(true) {
    refresh();
  }

  Future<void> refresh() async {
    final service = NotificationService();
    final enabled = await service.isSystemNotificationEnabled();
    final recovered = enabled && !state;

    if (!mounted) return;
    state = enabled;

    // 拒否→許可に変わったら予約を組み直す。許可が無い間のスケジュールは
    // OSに黙って捨てられているので、そのままでは通知が復活しない。
    if (recovered) {
      final studiedToday = await _ref
          .read(cardRepositoryProvider)
          .hasStudiedToday(DateTime.now().toDateString());
      await service.rescheduleAll(studiedToday: studiedToday);
    }
  }
}

final notificationPermissionProvider =
    StateNotifierProvider<NotificationPermissionNotifier, bool>(
      (ref) => NotificationPermissionNotifier(ref),
    );
