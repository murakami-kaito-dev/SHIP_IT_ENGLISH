# System: 発音音声（TTS / 事前生成）

自然な英語発音のため、**開発時に Amazon Polly(Neural) で音声を一括生成→同梱し、実行時は
再生するだけ（非通信）**。同梱が無いテキストは端末TTSにフォールバック。手順書は
[docs/tts_audio_generation.md](../../../docs/tts_audio_generation.md)。

## 実行時（[audio_clip_service.dart](../../../lib/core/services/audio_clip_service.dart) / [tts_service.dart](../../../lib/core/services/tts_service.dart)）
- `TtsService.speakTarget(text, mode)`：
  - jaモード（読み上げ対象＝英語）：`AudioClipService.playIfAvailable(text)` で同梱音声を優先再生。
  - 無ければ従来の `flutter_tts`（iOSオーディオセッション: playback+defaultToSpeaker＝サイレントでも鳴る）。
  - enモード（日本語）は常に端末TTS。
- `AudioClipService`：起動時に `assets/audio/manifest.json` の keys 集合を読み、`sha1(text.trim())`
  で `assets/audio/en-US/<sha1>.mp3` を引いて audioplayers で再生。manifest/クリップが無ければ全部フォールバック（＝壊れない）。
- iOS/Androidの再生設定は `AudioContext` で playback系に設定。

## 生成（[tools/generate_tts.dart](../../../tools/generate_tts.dart)・開発時のみ）
- `dart run tools/generate_tts.dart --generate`（要 AWS CLI・`aws configure` 済み）。
- 対象：各カードの `phrase` と `example`（英語）。声＝US女性 **Joanna**（Neural）。mp3直接出力。
- **差分生成**：既存 `<sha1>.mp3` はスキップ（`--force` で全再生成）。オプション `--limit N`（PoC）/`--voice`/`--region`。
- 生成後 `assets/audio/en-US/` の実ファイルから `manifest.json` を作り直す。
- キー＝`sha1(テキストをtrim)`。生成側と実行側で**同じ正規化・同じsha1**なので必ず一致。

## 保守
- カード追加時：cards.json更新 → `--generate`（増分のみ）→ mp3とmanifestをコミット。
- 男性音声を足す場合は別voiceで生成（将来）。実行時APIは一切叩かない（「データ収集なし」維持）。
