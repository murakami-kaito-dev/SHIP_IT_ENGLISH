# 発音音声の生成（OpenAI TTS / オフライン同梱）

自然な英語発音のため、**開発時に一度だけ** OpenAI TTS で音声を一括生成し
`assets/audio/en-US/` に同梱する。**実行時はこの音声を再生するだけで API は叩かない**
（完全オフライン・「データ収集なし」申告に影響なし）。同梱が無いテキストは自動で
端末TTS（flutter_tts）にフォールバックする。

- 声: **nova（OpenAI・英語/日本語共通）**。モデル `gpt-4o-mini-tts`。
- 形式: OpenAI から WAV 取得 → macOS標準 `afconvert` で **AAC(.m4a) 48kbps** に圧縮（ffmpeg不要）。
- **2ロケール**（`--locale` で指定）:
  - `en-US`（既定）: `phrase`/`example`（英語）→ `assets/audio/en-US/`
  - `ja-JP`: `translation`/`example_translation`（日本語）→ `assets/audio/ja-JP/`
- 生成: **差分生成**（すでに作った音声は作り直さない）。通信例外・429は自動リトライ。

> 現状: en-US 3,826件（約124MB）＋ ja-JP 3,822件（約158MB）を同梱済み。
> 例) 日本語を生成: `dart run tools/generate_tts.dart --locale ja-JP --generate`

---

## 前提（初回だけ）
1. OpenAI アカウント作成: https://platform.openai.com
2. **クレジットを追加**（前払い制。$5程度）: https://platform.openai.com/settings/organization/billing/overview
   → 支払い方法を登録し「**Add to credit balance**」で残高購入（カード登録だけでは不足）。
3. **API キーを発行**（`sk-...`）し、`dart_defines.json` に追記（gitignore済み・非公開）:
   ```json
   { "GEMINI_API_KEY": "...", "OPENAI_API_KEY": "sk-..." }
   ```
   ※スクリプトは環境変数 `OPENAI_API_KEY` を優先し、無ければ dart_defines.json から読む。

## コマンド
| コマンド | 動作 |
|---|---|
| `dart run tools/generate_tts.dart` | ドライラン（件数だけ・生成しない） |
| `… --poc` | 声の聴き比べサンプルを `tools/tts_poc/` に生成（nova/shimmer/coral/sage） |
| `… --generate` | **未生成分だけ**生成（差分生成） |
| `… --generate --limit 20` | 先頭20件だけ（PoC） |
| `… --generate --force` | 既存も作り直す（声を変えた時など） |
| `… --generate --voice shimmer` | 別の声で生成 |
| `… --generate --bitrate 64000` | AACビットレート変更（既定48000＝軽量） |

- 長時間・安定運用のため `caffeinate -i dart run …` 推奨（スリープ防止）。
- 途中で止まっても **再実行で続きから**（差分生成）。声の聴き比べは `tools/tts_poc/index.html` をブラウザで開く。

## カードを追加したときの手順
1. `cards.json` にカード追加（既存ルール通り version も上げる）
2. `dart run tools/generate_tts.dart --generate`（要 OPENAI_API_KEY）→ **増えた分だけ**生成
3. `assets/audio/en-US/*.m4a` と `assets/audio/manifest.json` をコミット

## 仕組み（参考）
- ファイル名 = `sha1(テキストをtrim)` + `.m4a`。同じ文言は1ファイルに集約。
- 実行時は [audio_clip_service.dart](../lib/core/services/audio_clip_service.dart) が manifest の
  キー集合を起動時に読み、`speakTarget` のテキストのハッシュが在れば audioplayers で再生、
  無ければ [tts_service.dart](../lib/core/services/tts_service.dart) が端末TTSにフォールバック。
  生成側と実行側で**同じ正規化・同じsha1**を使う。

## 商用利用の注意
- OpenAI の生成音声は商用利用可。利用ポリシー上「**AI生成の音声である旨**」をユーザーに
  分かるようにする必要がある（アプリ説明文等に一言記載）。最新規約は要確認。
