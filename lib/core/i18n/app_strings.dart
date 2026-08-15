import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/domain/quests.dart';

/// UI表示言語モード。
/// - [ja] 日本語話者向け: UIは日本語、英語フレーズを学習する（従来の動作）
/// - [en] 英語話者向け: UIは英語、日本語フレーズを学習する
enum LanguageMode {
  ja('ja'),
  en('en');

  final String value;
  const LanguageMode(this.value);

  static LanguageMode fromString(String? value) {
    return LanguageMode.values.firstWhere(
      (m) => m.value == value,
      orElse: () => LanguageMode.ja,
    );
  }
}

/// アプリUIの全文言。カードのコンテンツ（phrase / translation 等）は含まない。
/// 画面からは stringsProvider 経由で取得すること。
class AppStrings {
  final LanguageMode mode;

  // Tabs
  final String tabHome;
  final String tabCategories;
  final String tabSettings;

  // Home
  final String loadError;
  final String todaysSession;
  final String newCards;
  final String reviewCards;
  final String studyScopeNewOnly;
  final String studyScopeReviewOnly;
  final String studyScopeBoth;
  final String sessionTotalLabel;
  final String startLearning;
  final String sessionCompleteToday;
  final String reviewAgain;
  final String noCardsToReview;
  final String allMastered;
  final String reviewWeakCards;
  final String progressTitle;

  // Study
  final String tapToFlip;
  final String swipeHint;
  final String ratingForgot;
  final String ratingUncertain;
  final String ratingRemembered;
  final String exitDialogTitle;
  final String exitDialogBody;
  final String exitDialogContinue;
  final String exitDialogQuit;
  final String emptySession;
  final String exampleLabel;
  final String usageLabel;

  // Session complete
  final String sessionCompleteTitle;
  final String statStudied;
  final String statCorrect;
  final String statTime;
  final String statStreak;
  final String newWordsLearned;
  final String reviewsCompleted;
  final String backToHome;

  // Categories
  final String categoriesTitle;
  final String genericError;
  final String cardsLoadError;
  final String studyThisCategory;
  final String noCardsInCategory;
  /// 未学習（まだ一度も評価していないカード）。
  /// 学習済みカードのステータスは ratingForgot / ratingUncertain /
  /// ratingRemembered をそのまま使い、評価ボタンと語彙を統一している。
  final String statusNew;

  // フィルタ
  final String filterTitle;
  final String filterCategory;
  final String filterStatus;
  final String filterClear;
  final String filterResultEmpty;

  // Settings
  final String settingsTitle;
  final String sectionStudy;
  final String sectionNotification;
  final String sectionData;
  final String sectionLanguage;
  final String newCardsPerDay;
  final String dailyReminder;
  final String reminderTime;
  final String streakReminder;
  final String streakReminderDesc;
  // 時刻ピッカー（ホイール式）
  final String hourLabel;
  final String minuteLabel;
  final String pickerConfirm;
  final String notifPermissionRequired;
  // OSの通知許可がオフのときに通知セクションの先頭へ出すバナー
  final String notifSystemOffTitle;
  final String notifSystemOffBody;
  final String notifOpenSettings;
  final String notifOpenSettingsFailed;
  final String backupExport;
  final String backupExportDesc;
  final String backupImport;
  final String backupImportDesc;
  final String backupImportConfirmTitle;
  final String backupImportConfirmBody;
  final String backupImportFailed;
  final String resetData;
  final String resetDataSubtitle;
  final String resetConfirmTitle;
  final String resetConfirmBody;
  final String cancel;
  final String resetAction;
  final String resetDone;
  final String languageLabel;
  final String languageModeDescription;

  // カード詳細からの評価
  final String updateStatusLabel;
  final String ratingSaved;

  /// 誤タップを取り消して未学習に戻すボタン
  final String resetToNotStudied;

  // カテゴリ学習（設定して学習）
  final String rangeStudyTitle;
  final String rangeStudySubtitle;
  final String rangeSelectCategory;
  final String rangeSelectStatus;
  final String rangeSelectRange;
  final String rangeSelectOrder;
  final String rangeOrderAsc;
  final String rangeOrderRandom;
  final String rangeStart;
  final String rangeCardsCount;
  final String rangeMatchCount;
  final String rangeNoMatch;
  final String newCardsOnHome;
  final String rangeMin;
  final String rangeMax;
  final String newCardsMaxLabel;
  // 「1日の新規学習カード数」設定UI（見出し＋プリセット名）
  final String newStudyCardsHeading;
  final String presetSteadyName;
  final String presetStandardName;
  final String presetSpeedName;

  // 学習履歴カレンダー
  final String historyTitle;
  final String historyStudied;
  final String historyNotStudied;
  final String historyThisMonth;
  final String historyTotalDays;
  final String historyThisMonthCards;
  final String historyTotalCards;
  final String historyTapDayHint;
  final String historyNoStudyThatDay;
  final String sessionHelpTitle;
  final String sessionHelpTooltip;
  // ゲーミフィケーション
  final String levelUpTitle;
  final String levelWord;
  final String continueButton;
  final String streakGoalReached;
  final String xpEarned;
  final String keepGoing;

