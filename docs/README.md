# docs/ — 人間向けの操作手順・申請ドキュメント

このフォルダは「**どう操作するか（how-to）**」を置く場所。
アプリの「**何であるか（仕様）**」は `.claude/spec/` を参照（仕様駆動開発の"正"）。

## ドキュメントの役割分担
| 置き場所 | 内容 |
|---|---|
| `.claude/spec/` | **画面・システムの仕様（正）**。コードを読む前にまずここ |
| `.claude/docs/release-log.md` | **リリース履歴（正）**。どのビルドで何を配信したか・状態（バージョン/ビルド番号を上げたら即追記） |
| `docs/`（ここ） | ビルド/申請/生成などの操作手順（how-to） |
| `CLAUDE.md` | 開発ルール・規約・注意事項（エージェント向け） |
| `.claude/rules/` | パス限定で常時効くルール（例 `lib/**/*.dart`） |
| `.claude/skills/` | 再利用スキル（配布・演出・教材など） |

## 一覧
| ファイル | 用途 |
|---|---|
| `build_and_release.md` | ビルド・署名・ストア申請の操作手順 |
| `app_store_connect_submission.md` | App Store Connect 申請の全手順・全入力値 |
| `app_store_free_release_checklist.md` | 課金なし配布の対応済み項目＋開発者の手作業チェックリスト |
| `subscription_setup_guide.md` | サブスク（ShipIt Pro）の有効化手順・Sandboxテスト |
| `tts_audio_generation.md` | 発音音声（Amazon Polly）の生成・AWSセットアップ・差分生成 |
| `backup_and_restore.md` | 学習データのバックアップ/復元の仕様と操作 |
| `feature_recommendations.md` | 追加機能の優先度リスト |
| `shipit_english_spec_v4.md` | 初期の詳細要件（参考・履歴。最新仕様は `.claude/spec/`） |
