# System: ゲーミフィケーション

- コード：[features/gamification/](../../../lib/features/gamification/)（domain / providers / presentation/widgets）＋ [sound_service.dart](../../../lib/core/services/sound_service.dart)。
- 準拠 Skill：`.claude/skills/gamification-us`・`.claude/skills/animation-effects`。

## ロジック（[gamification_providers.dart](../../../lib/features/gamification/providers/gamification_providers.dart) / [gamification.dart](../../../lib/features/gamification/domain/gamification.dart)）
- `gamificationProvider`（StateNotifier）に集約。`GamificationState{ snapshot, combo, sessionXp }`。
- `registerAnswer(rating, firstTry) -> AnswerOutcome{ rating, firstTryCorrect, xpGained, combo, fever, leveledUp, newLevel }`。
  - コンボ：1回で正解（remembered/uncertain かつ firstTry）で+1、forgotで0。
  - XP：基礎（remembered12/uncertain6/forgot3）＋コンボボーナス（×2・上限20）、**FEVER中は×1.5**。
  - **FEVER = combo>=5**（`feverThreshold`）。
- `startSession()` でコンボ・sessionXp をリセット（セッション開始時）。
- **永続化は XP総量だけ**（`keyTotalXp`）。レベル/レベル内進捗は `GamificationSnapshot.fromTotalXp`（`xpForLevel(l)=60+l*40`）で都度算出。
- チューニングは **`GamificationConfig` 定数のみ**（XP量・閾値・倍率・`dailyGoalCards=20`・`streakFreezeCost=200`・`maxStreakFreezes=3`）。

## 称号（レベルの意味づけ・[gamification.dart](../../../lib/features/gamification/domain/gamification.dart)）
- `EngineerRank`（Intern→Junior→Engineer→Senior→Staff→Principal→Distinguished）。`rankForLevel(level)` が帯の下限で判定（**5/10/16/24/34/50**。レベル=頻繁な短期達成感/称号=長期目標の二層。以前の 3/5/8/12/17/25 は「シニア4日・最高1ヶ月」で軽すぎた）。**表示は言語モードに関わらず英語**（`rankName`・ユーザー指定）。
- 表示名は言語モード別に `AppStrings.rankName(rank)`（UI文言はハードコード禁止の方針に従い app_strings に集約。app_strings が gamification 定義を import）。
- 出す場所：Home `_LevelCard`（称号ピル）＋ `showLevelUpModal`（レベルバッジ下に称号）。

## ストリーク保護（XPを使う特典・「使えるXP」経済）
- **通算XP（`totalXp`）はレベル/称号の基準なので減らさない**。交換は使用済みXP（`spentXp`・`keySpentXp`）を増やす方式で、**使えるXP = totalXp − spentXp**（`GamificationState.availableXp`・0未満にならない）。
- `buyStreakFreeze()`：`canBuyStreakFreeze`（残高≥`streakFreezeCost` かつ 所持<`maxStreakFreezes`）のとき spentXp+=cost / streakFreezes+=1 を永続化（`keyStreakFreezes`）。
- **自動消費は起動時**：[streak_manager.dart](../../../lib/core/services/streak_manager.dart) `checkAndUpdateStreak()` が、空いた日数（`daysDiff-1`）を保護で埋められるなら消費して `lastStudyDate` を前日に橋渡し（連続維持）。足りなければ従来どおりリセット。消費数は `keyStreakFreezeUsedPending` に積み、Home が `takeStreakFreezeUsedNotice()` で一度だけ SnackBar 通知（→ `refreshStreakFreezes()` で状態同期）。
- 交換UIは Home `_StreakShieldCard`（使えるXP・所持盾・交換ボタン。上限/残高不足でボタン文言が変化）。

## 演出ウィジェット（presentation/widgets）
| Widget | 役割 |
|---|---|
| `ComboOverlay` | 「COMBO×N」を elasticOut で弾ませ＋ネオングロー。5でFEVERタグ |
| `FeverFrame` | FEVER中の画面枠パルス発光 |
| `XpGainPopup` | 「+N XP」が浮上して消える |
| `SparkleBurst` | 正解時の粒子（軽量CustomPainter・外部パッケージ不使用） |
| `XPProgressBar` | 白カード上に LVバッジ＋XPゲージ＋**次の到達点**（`xpToNext`／85%超で `xpAlmost` の煽り文言）。25%ごとの刻み目で1回分(+12XP程度)の増加も体感できる。FEVER/コンボはチップで併記。easeOutQuartで滑らか・countはmono・単位「XP」必須 |
| `XpFlyToBar` | 獲得XPがカード付近から立ち上がり、**上のXPバーへ吸い込まれる**。answer→XP→ゲージ増加の因果を見せる。カード内のStackはクリップされるので**外側のStackに置く**こと |
| `ConfettiCelebration` | 紙吹雪（confettiパッケージ・下向き噴出） |
| `showLevelUpModal` | 「LEVEL UP!」を Scale-up+Bounce＋紙吹雪＋音/振動 |
| `StreakWidget` | 🔥 breathingパルス・目標達成で強発光＋チェック（home小/完了画面large） |
| `PressScale` | タップで scale(0.95)→elasticOutで戻る汎用ラッパー |

