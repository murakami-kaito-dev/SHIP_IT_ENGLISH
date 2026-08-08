# ShipIt English

海外テック企業で働くための「技術英語」を、毎日5〜10分の SRS 学習で習得する Flutter アプリ。
単語暗記ではなく、コードレビュー・会議・Slack・インシデント対応などの**現場フレーズと文脈**を学ぶ。
完全オフライン・データ収集なし・広告なし。iPhone 向け（Android も同梱）。

## ドキュメント（どこを見るか）
- **仕様（正）**: [`.claude/spec/`](.claude/spec/README.md) — 画面別・システム別の最新仕様。**コードを読む前にここ**（仕様駆動開発）。
- **開発ルール/規約**: [`CLAUDE.md`](CLAUDE.md)
- **操作手順（ビルド/申請/音声生成等）**: [`docs/`](docs/README.md)

## セットアップ
```bash
flutter pub get
flutter run            # 実機/シミュレータで起動
flutter test           # ユニットテスト
flutter analyze        # 静的解析
```
- カード本体は `assets/data/cards.json`（唯一の正・変更時は `version` を上げる）。
- 発音音声の生成は `docs/tts_audio_generation.md` を参照（開発時に Amazon Polly で一括生成・実行時は非通信）。

## 技術スタック
Flutter / Dart・Riverpod・SQLite(sqflite)・go_router・flutter_local_notifications・
audioplayers/flutter_tts・in_app_purchase（休眠）。詳細は [`.claude/spec/overview.md`](.claude/spec/overview.md)。
