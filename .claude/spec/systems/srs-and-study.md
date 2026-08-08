# System: SRS・学習セッション

## SM-2 SRS（[srs_engine.dart](../../../lib/features/study/domain/srs_engine.dart)）
`processReview(current, rating) -> LearningProgress`（純関数・保存はしない）。
- 品質：forgot=1 / uncertain=3 / remembered=5。
- 正解（quality>=3）：repetitions++、interval = rep1→1日 / rep2→3日 / それ以降 `round(interval×ease)`。ease は SM-2式で増減、下限 `minimumEaseFactor=1.3`。interval>=`masteredThresholdDays(21)` で status=mastered、未満は review。
- 不正解（forgot）：repetitions=0, interval_days=0, status=learning。**next_review = now + `relearnStepMinutes(10)`分**（当日中の短い再学習ステップ＝忘却曲線基準）。
- `projectedInterval(current, rating)`：その評価を選んだ時の次回間隔（`processReview`を内部で呼ぶ）。RatingButtonsの「10分/1日/3日」表示に使う（表示＝実挙動）。

## 復習カードの決まり方
`getCardsForReview(asOf)`＝`next_review <= now AND status != 'new'`。よく覚えたカードほど
間隔が伸びるので毎日全部は来ない（負荷が分散）。

## デイリーセット / 新規枠
- `loadSession(maxNewCards)`：復習期限到来分＋**残り新規枠**の新規カード。
- **残り新規枠 = 1日の上限 − 今日学習した新規（daily_stats.new_cards / `getNewCardsStudiedToday`）**。途中離脱→再開で0/40に戻らない。
- `loadPracticeSession`：今日学習した未習得＋期限切れを苦手順（「もう一度復習」）。
- `loadCategoryStudySession(from,to,statuses,random)`：カテゴリの番号範囲・学習状況・順序指定。

## セッション状態（[study_providers.dart](../../../lib/features/study/providers/study_providers.dart)）
- `StudySessionNotifier`／`StudySessionState`：queue, currentCard, isFlipped, completed/totalUniqueCount, session(StudySession), retryCount, phase, newCardIds, reviewCardIds, **currentProgress**（めくった時に読み込み＝間隔予測用）。
- `copyWith` は `currentCard`/`currentProgress` を「変更なし」と「nullにする」で区別するセンチネル方式。
- `rateCard`：progress取得→`processReview`→保存→結果記録→「忘れた」はキュー末尾に再追加（`maxRetriesPerSession=2`）→次カードへ（currentProgressをnull化）。
- `flipCard`（async）：めくった時に currentProgress を読み込み isFlipped と同時set。
- `buildSessionResult`：ユニーク評価集計・ストリーク更新・当夜のストリーク通知キャンセル・daily_stats保存 → `SessionResult`。**途中離脱でも呼ぶ**。

## リポジトリ（[local_card_repository.dart](../../../lib/features/study/data/local_card_repository.dart)）
抽象 `CardRepository` / SQLite実装。主メソッド：getCardsForReview / getNewCards / getNewCardsStudiedToday / getCardsStudiedToday / getReviewCardsCount / getNewCardsCount / getPracticeCards / getProgress / saveProgress / saveDailyStats / getAllStudyDays / hasStudiedToday。

## テスト
`test/unit/{srs_engine,daily_set,study_session,streak}_test.dart`。SRSの間隔/mastered/forgotステップ・セッション完了・コンボ前提などを固定。