  // 週間サマリー
  final String weeklyTitle;

  // カード検索
  final String searchTitle;
  final String searchHint;
  final String searchEmpty;

  // Pro / サブスクリプション（ゲート表示用。パウォール本文は paywall_screen 内）
  final String proSection;
  final String proStatusFree;
  final String proStatusActive;
  final String upgradeToPro;
  final String manageSubscription;
  final String manageSubscriptionDesc;
  final String restorePurchases;
  final String restorePurchasesDesc;
  final String restoreSuccess;
  final String restoreNotFound;
  final String proSliderHint;
  final String proLockedCategory;

  const AppStrings._({
    required this.mode,
    required this.tabHome,
    required this.tabCategories,
    required this.tabSettings,
    required this.loadError,
    required this.todaysSession,
    required this.newCards,
    required this.reviewCards,
    required this.studyScopeNewOnly,
    required this.studyScopeReviewOnly,
    required this.studyScopeBoth,
    required this.sessionTotalLabel,
    required this.startLearning,
    required this.sessionCompleteToday,
    required this.reviewAgain,
    required this.noCardsToReview,
    required this.allMastered,
    required this.reviewWeakCards,
    required this.progressTitle,
    required this.tapToFlip,
    required this.swipeHint,
    required this.ratingForgot,
    required this.ratingUncertain,
    required this.ratingRemembered,
    required this.exitDialogTitle,
    required this.exitDialogBody,
    required this.exitDialogContinue,
    required this.exitDialogQuit,
    required this.emptySession,
    required this.exampleLabel,
    required this.usageLabel,
    required this.sessionCompleteTitle,
    required this.statStudied,
    required this.statCorrect,
    required this.statTime,
    required this.statStreak,
    required this.newWordsLearned,
    required this.reviewsCompleted,
    required this.backToHome,
    required this.categoriesTitle,
    required this.genericError,
    required this.cardsLoadError,
    required this.studyThisCategory,
    required this.noCardsInCategory,
    required this.statusNew,
    required this.filterTitle,
    required this.filterCategory,
    required this.filterStatus,
    required this.filterClear,
    required this.filterResultEmpty,
    required this.settingsTitle,
    required this.sectionStudy,
    required this.sectionNotification,
    required this.sectionData,
    required this.sectionLanguage,
    required this.newCardsPerDay,
    required this.dailyReminder,
    required this.reminderTime,
    required this.streakReminder,
    required this.streakReminderDesc,
    required this.hourLabel,
    required this.minuteLabel,
    required this.pickerConfirm,
    required this.notifPermissionRequired,
    required this.notifSystemOffTitle,
    required this.notifSystemOffBody,
    required this.notifOpenSettings,
    required this.notifOpenSettingsFailed,
    required this.backupExport,
    required this.backupExportDesc,
    required this.backupImport,
    required this.backupImportDesc,
    required this.backupImportConfirmTitle,
    required this.backupImportConfirmBody,
    required this.backupImportFailed,
    required this.resetData,
    required this.resetDataSubtitle,
    required this.resetConfirmTitle,
    required this.resetConfirmBody,
    required this.cancel,
    required this.resetAction,
    required this.resetDone,
    required this.languageLabel,
    required this.languageModeDescription,
    required this.updateStatusLabel,
    required this.ratingSaved,
    required this.resetToNotStudied,
    required this.rangeStudyTitle,
    required this.rangeStudySubtitle,
    required this.rangeSelectCategory,
    required this.rangeSelectStatus,
    required this.rangeSelectRange,
    required this.rangeSelectOrder,
    required this.rangeOrderAsc,
    required this.rangeOrderRandom,
    required this.rangeStart,
    required this.rangeCardsCount,
    required this.rangeMatchCount,
    required this.rangeNoMatch,
    required this.newCardsOnHome,
    required this.rangeMin,
    required this.rangeMax,
    required this.newCardsMaxLabel,
    required this.newStudyCardsHeading,
    required this.presetSteadyName,
    required this.presetStandardName,
    required this.presetSpeedName,
    required this.historyTitle,
    required this.historyStudied,
    required this.historyNotStudied,
    required this.historyThisMonth,
    required this.historyTotalDays,
    required this.historyThisMonthCards,
    required this.historyTotalCards,
    required this.historyTapDayHint,
    required this.historyNoStudyThatDay,
    required this.sessionHelpTitle,
    required this.sessionHelpTooltip,
    required this.levelUpTitle,
    required this.levelWord,
    required this.continueButton,
    required this.streakGoalReached,
    required this.xpEarned,
    required this.keepGoing,
    required this.weeklyTitle,
    required this.searchTitle,
    required this.searchHint,
    required this.searchEmpty,
    required this.proSection,
    required this.proStatusFree,
    required this.proStatusActive,
    required this.upgradeToPro,
    required this.manageSubscription,
    required this.manageSubscriptionDesc,
    required this.restorePurchases,
    required this.restorePurchasesDesc,
    required this.restoreSuccess,
    required this.restoreNotFound,
    required this.proSliderHint,
    required this.proLockedCategory,
  });

