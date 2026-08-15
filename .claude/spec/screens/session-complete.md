# SessionComplete 画面（`/session-complete`）

- ファイル：[session_complete_screen.dart](../../../lib/features/study/presentation/session_complete_screen.dart)
- 役割：セッション完了の祝福＋結果サマリー。

## 入力
- `lastSessionResultProvider`（`SessionResult`：studiedCount, correctCount, newCardsCount, reviewCardsCount, duration, streakCount）。null なら「ホームに戻る」だけの簡易表示。
- `dailySessionInfoProvider.cardsStudiedToday`（目標達成判定）、`gamificationProvider.sessionXp`（今回獲得XP）。

## 構成（中央寄せ Column を `Stack` で包み紙吹雪を重ねる）
1. チェックマーク円 → タイトル。
2. **StreakWidget（large）**：連続日数・目標達成で強発光＋チェック＋`streakGoalReached`メッセージ。
3. 統計カード：学習数・正解(正答率)・時間・**獲得XP（+N）**。
4. **XPProgressBar**（獲得反映後のレベル/ゲージ）。
5. 新規/復習の内訳。
6. `GradientButton`「ホームに戻る」→ 結果をnull化して`/`。
7. `ConfettiCelebration`（表示時に自動発火）。

## 副作用（initState）
- `invalidateProgressProviders(ref)`（集計更新）。
- `SoundService.celebrate()`（音＋振動）。
- 2秒後 `ReviewService.maybeRequestReview(streakCount)`（ストリーク3日以上・未依頼時のみOSレビュー依頼）。

## 注意
- レベルアップの祝い（`showLevelUpModal`）は Study 画面側で発火済み（ここでは重ねない）。
- **パーフェクトセッション**：`SessionResult.perfect`（全カード1発で「覚えてた」・`perfectMinCards=5`枚以上・ユニットテスト除外＝`isPerfectSession` 純関数）のとき、タイトル下に金色の「⭐ PERFECT!」バナー＋ボーナス `perfectBonusXp=25` XP（study_screen `_completeSession` で `grantBonusXp(addToSession:true)`＝獲得XPに合算。通算回数は `keyPerfectSessions` に保存しバッジ判定に使う）。
