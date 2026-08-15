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
  // 「1日の新規カード数」設定でユーザーが指定できる上限
  static const int maxNewCardsSetting = 100;
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
  // ストリーク危機通知（23:00固定）のオン/オフ。既定はオン。
  // 定時リマインダーとは独立させる。「毎朝の通知は不要だが、途切れそうな日だけは
  // 知らせてほしい」という組み合わせを選べるようにするため。
  static const String keyStreakReminderEnabled = 'streak_reminder_enabled';
  // OSの通知許可を一度でも要求したか。iOSは一度拒否されると requestPermissions()
  // がダイアログを出さず即 false を返すため、「未決定（ダイアログを出す）」と
  // 「拒否済み（設定アプリへ誘導する）」をこのフラグで区別する。
  static const String keyNotifPermissionRequested = 'notif_permission_requested';
  static const String keyLanguageMode = 'language_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyReviewRequested = 'review_requested';
  static const String keyProEntitlement = 'pro_entitlement';
  static const String keyTotalXp = 'gamification_total_xp';
  // これまでに交換（消費）したXPの累計。使えるXP = 通算XP − 使用済みXP。
  static const String keySpentXp = 'gamification_spent_xp';
  // 所持しているストリーク保護の数。
  static const String keyStreakFreezes = 'streak_freezes';
  // 起動時に自動消費したストリーク保護の枚数（ホームで一度だけ通知して0に戻す）。
  static const String keyStreakFreezeUsedPending = 'streak_freeze_used_pending';
  static const String keyStudyScope = 'study_scope';
  // デイリークエストの進捗（日付付きJSON。日付が変わると自動リセット）。
  static const String keyQuestProgress = 'daily_quest_progress';
  // クリア済みユニット（'categoryId:unitIndex' の文字列リスト）。
  static const String keyClearedUnits = 'cleared_units';
  // パーフェクトセッション（全カード1発で「覚えてた」）の通算回数。
  static const String keyPerfectSessions = 'perfect_sessions_count';
  // 獲得済みバッジ（JSON: id → 獲得日ISO8601）。
  static const String keyEarnedBadges = 'earned_badges';
  // 耳学（リスニング）の再生設定を記憶する。
  static const String keyListenSpeed = 'listen_speed';
  static const String keyListenRepeat = 'listen_repeat';

  /// 権利の検証に最後に成功した時刻（ISO8601）。
  /// 猶予期間の判定に使う（オフラインで即失効させないため）
  static const String keyEntitlementVerifiedAt = 'entitlement_verified_at';
}
