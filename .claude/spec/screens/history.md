# History 画面（学習カレンダー・`/history`）

- ファイル：[history_screen.dart](../../../lib/features/history/presentation/history_screen.dart) / [history_providers.dart](../../../lib/features/history/providers/history_providers.dart)
- 役割：いつ・何枚学習したかを月カレンダーで振り返る。Home のストリーク🔥から遷移。

## 入力
- `studyDaysProvider` → `Map<'yyyy-MM-dd', int>`（日付→その日の学習枚数。0枚の日は含まない）。

## 構成（自前グリッド・外部パッケージ不使用）
- 月ヘッダー：前後の月送り（未来月へは進めない）。
- カレンダーグリッド：日曜始まり。学習日はグラデ＋発光。今日＝streakFire枠、**選択日＝primary太枠**。
- **日タップ**：`_SelectedDayDetail` にその日の学習枚数（`historyDayCards`）／未学習は「学習なし」。未選択時は操作ヒント。
- **サマリー**：今月/累計の「学習日数」＋「学習枚数」（`_cardsInMonth` で月合計、全体合計）。
- 凡例（学習した日/未学習）。

## 状態
- `_visibleMonth`（表示中の月）・`_selectedDate`（選択日。月送りで解除）。
