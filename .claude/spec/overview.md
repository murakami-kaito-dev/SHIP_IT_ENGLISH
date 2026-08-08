# Overview — アプリ全体像

## プロダクト
- **ShipIt English**：海外テック企業で働くための「技術英語」を、毎日5〜10分のSRS学習で習得するアプリ。
- 単語暗記ではなく、コードレビュー/会議/Slack/インシデント対応などの**現場フレーズと文脈**を学ぶ。
- **2言語モード**：ja=日本語話者が技術英語を学ぶ / en=英語話者が技術日本語を学ぶ。UIも切替。
- **完全オフライン・データ収集なし・広告なし・トラッキングなし**（App Store申告と一致）。
- 現状：Phase1 MVP完成、無料配布（課金は休眠）、iPhone専用。

## 技術スタック
| 項目 | 内容 |
|---|---|
| Flutter / Dart | 3.24.3 / 3.5.3 |
| 状態管理 | Riverpod（StateNotifier / FutureProvider / autoDispose・手動プロバイダー、コード生成は不使用） |
| ローカルDB | SQLite（sqflite） |
| ルーティング | go_router（ShellRoute + NoTransitionPage） |
| 通知 | flutter_local_notifications + timezone |
| 設定 | shared_preferences |
| 音声 | audioplayers（事前生成音声）/ flutter_tts（フォールバック） |
| 演出 | confetti + Flutter組み込みアニメーション |
| 課金 | in_app_purchase（休眠中） |

## ディレクトリ地図
```
lib/
├── main.dart                # 起動・初期化（DB→通知→prefs読込→runApp）
├── app.dart                 # GoRouter + AppShell + BottomNavigationBar
├── core/
│   ├── constants/app_constants.dart      # SRS/通知/prefsキー等の定数
│   ├── database/{database_helper,seed_data}.dart  # スキーマ・マイグレ・JSON投入
│   ├── i18n/app_strings.dart             # 全UI文言（ja/en）。stringsProvider経由
│   ├── monetization/*                    # 課金・権利・設定（休眠）
│   ├── providers/{core_providers,language_provider,progress_refresh}.dart
│   ├── services/{tts_service,audio_clip_service,sound_service,
│   │             notification_service,streak_manager,review_service,backup_service}.dart
│   ├── theme/app_theme.dart              # 色/影/文字（デザインシステムの単一の源）
│   └── utils/date_utils.dart
├── features/<feature>/{presentation,providers,domain,data}/
│   └── home / study / categories / settings / history / search /
│       onboarding / paywall / gamification
└── shared/widgets/*         # 画面横断の共通部品
assets/
├── data/cards.json          # カード本体（唯一の正・1913枚/14カテゴリ・v2.0.0）
└── audio/                   # 事前生成した発音音声（manifest.json + en-US/*.mp3）
tools/generate_tts.dart      # 開発時: Pollyで音声一括生成（実行時は不使用）
docs/*                       # 人間向けの操作手順・申請・配布・生成手順
```

## 命名・実装規約（要点。詳細は CLAUDE.md）
- **UI文言はハードコード禁止** → `app_strings.dart` に ja/en 定義、`stringsProvider` 経由。
- **色/影/文字は `AppTheme.*` のみ**（google_fonts不使用＝ネット非通信）。`withOpacity()`使用（`withValues`不可）。
- **学習進捗を変えたら `invalidateProgressProviders(ref)`**（Home/カテゴリ集計のキャッシュ更新）。
- **Pro判定は `isProProvider` 経由のみ**（休眠時は常にtrue）。無料/Pro境界は `MonetizationConfig` だけ。
- **実行時ネットワーク通信の追加は要確認**（「データ収集なし」申告を崩さない）。
- カード状況の表示は `Rating`（忘れた/曖昧/覚えてた/未学習=null）で統一。`CardStatus`（SRS内部）は画面に出さない。

## アプリの機能マップ（どの spec を見るか）
- 学習の中核 → [systems/srs-and-study.md](systems/srs-and-study.md) + [screens/study.md](screens/study.md)
- 継続/報酬演出 → [systems/gamification.md](systems/gamification.md)
- 発音 → [systems/tts-audio.md](systems/tts-audio.md)
- 課金 → [systems/monetization.md](systems/monetization.md)
- 文言/テーマ/通知/バックアップ → [systems/platform-and-ui.md](systems/platform-and-ui.md)
