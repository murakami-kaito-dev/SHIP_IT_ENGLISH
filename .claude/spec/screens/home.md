# Home 画面（`/`）

- ファイル：[home_screen.dart](../../../lib/features/home/presentation/home_screen.dart) / [home_providers.dart](../../../lib/features/home/providers/home_providers.dart)
- 役割：今日の学習の起点。ストリーク・今日のセッション・週間サマリー・全体進捗を表示。

## 主なプロバイダー
- `dailySessionInfoProvider` → `DailySessionInfo`：newCardsCount(=今日の残り新規枠), newCardsLimit, newCardsStudiedToday, reviewCardsCount, totalCount, estimatedSeconds, streakCount, hasStudiedToday, cardsStudiedToday, practiceCardsCount。
- `overallProgressProvider`（studied/mastered/total）、`weeklyStatsProvider`（直近7日・暦週=日曜始まり）。
- 設定依存の再計算中もチラつかないよう `sessionInfo.when(skipLoadingOnReload: true)` を使う。

## レイアウト（上→下）
1. ヘッダー：`StreakWidget`（🔥 breathing・今日の目標`GamificationConfig.dailyGoalCards`達成で強発光＋チェック。タップ→`/history`）＋ 今日の日付。
2. **今日のセッションカード** `_TodaySessionCard`（**タイトル・完了マーク・各行・合計・CTAを1枚の白カード内に集約**）：
   - タイトル行：「今日のセッション」＋（今日学習済みなら）タイトル横に小さな完了チップ `_SessionDoneChip`（`sessionDoneChip`＝「完了」・以前の大きな緑バナー `_TodayCompleteBanner` は廃止）＋ 右端に「?」ヘルプボタン → `_showSessionHelp`（各要素の意味をボトムシート説明。高さは画面の下2/3に制限）。
   - **学習範囲セレクタ**（`SegmentedButton<StudyScope>`：新規のみ/復習のみ/両方）。設定に永続化（`settingsProvider.studyScope`・key `study_scope`・既定 both）。選択に応じて新規/復習の行が薄くなり、**合計＝選んだ範囲の枚数**（`sessionTotalLabel`＋`scopedTotal`）。所要時間表示は無し。
   - 新規行の値＝「残りX / 上限Y枚」（`newCardsRemainingOfLimit`）。今日学習済みなら補足キャプション。
   - StudyScope は `loadSession(scope:)` に渡り、reviewOnly=新規除外/newOnly=復習除外（**SRSの予定日サイクルは不変**）。
   - **1日の新規カード数の設定はここには無い**（設定タブへ移動。[settings.md](settings.md)）。
   - **CTA もカード内下部**：`GradientButton`「学習を始める」→`/study`、🎛（範囲指定シート `showRangeStudySheet`）、「もう一度復習」→`/study?mode=practice`（practiceCardsCount>0時のみ活性）。
   - 全カードmastered時のみ、このカードの代わりに `_AllMasteredCard` を表示。
3. **`_LevelCard`（経験値/レベル）**：`gamificationProvider.snapshot` を watch。通算XP（`totalXpValue`）＋ **称号ピル**（`rankName(rankForLevel(level))`）＋ `XPProgressBar`（LVバッジ＋ゲージ）＋ 次LVまでの残りXP（`xpToNext`）。**獲得経験値を確認できる常設の場所**。XPは起動時に `keyTotalXp` から復元される（[systems/gamification.md](../systems/gamification.md)）。
4. **`_StreakShieldCard`（XPの使い道＝ストリーク保護）**：使えるXP（`availableXpLabel`）・所持盾（最大`maxStreakFreezes`）・交換ボタン（`buyStreakFreeze`・コスト`streakFreezeCost`）。起動時に保護が自動消費されていたら `_HomeScreenState` が SnackBar で一度だけ通知（`takeStreakFreezeUsedNotice`→`refreshStreakFreezes`）。※このため HomeScreen は `ConsumerStatefulWidget`。
5. 週間サマリー棒グラフ、全体進捗バー（`studiedCount`基準）。

## 重要な仕様
- **今日の残り新規枠 = 1日の上限 − 今日学習した新規（daily_stats.new_cards）**。途中でやめて再開しても満タンに戻らない（0/40→3枚やって0/37）。日付が変わると上限にリセット。
- 学習後の表示更新は `invalidateProgressProviders(ref)` に依存（Studyの完了/離脱時に呼ばれる）。
