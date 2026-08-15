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
- 上部：**2つの進捗表示は形を変えて区別する**（同じ形の横棒を並べると何のバーか分からなくなる）。
  - **セッション進捗** ＝ AppBar の数字（`9 / 15枚` ＋ `のこり 6枚`）と、**AppBar直下の全幅4pxヘアライン**（`AppBar.bottom` の `PreferredSize`）。「ページ全体の進み具合」を表す線。単位「枚」を必ず付ける。
  - **XP/レベル** ＝ `XPProgressBar`。白いカードの面の上に LVバッジ・ゲージ・次の到達点をまとめた部品。
  - 以前は同形の横棒が6px間隔で2本並び、下のバーは AppBar の数字と情報が完全重複していた。**横棒を2本並べないこと。**
- 中央：**出題形式によって切り替わる**（[domain/quiz.dart](../../../lib/features/study/domain/quiz.dart) `quizModeFor`）。
  - **flip（従来）**：`SwipeCardWrapper`（左=忘れた/右=覚えてた・閾値30%）で包んだ `FlipCard`（Y軸3Dフリップ300ms・表=英語→裏=訳/例文/使用場面・スピーカーで読み上げ）。
  - **choice / audio / cloze（クイズ）**：[quiz_card.dart](../../../lib/features/study/presentation/widgets/quiz_card.dart) `QuizCard`（設問＋4択→正誤ハイライト→答え合わせパネル→「つづける」）。誤答選択肢は同カテゴリから3枚（`quizDistractorsProvider`・cardIdシードで決定的＝リビルドで入れ替わらない）。取得失敗時は flip にフォールバック。
  - オーバーレイ（IgnorePointer）：`ComboOverlay`（COMBO×N）、`SparkleBurst`（正解時）、`XpGainPopup`（+XP）、不正解時 `_KeepGoingChip`（どんまい！）。
  - 画面枠：`FeverFrame`（FEVER中パルス発光）。
- 下部：`RatingButtons`（忘れた/曖昧/覚えてた＋各ボタン下に**次回復習間隔**「10分/1日/3日」=`SrsEngine.projectedInterval`）。**flip形式の裏面表示時のみ**（クイズは選択肢＋つづけるがカード内にあるため下部は出さない）。

## 出題形式（単調さを断つ・[domain/quiz.dart](../../../lib/features/study/domain/quiz.dart)）
- **新規カード・再出題（忘れた後）は必ず flip**（まず学ぶ／学び直す）。復習カードのみクイズ対象。
- 抽選は `quizModeFor(cardId, sessionSeed)` で**セッション内決定的**（flip40% / choice25% / audio20% / cloze15%）。シードは `_quizSeed`（画面Stateで固定）。
- 形式の向き（`buildQuizQuestion`）：ja=設問英語→選択肢和訳 / en=設問和訳→選択肢英語。audio は `speakTarget` と同じ向きで自動再生＋タップ再生。cloze は英語例文の穴埋め（`clozeExample`。**enモード・フレーズが例文に無い場合は choice にフォールバック**）＋例文訳を補助表示。
- **クイズの正誤→SRS評価**：正解=`remembered` / 不正解=`forgot`（`_handleQuizAnswered` が `flipCard()`→`_handleRating` を呼ぶ。isFlipped 前提の `rateCard` を満たすため）。不正解カードは再出題され flip で学び直す。
- テスト：[quiz_modes_test.dart](../../../test/unit/quiz_modes_test.dart)（決定性・新規/再出題=flip・空欄化・選択肢4/正解1・向き・並び安定）。

## 評価フロー `_handleRating`
1. 評価前に「1回目か（retryCount==0）」を判定 → `rateCard(rating)`（SRS更新・保存）。
2. `gamificationProvider.registerAnswer(rating, firstTry)` → `AnswerOutcome` で音/振動/オーバーレイ発火。
3. デイリークエストへ記録（`dailyQuestsProvider.recordAnswer`）。
4. レベルアップなら `showLevelUpModal`（閉じるまで待つ）。
5. `phase==completed` なら `_completeSession()`→ 結果を `lastSessionResultProvider` に入れ `context.go('/session-complete')`。

## 重要な仕様
- **途中離脱**（戻る/システムバック）でも `buildSessionResult()` を呼び、その時点までを daily_stats/ストリークに記録。
- 完了処理は try/catch＋`_completing` ガード（副作用失敗でも必ず遷移／二重起動防止）。
- 「忘れた」はセッション内で最大2回まで再出題（`retryCount`・`maxRetriesPerSession`）。
- カード読み上げは jaモードで同梱音声優先→無ければ端末TTS（[systems/tts-audio.md](../systems/tts-audio.md)）。
