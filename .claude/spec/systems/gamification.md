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
- チューニングは **`GamificationConfig` 定数のみ**（XP量・閾値・倍率・`dailyGoalCards=20`）。

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
  - correct=軽い上昇2音／combo=明るいベル（**コンボ数に応じ `setPlaybackRate` でピッチ上昇**・上限1.6）／fever=きらめくアルペジオ／levelUp=ファンファーレ／celebrate=ファンファーレ流用。
  - **retry（不正解）は音を出さない**（触覚のみ・負の感情を軽減）／tap も音なし（触覚のみ）。
  - 再生失敗時は `SystemSound.click` にフォールバック。AudioContext は playback+mixWithOthers（サイレントスイッチでも鳴る／発音音声と混ざる）。
- **直接 HapticFeedback を撒かず必ず SoundService 経由**。
- SFXの音そのものを作り直す場合の合成レシピは開発メモに残す（`_render`＝基音＋オクターブ＋5度のベル風・指数減衰）。

## 統合ポイント
- Study：`_handleRating` で `registerAnswer`→エフェクト発火、レベルアップで `showLevelUpModal`。
- SessionComplete：`ConfettiCelebration`＋`StreakWidget(large)`＋獲得XP＋`XPProgressBar`。
- Home：ヘッダー `StreakWidget`（目標達成で強発光）＋ **`_LevelCard`（通算XP `totalXpValue` ＋ `XPProgressBar` ＋ 次LVまでの残りXP `xpToNext`）＝獲得経験値を常設で確認できる場所**。
- CTA `GradientButton` は押下 scale(0.95) spring（`onHighlightChanged`駆動）。
