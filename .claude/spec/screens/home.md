# Home 画面（`/`）

- ファイル：[home_screen.dart](../../../lib/features/home/presentation/home_screen.dart) / [home_providers.dart](../../../lib/features/home/providers/home_providers.dart)
- 役割：今日の学習の起点。ストリーク・今日のセッション・週間サマリー・全体進捗を表示。

## 主なプロバイダー
- `dailySessionInfoProvider` → `DailySessionInfo`：newCardsCount(=今日の残り新規枠), newCardsLimit, newCardsStudiedToday, reviewCardsCount, totalCount, estimatedSeconds, streakCount, hasStudiedToday, cardsStudiedToday, practiceCardsCount。
- `overallProgressProvider`（studied/mastered/total）、`weeklyStatsProvider`（直近7日・暦週=日曜始まり）。
- 設定依存の再計算中もチラつかないよう `sessionInfo.when(skipLoadingOnReload: true)` を使う。

## レイアウト（上→下）
1. ヘッダー：`StreakWidget`（🔥 breathing・今日の目標`GamificationConfig.dailyGoalCards`達成で強発光＋チェック。タップ→`/history`）＋ 今日の日付。
2. 学習済みなら `_TodayCompleteBanner`。
3. **今日のセッションカード** `_TodaySessionCard`：
   - 「?」ヘルプボタン → `_showSessionHelp`（各要素の意味をボトムシート説明。高さは画面の下2/3に制限）。
   - 新規行の値＝「残りX / 上限Y枚」（`newCardsRemainingOfLimit`）。今日学習済みなら補足キャプション。
   - 復習行・合計・所要時間。
   - **1日の新規カード数**の設定：`_NewCardsStepper`（− 直接入力 ＋・**入力即確定** onChanged）＋ `_NewCardsPresets`（5/10/25/50/100/最大）。上限＝総カード数（`overallProgressProvider.totalCount`）。
4. CTA：`GradientButton`「学習を始める」→`/study`、🎛（範囲指定シート）、「もう一度復習」→`/study?mode=practice`（practiceCardsCount>0時）。
5. 週間サマリー棒グラフ、全体進捗バー（`studiedCount`基準）。
6. 全カードmastered時は `_AllMasteredCard`。

## 重要な仕様
- **今日の残り新規枠 = 1日の上限 − 今日学習した新規（daily_stats.new_cards）**。途中でやめて再開しても満タンに戻らない（0/40→3枚やって0/37）。日付が変わると上限にリセット。
- 学習後の表示更新は `invalidateProgressProviders(ref)` に依存（Studyの完了/離脱時に呼ばれる）。
