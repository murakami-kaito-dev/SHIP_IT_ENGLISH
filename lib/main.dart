import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/app.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/database/database_helper.dart';
import 'package:ship_it_english/core/database/seed_data.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/services/notification_service.dart';
import 'package:ship_it_english/core/services/streak_manager.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. SQLite 初期化
  final dbHelper = DatabaseHelper();
  await dbHelper.initialize();

  // 2. シードデータ投入（初回 or バージョン更新時のみ）
  await SeedData(dbHelper).seed();

  // 3. ストリークチェック（2日以上空いていればリセット）
  await StreakManager().checkAndUpdateStreak();

  // 4. 通知スケジュール設定
  //    - 定時リマインダー（毎日同時刻）
  //    - ストリーク危機通知（7日分。学習済みの日は当日分をキャンセル）
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleDailyReminder();
  await notificationService.scheduleStreakReminders();
  final studiedToday = await LocalCardRepository(dbHelper)
      .hasStudiedToday(DateTime.now().toDateString());
  if (studiedToday) {
    await notificationService.cancelStreakReminderForToday();
  }

  // 5. 言語モード・オンボーディング状態の読み込み
  final prefs = await SharedPreferences.getInstance();
  final languageMode =
      LanguageMode.fromString(prefs.getString(AppConstants.keyLanguageMode));
  final onboardingDone =
      prefs.getBool(AppConstants.keyOnboardingDone) ?? false;

  // 6. UI起動
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(dbHelper),
        languageModeProvider.overrideWith(
          (ref) => LanguageModeNotifier(languageMode),
        ),
      ],
      child: ShipItEnglishApp(showOnboarding: !onboardingDone),
    ),
  );
}