  // === パラメータ付き文言 ===

  String cardsCount(int n) => mode == LanguageMode.ja
      ? '$n枚'
      : '$n ${n == 1 ? 'card' : 'cards'}';

  String estimatedTime(int seconds) {
    if (mode == LanguageMode.ja) {
      if (seconds < 60) return '約$seconds秒';
      return '約${(seconds / 60).ceil()}分';
    }
    if (seconds < 60) return '~$seconds sec';
    return '~${(seconds / 60).ceil()} min';
  }

  /// 次に復習するまでの待ち時間を短く表示する（例: 「10分」「1日」「3日」「2週間」）。
  /// 評価ボタンに「次はいつ復習するか」を示すために使う。
  String nextReviewIn(Duration d) {
    final minutes = d.inMinutes < 1 ? 1 : d.inMinutes;
    if (mode == LanguageMode.ja) {
      if (d.inMinutes < 60) return '$minutes分';
      if (d.inHours < 24) return '${d.inHours}時間';
      final days = d.inDays;
      if (days < 7) return '$days日';
      if (days < 30) return '${(days / 7).round()}週間';
      return '${(days / 30).round()}か月';
    }
    if (d.inMinutes < 60) return '$minutes min';
    if (d.inHours < 24) return '${d.inHours} h';
    final days = d.inDays;
    if (days < 7) return '$days d';
    if (days < 30) return '${(days / 7).round()} wk';
    return '${(days / 30).round()} mo';
  }

  String streak(int days) =>
      mode == LanguageMode.ja ? '$days日連続' : '$days-day streak';

  String streakDays(int days) => mode == LanguageMode.ja
      ? '$days日 🔥'
      : '$days ${days == 1 ? 'day' : 'days'} 🔥';

  /// 進捗表示は「学習した枚数」を主役にする。
  /// mastered（21日間隔到達）は数週間かかるため、これだけだと
  /// 学習しても 0 のままに見えてしまう。
  String studiedOf(int studied, int total) => mode == LanguageMode.ja
      ? '学習済み: $studied / $total'
      : 'Studied: $studied / $total';

  String masteredOf(int mastered, int total) => mode == LanguageMode.ja
      ? '習得済み: $mastered / $total'
      : 'Mastered: $mastered / $total';

  String masteredCountLabel(int mastered) => mode == LanguageMode.ja
      ? 'うち習得済み $mastered'
      : '$mastered mastered';

  /// 「今日のセッション」タイトル横に出す小さな完了マークの文言。
  String get sessionDoneChip => mode == LanguageMode.ja ? '完了' : 'Done';

  // --- レベル / 経験値（ゲーミフィケーション） ---
  String get levelTitle => mode == LanguageMode.ja ? 'レベル' : 'Level';

  /// 通算で獲得したXPの総量。
  String totalXpValue(int xp) =>
      mode == LanguageMode.ja ? '通算 $xp XP' : 'Total $xp XP';

  /// 次のレベルまでに必要な残りXP。
  String xpToNext(int remaining, int nextLevel) => mode == LanguageMode.ja
      ? 'あと $remaining XP で LV $nextLevel'
      : '$remaining XP to LV $nextLevel';

  /// レベルアップ間近（85%以上）のときの煽り文言。短く強くする。
  String xpAlmost(int remaining) => mode == LanguageMode.ja
      ? 'あと $remaining XP!'
      : '$remaining XP to go!';

  /// セッションの残り枚数。数字だけの `9 / 15` を補い、ゴールを意識させる。
  String remainingCards(int n) =>
      mode == LanguageMode.ja ? 'のこり $n枚' : '$n left';

  /// コンボ数のチップ表示。
  String comboChip(int combo) =>
      mode == LanguageMode.ja ? 'コンボ $combo' : 'Combo $combo';

  /// レベルの意味を説明するキャプション（学習量の証）。
  String get levelCaption => mode == LanguageMode.ja
      ? 'カードに正解するとXPが貯まり、レベルが上がります'
      : 'Answer cards correctly to earn XP and level up';

  /// レベル帯に対応する称号（キャリアラダー）。
  String rankName(EngineerRank rank) {
    if (mode == LanguageMode.ja) {
      return switch (rank) {
        EngineerRank.intern => 'インターン',
        EngineerRank.junior => 'ジュニアエンジニア',
        EngineerRank.engineer => 'エンジニア',
        EngineerRank.senior => 'シニアエンジニア',
        EngineerRank.staff => 'スタッフエンジニア',
        EngineerRank.principal => 'プリンシパルエンジニア',
        EngineerRank.distinguished => 'ディスティングイッシュト',
      };
    }
    return switch (rank) {
      EngineerRank.intern => 'Intern',
      EngineerRank.junior => 'Junior Engineer',
      EngineerRank.engineer => 'Engineer',
      EngineerRank.senior => 'Senior Engineer',
      EngineerRank.staff => 'Staff Engineer',
      EngineerRank.principal => 'Principal Engineer',
      EngineerRank.distinguished => 'Distinguished Engineer',
    };
  }

