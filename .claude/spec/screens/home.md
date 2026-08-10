# Home 画面（`/`）

- ファイル：[home_screen.dart](../../../lib/features/home/presentation/home_screen.dart) / [home_providers.dart](../../../lib/features/home/providers/home_providers.dart)
- 役割：今日の学習の起点。ストリーク・今日のセッション・週間サマリー・全体進捗を表示。

## 主なプロバイダー
- `dailySessionInfoProvider` → `DailySessionInfo`：newCardsCount(=今日の残り新規枠), newCardsLimit, newCardsStudiedToday, reviewCardsCount, totalCount, estimatedSeconds, streakCount, hasStudiedToday, cardsStudiedToday, practiceCardsCount。
- `overallProgressProvider`（studied/mastered/total）、`weeklyStatsProvider`（直近7日・暦週=日曜始まり）。
- 設定依存の再計算中もチラつかないよう `sessionInfo.when(skipLoadingOnReload: true)` を使う。

## レイアウト（上→下）
- **セクション見出しはすべて白カードの「外・上」に左揃え**（共通 `SectionHeader`＝[shared/widgets/section_header.dart](../../../lib/shared/widgets/section_header.dart)・`captionText`/w600/textSecondary）。**設定画面と同一ウィジェットで統一**（settings も同じ `SectionHeader` を使用）。カード内には見出しを持たない。
1. ヘッダー：`StreakWidget`（🔥 breathing・今日の目標`GamificationConfig.dailyGoalCards`達成で強発光＋チェック。タップ→`/history`）＋ 今日の日付。
2. **今日のセッション**：見出しは**カード外**（「今日のセッション」＋今日学習済みなら完了チップ `_SessionDoneChip`＋右端に「?」ヘルプ → `_showSessionHelp`）。カード `_TodaySessionCard` は見出しを持たず、**学習範囲セレクタ・各行・合計・CTAを白カード内に集約**：
   - **学習範囲セレクタ**（`SegmentedButton<StudyScope>`：新規のみ/復習のみ/両方）。設定に永続化（`settingsProvider.studyScope`・key `study_scope`・既定 both）。選択に応じて新規/復習の行が薄くなり、**合計＝選んだ範囲の枚数**（`sessionTotalLabel`＋`scopedTotal`）。所要時間表示は無し。
   - 新規行の値＝「残りX / 上限Y枚」（`newCardsRemainingOfLimit`）。今日学習済みなら補足キャプション。
   - StudyScope は `loadSession(scope:)` に渡り、reviewOnly=新規除外/newOnly=復習除外（**SRSの予定日サイクルは不変**）。
   - **1日の新規カード数の設定はここには無い**（設定タブへ移動。[settings.md](settings.md)）。
   - **CTA もカード内下部**：`GradientButton`「学習を始める」→`/study`、🎛（範囲指定シート `showRangeStudySheet`）、「もう一度復習」→`/study?mode=practice`（practiceCardsCount>0時のみ活性）。
   - 全カードmastered時のみ、このカードの代わりに `_AllMasteredCard` を表示。
3. **レベル** `_LevelCard`：見出し「レベル」はカード外。カード内は **称号ピル（左・`rankName(rankForLevel(level))`）＋ 通算XP（右・`totalXpValue`）** の spaceBetween 行＋ `XPProgressBar`＋次LVまでの残りXP（`xpToNext`）。XPは起動時に `keyTotalXp` から復元（[systems/gamification.md](../systems/gamification.md)）。
4. **ストリーク保護** `_StreakShieldCard`：見出し「ストリーク保護」はカード外。カード内は **所持盾＋所持N/M（左）＋ 使えるXP（右・`availableXpLabel`）** の spaceBetween 行＋説明＋交換ボタン（`buyStreakFreeze`・`streakFreezeCost`・最大`maxStreakFreezes`）。起動時に保護が自動消費されていたら `_HomeScreenState` が SnackBar で一度だけ通知（`takeStreakFreezeUsedNotice`→`refreshStreakFreezes`）。※このため HomeScreen は `ConsumerStatefulWidget`。
5. **今週の学習** `_WeeklySummaryCard`・**学習進捗** `_buildProgressSection`：どちらも見出しはカード外（`SectionHeader`）。中身は棒グラフ／全体進捗バー（`studiedCount`基準）。

## 重要な仕様
- **今日の残り新規枠 = 1日の上限 − 今日学習した新規（daily_stats.new_cards）**。途中でやめて再開しても満タンに戻らない（0/40→3枚やって0/37）。日付が変わると上限にリセット。
- 学習後の表示更新は `invalidateProgressProviders(ref)` に依存（Studyの完了/離脱時に呼ばれる）。
