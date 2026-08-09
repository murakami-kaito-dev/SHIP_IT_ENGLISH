# System: 発音音声（TTS / 事前生成・英語＋日本語）

自然な発音のため、**開発時に OpenAI TTS で音声を一括生成→同梱し、実行時は
再生するだけ（非通信）**。同梱が無いテキストは端末TTSにフォールバック。手順書は
[docs/tts_audio_generation.md](../../../docs/tts_audio_generation.md)。

- 声＝**nova（OpenAI `gpt-4o-mini-tts`・英語/日本語で共通）**。形式＝AAC(.m4a) 48kbps。
- **2ロケール同梱**：
  - `en-US`（jaモードの学習対象＝英語 phrase/example）：全3,826件・約124MB・`assets/audio/en-US/*.m4a`、manifest=`assets/audio/manifest.json`。
  - `ja-JP`（enモードの学習対象＝日本語 translation/example_translation）：全3,822件・約158MB・`assets/audio/ja-JP/*.m4a`、manifest=`assets/audio/ja-JP/manifest.json`。

## 実行時（[audio_clip_service.dart](../../../lib/core/services/audio_clip_service.dart) / [tts_service.dart](../../../lib/core/services/tts_service.dart)）
- `TtsService.speakTarget(text, mode)`：読み上げ対象ロケール（ja→en-US / en→ja-JP）を決め、
  - `AudioClipService.playIfAvailable(text, locale)` で該当ロケールの同梱音声を優先再生。
  - 無ければ従来の `flutter_tts`（iOSオーディオセッション: playback+defaultToSpeaker＝サイレントでも鳴る）。
  - enモード（日本語）は常に端末TTS。
- `AudioClipService`：起動時に `assets/audio/manifest.json` の keys 集合を読み、`sha1(text.trim())`
  で `assets/audio/en-US/<sha1>.m4a` を引いて audioplayers で再生。manifest/クリップが無ければ全部フォールバック（＝壊れない）。
- iOS/Androidの再生設定は `AudioContext` で playback系に設定。

## 生成（[tools/generate_tts.dart](../../../tools/generate_tts.dart)・開発時のみ）
- `dart run tools/generate_tts.dart --locale <en-US|ja-JP> --generate`（要 `OPENAI_API_KEY`）。
- 対象：en-US=`phrase`/`example`、ja-JP=`translation`/`example_translation`。OpenAIからWAV取得→`afconvert`でAAC(.m4a)圧縮（ffmpeg不要）。
- **差分生成**：既存 `<sha1>.m4a` はスキップ（`--force` で全再生成）。`--voice`/`--model`/`--bitrate`/`--limit`/`--delay`。通信例外・429は自動リトライ。
- `--poc` で声の聴き比べサンプルを `tools/tts_poc/` に生成（`index.html` をブラウザで開く）。
- 生成後 `assets/audio/en-US/` の実ファイルから `manifest.json` を作り直す。
- キー＝`sha1(テキストをtrim)`。生成側と実行側で**同じ正規化・同じsha1**なので必ず一致。

## 保守・注意
- カード追加時：cards.json更新 → `--generate`（増分のみ）→ m4aとmanifestをコミット。
- 男性音声を足す場合は別voiceで生成（将来）。実行時APIは一切叩かない（「データ収集なし」維持）。
- OpenAIの生成音声は商用利用可だが「**AI生成音声である旨の明示**」が必要（アプリ説明文に記載）。
- `tools/tts_poc/` は聴き比べ用スクラッチで gitignore 済み（コミットしない）。
