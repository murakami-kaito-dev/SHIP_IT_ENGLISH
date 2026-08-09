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
- `EngineerRank`（intern→junior→engineer→senior→staff→principal→distinguished）。`rankForLevel(level)` が帯の下限で判定（3/5/8/12/17/25）。
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
| `XPProgressBar` | レベルバッジ＋XPゲージ（easeOutQuartで滑らか・countはmono） |
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

## 統合ポイント
- Study：`_handleRating` で `registerAnswer`→エフェクト発火、レベルアップで `showLevelUpModal`。
- SessionComplete：`ConfettiCelebration`＋`StreakWidget(large)`＋獲得XP＋`XPProgressBar`。
- Home：ヘッダー `StreakWidget`（目標達成で強発光）＋ **`_LevelCard`（通算XP `totalXpValue` ＋ `XPProgressBar` ＋ 次LVまでの残りXP `xpToNext`）＝獲得経験値を常設で確認できる場所**。
- CTA `GradientButton` は押下 scale(0.95) spring（`onHighlightChanged`駆動）。
