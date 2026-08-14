import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 0;

  /// ストリーク危機通知のID。曜日ごとに 2001〜2007 を使う
  static const int _streakReminderBaseId = 2000;

  /// ストリーク危機通知のメッセージプール（毎回ランダムに選ばれる）
  static const List<String> _streakMessagesJa = [
    '🔥 まだ間に合います！今日の学習でストリークを守りましょう',
    '⏰ 今日の5分、まだ終わっていません。継続が途切れます！',
    '📚 今日のカードが待っています。寝る前にサクッと復習しませんか？',
    '🚀 Ship it! 今日の学習を終わらせてストリークを継続しよう',
    '😱 ストリークが今夜リセットされそうです。5分だけ学習しましょう！',
    '💪 継続は力なり。今日の分、まだ間に合います',
    '🧠 復習のベストタイミングです。忘れてしまう前に確認しましょう',
    '🌙 今日が終わる前に、少しだけ学習しませんか？',
    '☕️ たった5分。それでストリークが守れます',
    '🎯 あと1セッションで今日のノルマ達成です！',
  ];

  static const List<String> _streakMessagesEn = [
    "🔥 There's still time! Study now and keep your streak alive",
    "⏰ Your 5 minutes today aren't done yet. Don't break the chain!",
    '📚 Your cards are waiting. A quick review before bed?',
    '🚀 Ship it! Finish today\'s session and keep the streak going',
    '😱 Your streak resets tonight. Just 5 minutes will save it!',
    '💪 Consistency is everything. Today still counts',
    '🧠 Perfect timing for review — check your cards before you forget',
    '🌙 Before the day ends, how about a quick session?',
    '☕️ Just 5 minutes. That\'s all it takes to keep your streak',
    "🎯 One session left to hit today's goal!",
  ];

  Future<void> initialize() async {
    tz.initializeTimeZones();
    // 通知は「インストール端末のローカルタイムゾーン」でスケジュールする。
    // tz.initializeTimeZones() だけでは tz.local が UTC のままで、端末が日本でも
    // zonedSchedule が UTC 基準で組まれて時刻がずれる。端末の IANA タイムゾーン
    // （例: Asia/Tokyo / America/Los_Angeles）を検出して tz.local に設定すると、
    // どの国の端末でもその端末の時刻に同期して通知が鳴る（日本の端末→日本時間、
    // 米国の端末→米国時間）。main.dart が起動のたびに再スケジュールするので、
    // 端末のタイムゾーンが変わっても次回起動で正しい時刻へ組み直される。
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (e) {
      // 取得失敗はまれ。最低限のフォールバックとして日本時間を使う。
      if (kDebugMode) {
        print('[NotificationService] timezone detect failed: $e');
      }
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // DarwinInitializationSettings の requestAlertPermission などにより、
    // iOS では初回起動のこの時点でOSの許可ダイアログが出る。設定画面が
    // 「未決定」と「拒否済み」を取り違えないよう、要求済みとして記録する。
    // ※許可要求をオンボーディング後に移す場合は、この行も一緒に移すこと。
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotifPermissionRequested, true);
  }

  Future<LanguageMode> _languageMode() async {
    final prefs = await SharedPreferences.getInstance();
    return LanguageMode.fromString(
        prefs.getString(AppConstants.keyLanguageMode));
  }

  // ===========================================================
  // 1) 毎日の定時リマインダー（固定メッセージ・時刻は設定変更可）
  // ===========================================================

  Future<void> scheduleDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(AppConstants.keyReminderEnabled) ?? true;

    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    final hour =
        prefs.getInt(AppConstants.keyReminderHour) ??
        AppConstants.defaultReminderHour;
    final minute =
        prefs.getInt(AppConstants.keyReminderMinute) ??
        AppConstants.defaultReminderMinute;

    await cancelDailyReminder();

    final mode = await _languageMode();
    final body = mode == LanguageMode.ja
        ? '今日の技術英語を学習しましょう！🚀'
        : "Today's session is ready. Let's study! 🚀";

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _dailyReminderId,
        'ShipIt English',
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Failed to schedule: $e');
      }
    }
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  // ===========================================================
  // 2) ストリーク危機通知（その日未学習のときだけ 23:00 に鳴る）
  //
  // 時刻は23:00固定（設定不可）だが、オン/オフは
  // keyStreakReminderEnabled で定時リマインダーとは独立に切り替えられる。
  // 仕組み: 今後7日分を曜日別ID（2001〜2007）でランダムメッセージ
  // 付きでスケジュールする。学習が完了した日は当日分だけキャンセル
  // する（cancelStreakReminderForToday）。翌日以降の分は残るので、
  // 学習しなかった日は自動的に通知が鳴る。
  // アプリ起動のたびに7日分を再スケジュールして先を補充する。
  // ===========================================================

  Future<void> scheduleStreakReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(AppConstants.keyStreakReminderEnabled) ?? true;

    // オフなら積んである7日分を必ず消す。スケジュールを止めるだけでは、
    // オフにする前に OS へ登録済みの通知が最長7日間鳴り続けてしまう。
    if (!enabled) {
      await cancelAllStreakReminders();
      return;
    }

    const hour = AppConstants.streakReminderHour;
    const minute = AppConstants.streakReminderMinute;

    final mode = await _languageMode();
    final messages = mode == LanguageMode.ja
        ? _streakMessagesJa
        : _streakMessagesEn;
    final random = Random();

    const androidDetails = AndroidNotificationDetails(
      AppConstants.streakChannelId,
      AppConstants.streakChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      final now = tz.TZDateTime.now(tz.local);
      for (var offset = 0; offset < 7; offset++) {
        var date = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        ).add(Duration(days: offset));

        // 今日の分がすでに過ぎていればスキップ
        if (date.isBefore(now)) continue;

        final id = _streakReminderBaseId + date.weekday; // 2001〜2007
        await _plugin.zonedSchedule(
          id,
          'ShipIt English',
          messages[random.nextInt(messages.length)],
          date,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Failed to schedule streak: $e');
      }
    }
  }

  /// 今日の学習が完了したら呼ぶ。今日の分の危機通知だけを消す
  Future<void> cancelStreakReminderForToday() async {
    final todayId = _streakReminderBaseId + DateTime.now().weekday;
    await _plugin.cancel(todayId);
  }

  Future<void> cancelAllStreakReminders() async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_streakReminderBaseId + weekday);
    }
  }

  /// 全ての通知予約を組み直す（起動時／OSの通知許可が戻ったとき）。
  ///
  /// 許可が無い間の `zonedSchedule` は例外を投げず黙って無視されるだけなので、
  /// 許可が戻った時点で必ずここを通さないと1通も鳴らないままになる。
  /// [studiedToday] が true なら当日分のストリーク危機通知は落とす。
  Future<void> rescheduleAll({required bool studiedToday}) async {
    await scheduleDailyReminder();
    await scheduleStreakReminders();
    if (studiedToday) {
      await cancelStreakReminderForToday();
    }
  }

  // ===========================================================
  // 3) OSの通知許可
  //
  // アプリ内のトグルがオンでも、OS側で通知が切られていれば1通も届かない。
  // 設定画面はこの状態を検出して「オンなのに鳴らない」表示にならないようにする。
  // ===========================================================

  /// OSレベルで通知が有効かどうか。
  ///
  /// iOS の許可はアプリの外（設定アプリ）で変えられるので、起動時に一度だけ
  /// ではなくフォアグラウンド復帰のたびに問い合わせ直すこと。
  /// 判定できないプラットフォームでは true（＝制限なし）を返す。
  Future<bool> isSystemNotificationEnabled() async {
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final options = await ios.checkPermissions();
        // options が null なのは情報を取得できなかったときだけ。
        // ここで false を返すと誤ってバナーを出してしまうので true 扱いにする。
        return options?.isEnabled ?? true;
      }

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] checkPermissions failed: $e');
      }
    }
    return true;
  }

  /// これまでに一度でもOSの許可ダイアログを出したか。
  ///
  /// iOS は一度拒否されると `requestPermissions()` がダイアログを出さずに
  /// 即 false を返す。未決定（＝ダイアログを出せばよい）と拒否済み（＝設定
  /// アプリへ誘導するしかない）を区別するために記録しておく。
  Future<bool> hasRequestedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyNotifPermissionRequested) ?? false;
  }

  Future<bool> requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotifPermissionRequested, true);

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }
}
