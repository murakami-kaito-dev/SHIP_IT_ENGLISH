class AppConstants {
  // App info（pubspec.yaml の version と手動で同期すること）
  static const String appVersion = '1.0.0';

  // SRS
  static const double initialEaseFactor = 2.5;
  static const double minimumEaseFactor = 1.3;
  static const int masteredThresholdDays = 21;
  static const int maxRetriesPerSession = 2;
  // 「忘れた」直後の再学習ステップ（エビングハウスの忘却曲線に基づく短い間隔）。
  // 失敗直後は急速に忘れるため、数十分後に再提示する。
  static const int relearnStepMinutes = 10;

  // Daily session
  static const int defaultNewCardsPerDay = 5;
  static const int minNewCardsPerDay = 1;
  static const int maxNewCardsPerDay = 20;
  static const int estimatedSecondsPerCard = 30;

  // Notification
  static const int defaultReminderHour = 8;
  static const int defaultReminderMinute = 0;
  static const String notificationChannelId = 'daily_reminder';
  static const String notificationChannelName = 'Daily Reminder';

  // ストリーク危機通知（その日未学習のときだけ23:00に鳴る。時刻は固定・設定不可）
  static const int streakReminderHour = 23;
  static const int streakReminderMinute = 0;
  static const String streakChannelId = 'streak_reminder';
  static const String streakChannelName = 'Streak Reminder';

  // Swipe
  static const double swipeConfirmThreshold = 0.30;
  static const double swipeMaxRotationDegrees = 15.0;
  static const Duration swipeSnapBackDuration = Duration(milliseconds: 200);
  static const Duration flipDuration = Duration(milliseconds: 300);
  static const Duration slideOutDuration = Duration(milliseconds: 200);
  static const Duration slideInDuration = Duration(milliseconds: 250);

  // In-app review
  static const int reviewRequestMinStreak = 3;

  // shared_preferences keys
  static const String keyStreakCount = 'streak_count';
  static const String keyLastStudyDate = 'last_study_date';
  static const String keySeedVersion = 'seed_version';
  static const String keyNewCardsPerDay = 'new_cards_per_day';
  static const String keyReminderEnabled = 'reminder_enabled';
  static const String keyReminderHour = 'reminder_hour';
  static const String keyReminderMinute = 'reminder_minute';
  static const String keyLanguageMode = 'language_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyReviewRequested = 'review_requested';
  static const String keyProEntitlement = 'pro_entitlement';
  static const String keyTotalXp = 'gamification_total_xp';

  /// 権利の検証に最後に成功した時刻（ISO8601）。
  /// 猶予期間の判定に使う（オフラインで即失効させないため）
  static const String keyEntitlementVerifiedAt = 'entitlement_verified_at';
}