  // --- ユニット制（約20枚ごとの関門＋卒業テスト） ---
  String get unitsSectionTitle => mode == LanguageMode.ja ? 'ユニット' : 'Units';

  String unitLabel(int index) =>
      mode == LanguageMode.ja ? 'ユニット $index' : 'Unit $index';

  String unitRangeLabel(int from, int to) => '#$from–#$to';

  String get unitTestButton => mode == LanguageMode.ja ? '挑戦' : 'Test';

  String get unitClearedChip => mode == LanguageMode.ja ? 'クリア' : 'Clear';

  String unitStudiedOf(int studied, int total) => mode == LanguageMode.ja
      ? '学習 $studied/$total'
      : 'Studied $studied/$total';

  String unitClearTitle(int index) => mode == LanguageMode.ja
      ? 'ユニット $index クリア！'
      : 'Unit $index clear!';

  String unitClearBonus(int xp) =>
      mode == LanguageMode.ja ? 'ボーナス +$xp XP' : 'Bonus +$xp XP';

  String get unitFailTitle => mode == LanguageMode.ja ? 'あと少し！' : 'Almost!';

  String unitFailBody(int mistakes, int allowed) => mode == LanguageMode.ja
      ? 'ミス $mistakes 回でした（クリアは $allowed 回まで）。\nもう一度挑戦してみよう'
      : '$mistakes mistakes (up to $allowed allowed to clear).\nGive it another try!';

  String get unitRetry =>
      mode == LanguageMode.ja ? 'もう一度挑戦' : 'Try again';

  String get unitBackToCategory =>
      mode == LanguageMode.ja ? 'カテゴリに戻る' : 'Back to category';

  // --- クイズ形式（4択・音声・穴埋め） ---
  String get quizChoicePrompt =>
      mode == LanguageMode.ja ? '正しい意味を選ぼう' : 'Choose the correct meaning';

  String get quizAudioPrompt => mode == LanguageMode.ja
      ? '音声を聴いて、意味を選ぼう'
      : 'Listen and choose the meaning';

  String get quizClozePrompt => mode == LanguageMode.ja
      ? '空欄に入るフレーズを選ぼう'
      : 'Which phrase fills the blank?';

  String get quizCorrect => mode == LanguageMode.ja ? '正解！' : 'Correct!';

  String get quizWrong =>
      mode == LanguageMode.ja ? '残念、正解は…' : 'Not quite — the answer is…';

  String get quizTapToReplay =>
      mode == LanguageMode.ja ? 'タップでもう一度聴く' : 'Tap to replay';

  // --- デイリークエスト（日替わりのお題＋宝箱） ---
  String get dailyQuestsTitle =>
      mode == LanguageMode.ja ? '今日のクエスト' : "Today's Quests";

  /// クエストのお題文言（種類＋目標値から生成）。
  String questTitle(Quest q) {
    if (mode == LanguageMode.ja) {
      return switch (q.type) {
        QuestType.studyCards => 'カードを${q.target}枚学習する',
        QuestType.comboReach => '${q.target}コンボを達成する',
        QuestType.remembered => '「覚えてた」を${q.target}回出す',
        QuestType.listenLines => '耳学で${q.target}クリップ聴く',
      };
    }
    return switch (q.type) {
      QuestType.studyCards => 'Study ${q.target} cards',
      QuestType.comboReach => 'Reach a ${q.target} combo',
      QuestType.remembered => 'Get ${q.target} "knew it" answers',
      QuestType.listenLines => 'Listen to ${q.target} clips',
    };
  }

  /// 宝箱の状態文言。
  String get questChestLocked => mode == LanguageMode.ja
      ? '3つすべて達成で宝箱が開く'
      : 'Complete all 3 to open the chest';

  String get questChestOpen =>
      mode == LanguageMode.ja ? '宝箱を開ける' : 'Open the chest';

  String questChestGained(int xp) =>
      mode == LanguageMode.ja ? '+$xp XP 獲得！' : '+$xp XP earned!';

  String get questChestFreezeBonus => mode == LanguageMode.ja
      ? 'おまけ：ストリーク保護 +1 🛡️'
      : 'Bonus: +1 Streak Freeze 🛡️';

  String questChestClaimed(int xp) => mode == LanguageMode.ja
      ? '今日の宝箱は受け取り済み（+$xp XP）'
      : "Today's chest claimed (+$xp XP)";

  String get questChestTitle =>
      mode == LanguageMode.ja ? '宝箱ゲット！' : 'Chest unlocked!';

  // --- ストリーク保護（XPで交換する特典） ---
  String get streakShieldTitle =>
      mode == LanguageMode.ja ? 'ストリーク保護' : 'Streak Freeze';

  String get streakShieldDesc => mode == LanguageMode.ja
      ? '1日サボっても連続記録が途切れません。休んだ日に自動で消費されます。'
      : 'Keeps your streak alive if you miss a day. Used automatically on a missed day.';

  String streakShieldOwned(int n, int max) => mode == LanguageMode.ja
      ? '所持 $n / $max'
      : 'Owned $n / $max';

  /// 交換に使える残高XP。
  String availableXpLabel(int xp) =>
      mode == LanguageMode.ja ? '使えるXP $xp' : 'Available $xp XP';

