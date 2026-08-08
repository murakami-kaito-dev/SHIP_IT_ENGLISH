# 発音音声の生成（Amazon Polly / オフライン同梱）

自然な英語発音を出すため、**開発時に一度だけ** Amazon Polly（Neural）でカードの英語
音声を生成し、`assets/audio/en-US/` に同梱する。**実行時はこの音声を再生するだけで
API は叩かない**（完全オフライン・「データ収集なし」申告に影響なし）。同梱音声が無い
テキストは自動的に端末TTS（flutter_tts）にフォールバックする。

- 声: **US・女性「Joanna」（Neural）**（男性を足す場合は `--voice Matthew` 等）
- 対象: 各カードの `phrase` と `example`（英語）。日本語（enモード）は端末TTSのまま。
- 生成: **差分生成**（すでに作った音声は作り直さない）。

---

## あなたがやること（初回だけ）

### 1. AWS アカウントと認証情報を用意する
1. AWS アカウントを作成（無料）: https://portal.aws.amazon.com/billing/signup
2. IAM で「プログラムアクセス用」のユーザーを作成し、**アクセスキーID / シークレット
   アクセスキー**を取得する（IAM ▸ Users ▸ Create user ▸ 後で「Access key」を作成）。
3. そのユーザーに Polly の権限を付与する。最小権限は以下（インラインポリシー例）:
   ```json
   { "Version": "2012-10-17",
     "Statement": [{ "Effect": "Allow", "Action": "polly:SynthesizeSpeech", "Resource": "*" }] }
   ```
   （手軽に済ませるなら AWS 管理ポリシー **AmazonPollyReadOnlyAccess** でも可）

### 2. AWS CLI を入れて設定する
```bash
brew install awscli            # まだ無ければ
aws configure                  # 上のアクセスキー/シークレット/リージョンを入力
#   AWS Access Key ID     : ****
#   AWS Secret Access Key : ****
#   Default region name   : us-east-1     ← Polly が使えるリージョン
#   Default output format : json
aws polly describe-voices --query "Voices[?Id=='Joanna'].Name" --output text   # 動作確認（Joanna が出ればOK）
```
> 認証情報は AWS CLI（`~/.aws/`）が持つ。**このリポジトリには保存しない**（生成
> スクリプトはキーを一切受け取らず `aws` コマンドを呼ぶだけ）。

### 3. まず PoC（数十件）で音質を確認
```bash
dart run tools/generate_tts.dart --generate --limit 20
```
- `assets/audio/en-US/*.mp3` が20件できる。アプリを実機/シミュレータで起動し、カードの
  スピーカーを押して**音質を確認**する（`flutter run`）。
- 声を変えたい場合は `--voice Matthew`（男性）等で数件試す。

### 4. 問題なければ全件生成
```bash
dart run tools/generate_tts.dart --generate
```
- 未生成分だけ生成する（差分生成）。約 3,800 クリップ（phrase+example）で数分〜。
- 生成費は Polly Neural で **数ドル程度**（約23万字 × $16/100万字）。
- 完了後 `assets/audio/manifest.json` が実ファイルから作り直される。

### 5. コミット
生成した mp3 と manifest.json をコミットする（＝ビルドに同梱される）。

---

## コマンド早見表
| コマンド | 動作 |
|---|---|
| `dart run tools/generate_tts.dart` | ドライラン（生成せず、件数だけ表示） |
| `… --generate` | **未生成分だけ**生成（差分生成） |
| `… --generate --limit 20` | 先頭20件だけ（PoC用） |
| `… --generate --force` | 既存も作り直す（声を変えた時など） |
| `… --generate --voice Matthew` | 別の声で生成（US男性 Neural） |
| `… --generate --region us-west-2` | リージョン指定（未指定は aws config） |

## カードを追加したときの手順
1. `cards.json` にカード追加（既存ルール通り version も上げる）
2. `dart run tools/generate_tts.dart --generate` → **増えた分だけ**生成
3. mp3 と manifest.json をコミット

## 仕組み（参考）
- ファイル名 = `sha1(テキストをtrimしたもの)` + `.mp3`。同じ文言は1ファイルに集約。
- 実行時は [audio_clip_service.dart](../lib/core/services/audio_clip_service.dart) が
  manifest のキー集合を起動時に読み、`speakTarget` のテキストのハッシュが在れば
  audioplayers で再生、無ければ [tts_service.dart](../lib/core/services/tts_service.dart)
  が端末TTSにフォールバックする。生成側と実行側で**同じ正規化・同じsha1**を使う。