## 五感フィードバック（[sound_service.dart](../../../lib/core/services/sound_service.dart)）
- `SoundService`（singleton）に tap/correct/combo/fever/levelUp/celebrate/retry のフック。
- **実SFXを再生**：事前生成した効果音 `assets/audio/sfx/{correct,combo,fever,levelup}.m4a`（純Dart合成→`afconvert`でAAC・各5〜8KB・**オフライン非通信**）を `audioplayers` で再生。ハプティクスも併用。
  - correct=軽い上昇2音／combo=明るいベル（**コンボ数に応じ `setPlaybackRate` でピッチ上昇**・上限1.6）／fever=きらめくアルペジオ／levelUp=ファンファーレ／celebrate=ファンファーレ流用／**retry（不正解）=`soft`（沈まない柔らかい中立音・音量0.7）**。tap は音なし（触覚のみ）。
  - **マナーモード尊重**：SFXは iOS `ambient` カテゴリ（サイレントスイッチONでは鳴らない）。再生直前に `AudioPlayer.global.setAudioContext(ambient)` を設定し直す。
  - **発音音声（AudioClipService）は別扱い**：学習の核なので消音でも鳴らす。`playback`（＋`mixWithOthers`のみ）を**各再生の直前に**設定し直して、SFXの ambient を上書きする（両者は互いに干渉しない）。
  - ⚠️ iOSの `defaultToSpeaker` は `playAndRecord` 専用。`playback` と併用すると `Error -50` でセッション設定が失敗し**音が鳴らない**（実機で発覚。`playback` は元々スピーカー出力＋消音無視なので不要）。
- **直接 HapticFeedback を撒かず必ず SoundService 経由**。
- SFXの音そのものを作り直す場合の合成レシピは開発メモに残す（`_render`＝基音＋オクターブ＋5度のベル風・指数減衰）。

## デイリークエスト＋宝箱（[quests.dart](../../../lib/features/gamification/domain/quests.dart) / [quests_providers.dart](../../../lib/features/gamification/providers/quests_providers.dart) / [daily_quests_card.dart](../../../lib/features/gamification/presentation/widgets/daily_quests_card.dart)）
- **目的**：日替わりのお題で「今日開く理由」を作る（アポイントメント機構＋可変報酬）。
- **生成は決定的**：`questsForDate(date)` が日付シードの Random で毎日3件生成（**保存しない**。同日は常に同じお題）。1つ目は必ず `studyCards`（入口を低く）、残り2つは combo/remembered/listenLines から重複なしで抽選。目標値候補・宝箱報酬は `QuestConfig` に集約。
- **進捗はカウンタのみ永続化**（`keyQuestProgress`・日付付きJSON）。日付が変わると `ensureToday()`（冪等）でリセット。採用されていない指標も常に記録する（どの組み合わせでも正しく進む）。
  - 学習：study_screen `_handleRating` → `recordAnswer(rating, combo)`（枚数・覚えてた回数・コンボ最大値）。
  - 耳学：`ListeningController(onLineCompleted:)` → `recordListenLine()`（**自然に聴き切った行のみ**。スキップ/停止は数えない）。
- **宝箱（可変報酬）**：3件全達成で `claimChest()`（1日1回）。`rollChestReward` が XP 30〜60 を抽選＋10%でストリーク保護+1（所持上限未満のときだけ）。付与はUI側が `grantBonusXp` / `grantStreakFreeze`（無償・上限共通）で実施。演出は 🎁ダイアログ（elasticOut＋紙吹雪＋celebrate音）。
- **UI**：Home のセッションカード直下 `DailyQuestsCard`（3行の進捗バー＋宝箱エリア：ロック文言→開けるボタン→受領済みチップ）。文言は `AppStrings.questTitle(quest)` 等（ja/en）。
- テスト：[daily_quests_test.dart](../../../test/unit/daily_quests_test.dart)（決定性・重複なし・進捗記録・宝箱1回・日付切替・再起動復元）。

## 統合ポイント
- Study：`_handleRating` で `registerAnswer`→エフェクト発火、レベルアップで `showLevelUpModal`。
- SessionComplete：`ConfettiCelebration`＋`StreakWidget(large)`＋獲得XP＋`XPProgressBar`。
- Home：ヘッダー `StreakWidget`（目標達成で強発光）＋ **`_LevelCard`（通算XP `totalXpValue` ＋ `XPProgressBar` ＋ 次LVまでの残りXP `xpToNext`）＝獲得経験値を常設で確認できる場所**。
- CTA `GradientButton` は押下 scale(0.95) spring（`onHighlightChanged`駆動）。

## マスコット「ダッキー」（[duck_mascot.dart](../../../lib/features/gamification/presentation/widgets/duck_mascot.dart)）
- **エンジニア文化の「ラバーダック・デバッグ」にちなんだ相棒**。感情的つながり（アプリの人格）を作る。
- **CustomPainter のドット絵**（16×14グリッド・画像アセット不要・オフライン）。`DuckMood`＝idle（ゆっくり浮遊）/ happy（弾む）/ cheer（大きく弾む＋首振り）。
- 出す場所：
  - **Home AppBar 常駐**（`_HomeDuck`）：今日学習済みなら happy。**タップでランダムな一言**（`AppStrings.duckLines`・応援/Tips）を SnackBar 表示。
  - **セッション完了画面**：チェックマーク横で cheer。
  - **毎日リマインダー通知**：本文を `duckReminderLines` からランダム選択（🦆の人格。起動ごとの rescheduleAll で文面が変わる）。
- 文言はすべて `AppStrings`（ja/en）。