  /// 交換ボタンの文言（コストXP）。
  String exchangeForXp(int cost) => mode == LanguageMode.ja
      ? '$cost XP で交換'
      : 'Exchange for $cost XP';

  String get streakShieldMax =>
      mode == LanguageMode.ja ? '所持数が上限です' : 'You have the maximum';

  String get streakShieldNotEnough =>
      mode == LanguageMode.ja ? 'XPが足りません' : 'Not enough XP';

  String get streakShieldPurchased => mode == LanguageMode.ja
      ? 'ストリーク保護を1つ入手しました'
      : 'Got 1 Streak Freeze';

  /// 起動時に保護が自動消費されたときの通知。
  String streakFreezeUsedNotice(int n) => mode == LanguageMode.ja
      ? '🛡 ストリーク保護でストリークを守りました（$n個消費）'
      : '🛡 A Streak Freeze saved your streak ($n used)';

  // --- 耳学（リスニング再生） ---
  String get studyAction => mode == LanguageMode.ja ? '学習する' : 'Study';
  String get listenAction => mode == LanguageMode.ja ? '聴く' : 'Listen';

  /// 範囲指定シートの「聴く」CTA。
  String get rangeStartListen =>
      mode == LanguageMode.ja ? 'この条件で聴く' : 'Listen to these';

  String get listenTitle => mode == LanguageMode.ja ? '耳学' : 'Listening';
  String get listenUpNext => mode == LanguageMode.ja ? '次に再生' : 'Up next';
  String get listenFinished => mode == LanguageMode.ja ? '再生完了' : 'Finished';
  String get listenReplay =>
      mode == LanguageMode.ja ? 'もう一度聴く' : 'Play again';
  String get listenNowPlaying =>
      mode == LanguageMode.ja ? '再生中' : 'Now playing';
  String get listenRepeat => mode == LanguageMode.ja ? '繰り返し' : 'Repeat';
  String get listenSpeed => mode == LanguageMode.ja ? '速度' : 'Speed';

  /// 「3 / 40 枚」形式のカード進捗。
  String listenProgress(int current, int total) => mode == LanguageMode.ja
      ? '$current / $total 枚'
      : '$current / $total';

  String correctWithAccuracy(int correct, int accuracy) =>
      '$correct ($accuracy%)';

