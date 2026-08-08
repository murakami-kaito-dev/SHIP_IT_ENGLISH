# Navigation — ルートと画面遷移

定義: [lib/app.dart](../../lib/app.dart)（`createRouter` / `AppShell`）。go_router 使用。
起動時 `main.dart` が `onboarding_done` を見て初期ルートを決める（未完了なら `/onboarding`）。

## ルート一覧
| ルート | 画面 | 種別 | 主なクエリ/パラメータ |
|---|---|---|---|
| `/` | Home | タブ（ShellRoute） | — |
| `/categories` | Categories | タブ | — |
| `/settings` | Settings | タブ | — |
| `/onboarding` | Onboarding | 全画面 | 初回のみ。完了で`/`へ |
| `/study` | Study | 全画面 | `category`, `mode=practice`, `from`,`to`,`statuses`(csv),`order=asc\|random` |
| `/category/:id` | CategoryDetail | 全画面 | パス`:id`=カテゴリID |
| `/session-complete` | SessionComplete | 全画面 | 直前の結果は `lastSessionResultProvider` で受渡し |
| `/paywall` | Paywall | 全画面 | 課金導線（休眠時は導線自体が出ない） |
| `/search` | Search | 全画面 | — |
| `/history` | History（学習カレンダー） | 全画面 | — |

## タブ構成（AppShell / BottomNavigationBar）
- 3タブ：ホーム / カテゴリ / 設定。タブ切替は **NoTransitionPage**（スライドアニメ無し・即時）。
- タブ画面は `AppShell` が背景グラデ（`AppBackground`）で包む → 各 Scaffold は `backgroundColor: transparent`。

## 主要な遷移
- Home「学習を始める」→ `/study`（通常デイリー）／「もう一度復習」→ `/study?mode=practice`。
- Home 🎛 / CategoryDetail「このカテゴリを学習」→ 範囲指定シート → `/study?category=…&from=…&to=…&statuses=…&order=…`。
- Home ストリーク🔥タップ → `/history`。
- Categories タブ右上🔍 → `/search`。カテゴリカード → `/category/:id`。
- Study 完了 → `context.go('/session-complete')`／SessionComplete「ホームに戻る」→ `/`。
- Settings「Proにアップグレード」→ `/paywall`。

## 全画面ルートの背景ルール（重要）
全画面遷移（study/session-complete/history/category詳細/search/paywall/onboarding）は
**`AppBackground(child: Scaffold(...))` で Scaffold ごと包む**。body だけ包むと AppBar/
ステータスバー裏・下部が黒く残る。Scaffold・AppBar は透明のまま。
