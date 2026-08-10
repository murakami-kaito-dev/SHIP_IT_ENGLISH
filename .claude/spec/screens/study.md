# Study 画面（`/study`）

- ファイル：[study_screen.dart](../../../lib/features/study/presentation/study_screen.dart) / [study_providers.dart](../../../lib/features/study/providers/study_providers.dart)
- 役割：カードをめくって自己評価する学習の中核。演出（ゲーミフィケーション）もここで発火。
- 詳細ロジックは [systems/srs-and-study.md](../systems/srs-and-study.md) と [systems/gamification.md](../systems/gamification.md)。

## モード（クエリで分岐・initState でセッション読込）
- 通常デイリー：`loadSession(maxNewCards)`（復習期限到来分＋残り新規枠）。
- `mode=practice`：`loadPracticeSession`（今日学習した未習得＋期限切れを苦手順）。
- `category` + `from`/`to`(+`statuses`,`order`)：`loadCategoryStudySession`（範囲/状況/順序指定）。
  - 範囲指定は `range_study_sheet.dart`。番号の最小#/最大#は**ダイヤルピッカー**（共通 [shared/widgets/dial_picker.dart](../../../lib/shared/widgets/dial_picker.dart) `DialPicker`＝`CupertinoPicker`ベース・学習枚数設定と同一）を左右に2つ（`_RangeMinMaxSelector`・StatefulWidget）。**常に 最小#≦最大# を維持**：最小を上げて最大を超えたら最大を最小まで**即ジャンプ連動**、最大を下げて最小を下回ったら最小を最大まで即ジャンプ連動。フラグは**左右独立**（`_syncingMin`/`_syncingMax`＋postframe解除）＝連動側だけ onChanged を無視し、フリング中も反対側のユーザー操作を止めない（共有フラグだと最終値の連動が伝わらず 最小#＞最大# が成立してしまうため）。カテゴリ詳細の「学習/聴く」から開き、`RangeSheetMode` で学習/耳学を出し分け（[systems/listening.md](../systems/listening.md)）。
- 無料プランは新規カードの出所を `freeCategoryIds` に限定。

## 画面構成
- AppBar：戻る（`_exitSession`）＋「完了数 / 総数」。
- 上部：**XPProgressBar**（レベル＋XP・FEVER中は発光）＋ セッション進捗バー。
- 中央：`SwipeCardWrapper`（左=忘れた/右=覚えてた・閾値30%）で包んだ `FlipCard`（Y軸3Dフリップ300ms・表=英語→裏=訳/例文/使用場面・スピーカーで読み上げ）。
  - オーバーレイ（IgnorePointer）：`ComboOverlay`（COMBO×N）、`SparkleBurst`（正解時）、`XpGainPopup`（+XP）、不正解時 `_KeepGoingChip`（どんまい！）。
  - 画面枠：`FeverFrame`（FEVER中パルス発光）。
- 下部：`RatingButtons`（忘れた/曖昧/覚えてた＋各ボタン下に**次回復習間隔**「10分/1日/3日」=`SrsEngine.projectedInterval`）。裏面表示時のみ。

## 評価フロー `_handleRating`
1. 評価前に「1回目か（retryCount==0）」を判定 → `rateCard(rating)`（SRS更新・保存）。
2. `gamificationProvider.registerAnswer(rating, firstTry)` → `AnswerOutcome` で音/振動/オーバーレイ発火。
3. レベルアップなら `showLevelUpModal`（閉じるまで待つ）。
4. `phase==completed` なら `_completeSession()`→ 結果を `lastSessionResultProvider` に入れ `context.go('/session-complete')`。

## 重要な仕様
- **途中離脱**（戻る/システムバック）でも `buildSessionResult()` を呼び、その時点までを daily_stats/ストリークに記録。
- 完了処理は try/catch＋`_completing` ガード（副作用失敗でも必ず遷移／二重起動防止）。
- 「忘れた」はセッション内で最大2回まで再出題（`retryCount`・`maxRetriesPerSession`）。
- カード読み上げは jaモードで同梱音声優先→無ければ端末TTS（[systems/tts-audio.md](../systems/tts-audio.md)）。
