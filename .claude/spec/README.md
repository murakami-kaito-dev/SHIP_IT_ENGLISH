# ShipIt English — 仕様書（Spec-Driven Development）

このフォルダは**アプリの「正」の仕様**を画面・システム単位で記述したもの。
目的は、**コード全体を読まずに仕様を把握して開発する**（トークン節約）こと。

## 使い方（開発フロー）
1. これから触る画面/機能に対応する spec を**まず読む**（下の索引から1〜2ファイルだけ開く）。
2. 変更を実装する。
3. **仕様が変わったら、対応する spec を必ず更新する**（コードと spec を常に一致させる）。
   - spec に書いてある file:line や関数名は変更で古くなりうる。参照時は存在を確認する。

## 索引

### 基盤
| ファイル | 内容 |
|---|---|
| [overview.md](overview.md) | アプリ概要・技術スタック・ディレクトリ地図・命名/実装規約 |
| [navigation.md](navigation.md) | 画面一覧・ルート（go_router）・遷移・クエリパラメータ |
| [data-model.md](data-model.md) | cards.json・SQLiteスキーマ・ドメインモデル・SharedPreferencesキー |

### 画面（features/*/presentation）
| ルート | ファイル |
|---|---|
| `/` | [screens/home.md](screens/home.md) |
| `/study` | [screens/study.md](screens/study.md) |
| `/session-complete` | [screens/session-complete.md](screens/session-complete.md) |
| `/categories` | [screens/categories.md](screens/categories.md) |
| `/category/:id` | [screens/category-detail.md](screens/category-detail.md) |
| `/settings` | [screens/settings.md](screens/settings.md) |
| `/history` | [screens/history.md](screens/history.md) |
| `/search` | [screens/search.md](screens/search.md) |
| `/onboarding` | [screens/onboarding.md](screens/onboarding.md) |
| `/paywall` | [screens/paywall.md](screens/paywall.md) |

### 横断システム（core/ ・ features 横断）
| ファイル | 内容 |
|---|---|
| [systems/srs-and-study.md](systems/srs-and-study.md) | SM-2 SRS・デイリーセット・セッション進行・リポジトリ |
| [systems/gamification.md](systems/gamification.md) | XP/レベル・コンボ/FEVER・演出・SoundService |
| [systems/tts-audio.md](systems/tts-audio.md) | 発音音声（Polly事前生成＋端末TTSフォールバック） |
| [systems/monetization.md](systems/monetization.md) | ShipIt Pro（休眠中）・課金・権利検証・ゲート |
| [systems/platform-and-ui.md](systems/platform-and-ui.md) | i18n・テーマ/デザインシステム・通知・ストリーク・バックアップ |

> 過去の経緯は原則書かない（最新状態のみ）。設計判断の「なぜ」は各 spec の「注意/背景」に最小限。
> 開発ルールの原本は [CLAUDE.md](../../CLAUDE.md)、機能別の操作手順は `docs/` を参照。