  String todayDate(DateTime now) {
    if (mode == LanguageMode.ja) {
      const days = ['月', '火', '水', '木', '金', '土', '日'];
      return '${now.month}/${now.day} (${days[now.weekday - 1]})';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  /// カレンダーの月見出し（例: 2026年7月 / July 2026）
  String monthLabel(DateTime month) {
    if (mode == LanguageMode.ja) {
      return '${month.year}年${month.month}月';
    }
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  /// カレンダーで選んだ日付の短い表記（例:「7月15日」/「Jul 15」）。
  String monthDayLabel(DateTime d) {
    if (mode == LanguageMode.ja) {
      return '${d.month}月${d.day}日';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  /// 「今日のセッション」の新規枠を「残り / 上限」で表す（例:「残り37 / 40枚」）。
  String newCardsRemainingOfLimit(int remaining, int limit) =>
      mode == LanguageMode.ja
          ? '残り$remaining / $limit枚'
          : '$remaining / $limit left';

  /// 今日すでに学習した新規カードの補足（残り枠が減る理由の明示）。
  String newCardsStudiedNote(int studied) => mode == LanguageMode.ja
      ? '今日はすでに新規を$studied枚学習しました'
      : 'You\'ve already studied $studied new cards today.';

  /// カレンダーの日別詳細（例:「24枚 学習」/「24 cards」）。
  String historyDayCards(int n) =>
      mode == LanguageMode.ja ? '$n枚 学習' : '$n cards';

  /// 「今日のセッション」ヘルプの各項目（見出し・説明）。
  /// UI文言をハードコードしないため、説明文もここに集約する。
  List<MapEntry<String, String>> sessionHelpEntries() {
    if (mode == LanguageMode.ja) {
      return const [
        MapEntry('学習範囲（新規のみ / 復習のみ / 両方）',
            '今日のセッションで学習する範囲を選べます。「新規のみ」＝新しいカードだけ、「復習のみ」＝期限が来た復習だけ、「両方」＝新規＋復習。合計枚数はこの選択で変わります（復習の予定日サイクルは変わりません）。'),
        MapEntry('新規（残り / 上限）',
            '「1日の新規カード数」の上限のうち、今日まだ学習していない残り枚数です。新規を学習するとその分だけ減り、日付が変わると上限まで戻ります。'),
        MapEntry('復習',
            '前回の学習で決まった「次回復習日」が来たカードです。よく覚えているカードほど次の復習までの間隔が長くなります。'),
        MapEntry('合計・所要時間',
            '今日のセッションで出題される「新規＋復習」の合計枚数と、そのおおよその目安時間です。'),
        MapEntry('1日の新規カード数',
            '1日に追加する新規カードの上限です。ここを増減すると上の「新規（残り）」も変わります。'),
        MapEntry('もう一度復習する',
            '今日学習したカードを、その日のうちにもう一度復習できます（復習間隔には影響しません）。'),
        MapEntry('評価ボタンの下の時間',
            '「忘れた／曖昧／覚えてた」の下の時間は、その評価を選んだ場合に次へ復習するまでの間隔です。忘れたは短く、覚えてたは長くなります（忘却曲線に基づく間隔反復）。'),
      ];
    }
    return const [
      MapEntry('Study scope (New only / Review only / Both)',
          'Choose what today\'s session includes: New only, Review only (cards that are due), or Both. The total count changes with this choice (the review scheduling itself does not change).'),
      MapEntry('New (left / limit)',
          'How many new cards remain today out of your daily limit. Studying new cards lowers it; it resets to the limit each day.'),
      MapEntry('Review',
          'Cards whose scheduled review date has arrived. The better you know a card, the longer until its next review.'),
      MapEntry('Total & time',
          'The combined new + review cards for today\'s session, and a rough time estimate.'),
      MapEntry('New cards per day',
          'The daily cap on how many new cards are added. Changing it also changes the "New (left)" count above.'),
      MapEntry('Review again',
          'Lets you review the cards you studied today once more, same day (it does not change their intervals).'),
      MapEntry('Time under rating buttons',
          'The time under Forgot / Unsure / Got it is when that card comes back if you pick that rating. Forgot is short, Got it is long (spaced repetition based on the forgetting curve).'),
    ];
  }

  // === 日本語（技術英語を学ぶ日本人向け） ===
  static const ja = AppStrings._(
    mode: LanguageMode.ja,
    tabHome: 'ホーム',
    tabCategories: 'カテゴリ',
    tabSettings: '設定',
    loadError: 'コンテンツの読み込みに失敗しました',
    todaysSession: '今日のセッション',
    newCards: '新規',
    reviewCards: '復習',
    studyScopeNewOnly: '新規のみ',
    studyScopeReviewOnly: '復習のみ',
    studyScopeBoth: '両方',
    sessionTotalLabel: '合計',
    startLearning: '学習を始める',
    sessionCompleteToday: '今日のセッション完了！',
    reviewAgain: 'もう一度復習する',
    noCardsToReview: '今復習するカードはありません',
    allMastered: '🎊 全カード習得済み！',
    reviewWeakCards: '苦手なカードを復習',
    progressTitle: '学習進捗',
    tapToFlip: 'カードをタップしてめくる',
    swipeHint: '← 忘れた ・ 覚えてた →  スワイプでも評価できます',
    ratingForgot: '忘れた',
    ratingUncertain: '曖昧',
    ratingRemembered: '覚えてた',
    exitDialogTitle: 'セッションを終了しますか？',
    exitDialogBody: '評価済みのカードは保存されます。',
    exitDialogContinue: '続ける',
    exitDialogQuit: '終了',
    emptySession: '今日学習するカードはありません',
    exampleLabel: '💬 例文',
    usageLabel: '📍 使用場面',
    sessionCompleteTitle: 'セッション完了！',
    statStudied: '学習したカード',
    statCorrect: '正解',
    statTime: '学習時間',
    statStreak: '連続記録',
    newWordsLearned: '新しく学んだ表現',
    reviewsCompleted: '復習した表現',
    backToHome: 'ホームへ戻る',
    categoriesTitle: 'カテゴリ',
    genericError: 'エラーが発生しました',
    cardsLoadError: 'カードの読み込みに失敗しました',
    studyThisCategory: 'このカテゴリを学習',
    noCardsInCategory: 'このカテゴリに今日学習するカードはありません',
    statusNew: '未学習',
    filterTitle: 'フィルタ',
    filterCategory: 'カテゴリ',
    filterStatus: '学習状況',
    filterClear: 'クリア',
    filterResultEmpty: '条件に一致するカードがありません',
    settingsTitle: '設定',
    sectionStudy: '学習',
    sectionNotification: '通知',
    sectionData: 'データ',
    sectionLanguage: '学習モード',
    newCardsPerDay: '1日の新規カード数',
    dailyReminder: '毎日のリマインダー',
    reminderTime: '通知時刻',
    streakReminder: 'ストリークが途切れそうな日',
    streakReminderDesc: '学習していない日だけ、23:00にお知らせします',
    hourLabel: '時',
    minuteLabel: '分',
    pickerConfirm: '決定',
    notifPermissionRequired: '通知の許可が必要です。設定アプリで許可してください。',
    notifSystemOffTitle: 'iOSの設定で通知がオフになっています',
    notifSystemOffBody: '現在このアプリからの通知は届きません',
    notifOpenSettings: '設定を開く',
    notifOpenSettingsFailed: '設定アプリを開けませんでした',
    backupExport: 'バックアップを書き出す',
    backupExportDesc: '学習履歴をファイルに保存します（機種変更前に推奨）',
    backupImport: 'バックアップから復元',
    backupImportDesc: '書き出したファイルを読み込みます',
    backupImportConfirmTitle: 'バックアップから復元',
    backupImportConfirmBody: '現在の学習進捗はファイルの内容で上書きされます。よろしいですか？',
    backupImportFailed: 'ファイルを読み込めませんでした',
    resetData: '学習データをリセット',
    resetDataSubtitle: 'すべての学習進捗を削除します',
    resetConfirmTitle: '学習データをリセット',
    resetConfirmBody: 'すべての学習進捗が削除されます。この操作は取り消せません。',
    cancel: 'キャンセル',
    resetAction: 'リセット',
    resetDone: '学習データをリセットしました',
    languageLabel: 'あなたの言語',
    languageModeDescription: '日本語で表示し、海外エンジニアと働くための「技術英語」を学びます',
    updateStatusLabel: '📌 学習状況を更新',
    ratingSaved: '学習状況を更新しました',
    resetToNotStudied: '未学習に戻す',
    rangeStudyTitle: 'カテゴリを指定して学習',
    rangeStudySubtitle: 'カテゴリ・学習状況・範囲・出題順を選んで学習します',
    rangeSelectCategory: 'カテゴリ',
    rangeSelectStatus: '学習状況（複数選択可・未選択なら全て）',
    rangeSelectRange: '範囲（番号）',
    rangeSelectOrder: '出題順',
    rangeOrderAsc: '番号順',
    rangeOrderRandom: 'ランダム',
    rangeStart: 'この条件で学習',
    rangeCardsCount: '枚',
    rangeMatchCount: '枚が対象',
    rangeNoMatch: '条件に一致するカードがありません',
    newCardsOnHome: '1日の新規カード数',
    rangeMin: '最小',
    rangeMax: '最大',
    newCardsMaxLabel: '最大',
    newStudyCardsHeading: '1日の新規学習カード数',
    presetSteadyName: 'マイペース',
    presetStandardName: 'スタンダード',
    presetSpeedName: 'スピード学習',
    historyTitle: '学習カレンダー',
    historyStudied: '学習した日',
    historyNotStudied: '未学習',
    historyThisMonth: '今月の学習日数',
    historyTotalDays: '累計の学習日数',
    historyThisMonthCards: '今月の学習枚数',
    historyTotalCards: '累計の学習枚数',
    historyTapDayHint: '日付をタップすると、その日に学習した枚数が見られます',
    historyNoStudyThatDay: '学習なし',
    sessionHelpTitle: '今日のセッションの見かた',
    sessionHelpTooltip: 'この画面の説明',
    levelUpTitle: 'LEVEL UP!',
    levelWord: 'レベル',
    continueButton: '続ける',
    streakGoalReached: '今日のストリーク達成！',
    xpEarned: '獲得XP',
    keepGoing: 'どんまい！次いこう',
    weeklyTitle: '今週の学習',
    searchTitle: 'カード検索',
    searchHint: 'フレーズや日本語で検索',
    searchEmpty: '見つかりませんでした',
    proSection: 'ShipIt Pro',
    proStatusFree: '無料プラン',
    proStatusActive: 'Pro（有効）',
    upgradeToPro: 'Proにアップグレード',
    manageSubscription: 'サブスクリプションを管理',
    manageSubscriptionDesc: 'プラン変更・解約（App Storeが開きます）',
    restorePurchases: '購入を復元',
    restorePurchasesDesc: '機種変更・再インストール時にご利用ください',
    restoreSuccess: '購入を復元しました',
    restoreNotFound: '復元できる購入が見つかりませんでした',
    proSliderHint: '無料プランは1日5枚まで。Proで無制限',
    proLockedCategory: 'このカテゴリは Pro で利用できます',
  );

  // === English (for English speakers learning technical Japanese) ===
  static const en = AppStrings._(
    mode: LanguageMode.en,
    tabHome: 'Home',
    tabCategories: 'Categories',
    tabSettings: 'Settings',
    loadError: 'Failed to load content',
    todaysSession: "Today's Session",
    newCards: 'New',
    reviewCards: 'Review',
    studyScopeNewOnly: 'New',
    studyScopeReviewOnly: 'Review',
    studyScopeBoth: 'Both',
    sessionTotalLabel: 'Total',
    startLearning: 'Start Learning',
    sessionCompleteToday: "Today's session complete!",
    reviewAgain: 'Review again',
    noCardsToReview: 'No cards to review right now',
    allMastered: '🎊 All cards mastered!',
    reviewWeakCards: 'Review weak cards',
    progressTitle: 'Progress',
    tapToFlip: 'Tap the card to flip',
    swipeHint: '← Forgot ・ Got it →  You can also swipe',
    ratingForgot: 'Forgot',
    ratingUncertain: 'Unsure',
    ratingRemembered: 'Got it',
    exitDialogTitle: 'End this session?',
    exitDialogBody: 'Cards you have already rated will be saved.',
    exitDialogContinue: 'Continue',
    exitDialogQuit: 'End',
    emptySession: 'No cards to study right now',
    exampleLabel: '💬 Example',
    usageLabel: '📍 When to use',
    sessionCompleteTitle: 'Session Complete!',
    statStudied: 'Studied',
    statCorrect: 'Correct',
    statTime: 'Time',
    statStreak: 'Streak',
    newWordsLearned: 'New phrases learned',
    reviewsCompleted: 'Reviews completed',
    backToHome: 'Back to Home',
    categoriesTitle: 'Categories',
    genericError: 'Something went wrong',
    cardsLoadError: 'Failed to load cards',
    studyThisCategory: 'Study this category',
    noCardsInCategory: 'No cards to study in this category today',
    statusNew: 'Not studied',
    filterTitle: 'Filter',
    filterCategory: 'Category',
    filterStatus: 'Status',
    filterClear: 'Clear',
    filterResultEmpty: 'No cards match your filters',
    settingsTitle: 'Settings',
    sectionStudy: 'Study',
    sectionNotification: 'Notifications',
    sectionData: 'Data',
    sectionLanguage: 'Learning Mode',
    newCardsPerDay: 'New cards per day',
    dailyReminder: 'Daily reminder',
    reminderTime: 'Reminder time',
    streakReminder: 'When your streak is at risk',
    streakReminderDesc: 'Only on days you haven\'t studied, at 23:00',
    hourLabel: 'Hour',
    minuteLabel: 'Min',
    pickerConfirm: 'Done',
    notifPermissionRequired:
        'Notification permission is required. Please allow it in the Settings app.',
    notifSystemOffTitle: 'Notifications are turned off in iOS Settings',
    notifSystemOffBody: 'This app cannot deliver any notifications right now',
    notifOpenSettings: 'Open Settings',
    notifOpenSettingsFailed: 'Could not open the Settings app',
    backupExport: 'Export backup',
    backupExportDesc: 'Save your learning history to a file',
    backupImport: 'Restore from backup',
    backupImportDesc: 'Load a previously exported file',
    backupImportConfirmTitle: 'Restore from backup',
    backupImportConfirmBody:
        'Your current progress will be overwritten with the file contents. Continue?',
    backupImportFailed: 'Could not read the file',
    resetData: 'Reset learning data',
    resetDataSubtitle: 'Deletes all learning progress',
    resetConfirmTitle: 'Reset learning data',
    resetConfirmBody:
        'All learning progress will be deleted. This cannot be undone.',
    cancel: 'Cancel',
    resetAction: 'Reset',
    resetDone: 'Learning data has been reset',
    languageLabel: 'Your language',
    languageModeDescription: 'Shown in English — learn the technical Japanese to work with Japanese engineers',
    updateStatusLabel: '📌 Update your progress',
    ratingSaved: 'Progress updated',
    resetToNotStudied: 'Reset to not studied',
    rangeStudyTitle: 'Study a category',
    rangeStudySubtitle: 'Pick category, status, range and order',
    rangeSelectCategory: 'Category',
    rangeSelectStatus: 'Status (multi-select, none = all)',
    rangeSelectRange: 'Range (numbers)',
    rangeSelectOrder: 'Order',
    rangeOrderAsc: 'By number',
    rangeOrderRandom: 'Random',
    rangeStart: 'Study with these settings',
    rangeCardsCount: 'cards',
    rangeMatchCount: 'cards match',
    rangeNoMatch: 'No cards match these settings',
    newCardsOnHome: 'New cards per day',
    rangeMin: 'Min',
    rangeMax: 'Max',
    newCardsMaxLabel: 'Max',
    newStudyCardsHeading: 'New study cards per day',
    presetSteadyName: 'Steady',
    presetStandardName: 'Standard',
    presetSpeedName: 'Speed',
    historyTitle: 'Study Calendar',
    historyStudied: 'Studied',
    historyNotStudied: 'Not studied',
    historyThisMonth: 'Days this month',
    historyTotalDays: 'Total days',
    historyThisMonthCards: 'Cards this month',
    historyTotalCards: 'Cards total',
    historyTapDayHint: 'Tap a date to see how many cards you studied that day',
    historyNoStudyThatDay: 'No study',
    sessionHelpTitle: 'Understanding Today\'s Session',
    sessionHelpTooltip: 'About this screen',
    levelUpTitle: 'LEVEL UP!',
    levelWord: 'Level',
    continueButton: 'Continue',
    streakGoalReached: 'Today\'s streak complete!',
    xpEarned: 'XP earned',
    keepGoing: 'Keep going!',
    weeklyTitle: 'This Week',
    searchTitle: 'Search Cards',
    searchHint: 'Search phrases or translations',
    searchEmpty: 'No results found',
    proSection: 'ShipIt Pro',
    proStatusFree: 'Free plan',
    proStatusActive: 'Pro (active)',
    upgradeToPro: 'Upgrade to Pro',
    manageSubscription: 'Manage subscription',
    manageSubscriptionDesc: 'Change plan or cancel (opens the App Store)',
    restorePurchases: 'Restore purchases',
    restorePurchasesDesc: 'Use this after reinstalling or changing devices',
    restoreSuccess: 'Your purchase has been restored',
    restoreNotFound: 'No purchases found to restore',
    proSliderHint: 'Free plan: up to 5/day. Pro: unlimited',
    proLockedCategory: 'This category is available with Pro',
  );

  static AppStrings of(LanguageMode mode) =>
      mode == LanguageMode.ja ? ja : en;
}
