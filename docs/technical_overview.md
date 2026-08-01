# ShipIt English — 技術ドキュメント（新規参画エンジニア向け）

> このドキュメントを読めば、アプリの機能・アーキテクチャ・実装の全体像が掴めることを目的としている。
> 詳細仕様は `docs/shipit_english_spec_v4.md`、リリース手順は `docs/build_and_release.md` を参照。

最終更新: 2026-07-20

---

## 1. このアプリは何か

**ShipIt English** は、エンジニアの「現場のフレーズ」を SRS（間隔反復学習）で習得する Flutter アプリ。
**2つの学習モード**を持つ:

- **日本語モード**: 日本語話者が海外テック企業で使う技術英語を学ぶ（UIは日本語）
- **English モード**: 英語話者が日本の技術現場の日本語表現を学ぶ（UIは英語）

初回起動時のオンボーディングでモードを選択し、設定画面でいつでも切替できる。

- 完全オフライン動作（実行時のネットワーク通信なし・アカウントなし・広告なし）。iPhone専用ビルド
- コンテンツ: 1500枚のフレーズカード / 14カテゴリ（`assets/data/cards.json` が唯一の本体、version 1.5.0）
- 学習方式: SM-2 ベースの SRS。毎日「復習カード全件 + 新規カード（設定枚数、デフォルト5枚）」を出題
- 音声: 端末内蔵TTSで学習対象言語を読み上げ（jaモード=en-US / enモード=ja-JP）
- 通知: 定時リマインダー（設定変更可） + ストリーク危機通知（未学習の日だけ**23:00固定**・設定不可・ランダム文言10種）

### 画面一覧

| 画面 | ルート | 役割 |
|------|--------|------|
| Onboarding | `/onboarding` | 初回起動のみ。言語モード選択 + 使い方説明（3ページ） |
| Home | `/` | 今日のセッション情報・ストリーク・全体進捗。学習開始の起点 |
| Study | `/study`（`?category=<id>` カテゴリ限定 / `?mode=practice` もう一度復習 / `&from=<n>&to=<m>` 範囲指定） | フリップカード学習。タップでめくり、3段階評価 or 左右スワイプで評価。スピーカーで発音再生 |
| Session Complete | `/session-complete` | セッション結果。条件を満たすとアプリ内レビュー依頼 |
| Categories | `/categories` | カテゴリ一覧と進捗。上部フィルタ（カテゴリOR × 学習状況OR のAND）適用時は該当カード一覧を表示 |
| Category Detail | `/category/:id` | カテゴリ内の全カード一覧（ステータス付き）。詳細ボトムシート（3段階評価で学習状況を変更可）+「このカテゴリを学習」 |
| History | `/history` | 学習履歴カレンダー（ホームのストリークバッジから） |
| Search | `/search` | フレーズ・和訳・例文の部分一致検索（入口はカテゴリ画面の🔍） |
| Settings | `/settings` | 表示言語・新規カード枚数・通知2種・データリセット |

`/`・`/categories`・`/settings` は `ShellRoute`（BottomNavigationBar 付き、タブ切替はアニメーションなし）。
それ以外はシェル外のフルスクリーン画面。ルーターは `createRouter(showOnboarding:)` で生成され、
オンボーディング未完了時のみ `/onboarding` から始まる。

---

## 2. 技術スタック

| 項目 | 採用技術 | 備考 |
|------|---------|------|
| フレームワーク | Flutter 3.24.3 / Dart 3.5.3 | `Color.withValues()` は未対応 → `withOpacity()` を使う |
| 状態管理 | Riverpod 2.x | **手動プロバイダーのみ**。riverpod_generator は導入済みだが未使用 |
| ローカルDB | sqflite | 学習進捗・カード・統計 |
| ルーティング | go_router 14.x | ShellRoute + NoTransitionPage |
| 通知 | flutter_local_notifications + timezone | ローカル通知のみ |
| 音声 | flutter_tts | 端末内蔵音声。オフライン動作 |
| レビュー | in_app_review | ストア標準のレビューダイアログ |
| 軽量設定 | shared_preferences | ストリーク・設定値・シードバージョン・言語モード・各種フラグ |

---

## 3. ディレクトリ構成と各層の責務

```
lib/
├── main.dart          # 起動シーケンス（下記 §4）
├── app.dart           # createRouter() + AppShell(BottomNav)
├── core/              # 全featureが依存する基盤
│   ├── constants/app_constants.dart    # SRS定数・キー名・アプリバージョン等の一元管理
│   ├── database/database_helper.dart   # SQLite初期化・スキーマ・マイグレーション（現在v3）
│   ├── database/seed_data.dart         # cards.json → cardsテーブル投入（バージョン比較で差分投入）
│   ├── i18n/app_strings.dart           # LanguageMode(ja/en) + 全UI文言（ja/en両方を定義）
│   ├── providers/core_providers.dart   # databaseProvider / cardRepositoryProvider / srsEngineProvider
│   ├── providers/language_provider.dart # languageModeProvider / stringsProvider
│   ├── services/notification_service.dart  # 毎日のリマインダー通知
│   ├── services/review_service.dart        # アプリ内レビュー依頼（条件判定込み）
│   ├── services/streak_manager.dart        # 連続学習日数（2日空くとリセット）
│   ├── services/tts_service.dart           # 音声読み上げ（モードに応じ en-US / ja-JP）
│   ├── theme/app_theme.dart            # 色・タイポグラフィ・コンポーネント寸法の一元管理
│   └── utils/date_utils.dart           # 'yyyy-MM-dd' 変換等の拡張メソッド
│   ├── monetization/                   # サブスク（ShipIt Pro）。subscriptionEnabled=false で休眠中
│   │   ├── monetization_config.dart    #   マスタースイッチ / 無料枠定義 / プロダクトID
│   │   ├── entitlement_provider.dart   #   isProProvider（無効時は常にtrue=全開放）
│   │   └── purchase_service.dart       #   in_app_purchase による購入・復元
├── shared/widgets/    # feature横断の共通Widget
│   ├── card_detail_sheet.dart          # カード詳細ボトムシート+3段階評価+ステータスチップ
│   ├── card_list_tile.dart             # カード1行（番号バッジ+状況チップ。一覧系で共用）
│   ├── card_number_label.dart          # 「💬 Code Review #3」形式のラベル
│   ├── progress_bar.dart               # 角丸プログレスバー（Semantics付き）
│   └── streak_badge.dart               # 🔥ストリーク表示
└── features/          # 機能単位（feature-first構成）
    ├── home/
    ├── onboarding/    # 初回起動の言語選択+使い方説明
    ├── paywall/       # Pro購入画面（/paywall。サブスク休眠中は導線なし）
    ├── search/        # カード横断検索（/search）
    ├── study/         # 学習のコア。data / domain / presentation の3層
    ├── categories/
    └── settings/
```

> **サブスクリプションについて**: フリーミアム型の課金実装（無料=3カテゴリ+新規5枚/日、
> Pro=全解放）が完成済みだが、`MonetizationConfig.subscriptionEnabled = false` により
> 現在は完全に無効（全機能無料）。Pro判定は必ず `isProProvider` を経由すること。
> 有効化手順と App Store Connect の設定は `docs/subscription_setup_guide.md` を参照。

### 層の依存方向

```
presentation(画面/Widget) → providers(Riverpod) → data(Repository) → core/database
                                   ↘ domain(SrsEngine, models) ↙
```

- **domain**: 純粋Dart（Flutter非依存）。`SrsEngine`・モデル群。ユニットテストの主対象
- **data**: `CardRepository`（抽象）と `LocalCardRepository`（SQLite実装）。将来のクラウド同期はここを差し替える設計
- **presentation**: 画面とWidget。状態は必ずプロバイダー経由で取得

---

## 4. 起動シーケンス（main.dart）

```
1. DatabaseHelper().initialize()      … SQLite オープン・スキーマ作成
2. SeedData(dbHelper).seed()          … cards.json のversionと保存済みseed_versionを比較し、
                                        差分があればカードをupsert（学習進捗は保持）
3. StreakManager().checkAndUpdateStreak() … 前回学習日から2日以上空いていればストリークを0に
4. NotificationService                … 初期化 + 毎日リマインダーのスケジュール
5. runApp(ProviderScope(...))         … databaseProvider を初期化済みインスタンスでoverride
```

---

## 5. データベーススキーマ（SQLite / version 3）

```sql
cards (                     -- カード本体（cards.jsonのミラー）
  id TEXT PRIMARY KEY,      -- 例: 'cr_001'
  phrase, translation, example, example_translation, context TEXT,
  category TEXT,            -- 14カテゴリのID
  difficulty INTEGER,       -- 1〜3
  created_at TEXT,
  context_en TEXT,          -- v2で追加。英語話者モード用の使用場面説明（空文字ならcontextにフォールバック）
  card_number INTEGER       -- v3で追加。カテゴリ内の通し番号（シード時に1から採番）
)

learning_progress (         -- SRS状態（1カード1行、seed時に status='new' で全行作成）
  card_id TEXT PRIMARY KEY REFERENCES cards(id),
  ease_factor REAL,         -- SM-2のEF。初期2.5、下限1.3
  interval_days INTEGER,
  repetitions INTEGER,
  next_review TEXT,         -- ISO8601。これが今日以前なら復習対象
  last_reviewed TEXT,
  status TEXT,              -- 'new' | 'learning' | 'review' | 'mastered'（内部状態。UIには出さない）
  last_rating TEXT          -- v3で追加。'forgot' | 'uncertain' | 'remembered' | NULL(未学習)
                            -- 画面の学習状況表示はこちらを使う（評価ボタンと語彙を統一）
)

daily_stats (               -- 日別学習統計（同日複数セッションは加算）
  date TEXT PRIMARY KEY,    -- 'yyyy-MM-dd'
  cards_studied, cards_correct, new_cards, review_cards, study_time_seconds INTEGER
)
```

マイグレーションは `database_helper.dart` の `_onUpgrade` に追記する（現在 version 3）。

---

## 6. SRS アルゴリズム（srs_engine.dart）

SM-2 の簡略版。評価は3段階を quality に変換: 忘れた=1 / 曖昧=3 / 覚えてた=5。

- **quality < 3（忘れた）**: repetitions=0, interval=0, status=learning, next_review=今すぐ（即日再復習）
- **quality >= 3**:
  - repetitions+1。interval は 1回目=1日, 2回目=3日, 3回目以降= `round(前回interval × EF)`
  - EF更新: `EF + (0.1 - (5-q)(0.08 + (5-q)×0.02))`、下限1.3
  - interval が **21日以上で status=mastered**（`masteredThresholdDays`）

セッション内では「忘れた」カードをキュー末尾に再追加する（1カードにつき最大2回 = `maxRetriesPerSession`）。

---

## 7. 状態管理（Riverpod プロバイダーマップ）

| プロバイダー | 種別 | 役割 |
|-------------|------|------|
| `databaseProvider` | Provider（main.dartでoverride） | DatabaseHelper |
| `cardRepositoryProvider` | Provider | LocalCardRepository |
| `srsEngineProvider` | Provider | SrsEngine |
| `settingsProvider` | StateNotifierProvider | 新規カード枚数・通知設定（shared_preferences永続化） |
| `studySessionProvider` | StateNotifierProvider.autoDispose | **学習セッションの中核**。キュー・現在カード・フリップ状態・再出題カウント |
| `lastSessionResultProvider` | StateProvider | Study→SessionComplete間の結果受け渡し |
| `dailySessionInfoProvider` | FutureProvider | ホームの「今日のセッション」情報 |
| `overallProgressProvider` | FutureProvider | 全体のmastered進捗 |
| `categoriesProvider` | FutureProvider | カテゴリ一覧+進捗 |
| `categoryCardsProvider` | FutureProvider.autoDispose.family\<_, String\> | カテゴリ内カード一覧+最終評価 |
| `cardFilterProvider` / `filteredCardsProvider` | StateProvider / FutureProvider.autoDispose | カテゴリタブのフィルタ条件と結果 |
| `languageModeProvider` | StateNotifierProvider | 言語モード（ja/en）。初期値は main.dart で prefs から override |
| `stringsProvider` | Provider | 現在モードの `AppStrings`（全UI文言） |
| `weeklyStatsProvider` | FutureProvider | 直近7日の学習枚数（ホームの週間サマリー） |
| `searchResultsProvider` | FutureProvider.autoDispose.family\<_, String\> | カード検索結果（2文字未満は空） |

### 学習セッションのデータフロー

```
StudyScreen.initState
  → studySessionProvider.loadSession(maxNewCards: 設定値)
      → repo.getCardsForReview(today) + repo.getNewCards(limit)  → shuffle してキュー化
ユーザーがカードをタップ → flipCard() → isFlipped=true → 評価ボタン/スワイプ有効化
評価（rateCard）
  → SrsEngine.processReview で learning_progress 更新（即DB保存）
  → 「忘れた」ならキュー末尾に再追加（最大2回）
  → キューが空になったら phase=completed
completed → buildSessionResult()
  → ユニークカードごとの最終評価を集計（正答 = remembered/uncertain）
  → StreakManager.recordStudyCompletion() / daily_stats へ加算保存
  → lastSessionResultProvider に格納 → /session-complete へ go()
```

---

## 8. UI・デザインシステム

すべての色・文字スタイル・寸法は `core/theme/app_theme.dart` に集約されている。**直接 Color(0xFF...) を画面に書かないこと。**
UI文言も同様に `core/i18n/app_strings.dart` に集約されている。**画面に文字列リテラルを書かず、`ref.watch(stringsProvider)` から取得すること**（ja/en 両方の定義が必須）。

- カラー: Primary=`#2563EB`（青）、評価色 = 赤/アンバー/緑、背景 `#F8FAFC`
- カード: 角丸16、border `#E2E8F0`、`AppTheme.cardShadow`（控えめな影）
- 評価ボタン: 高さ52、InkWell + `HapticFeedback.lightImpact()`
- フリップ: Y軸3D回転 300ms。フリップ時 `selectionClick`、スワイプ確定時 `mediumImpact`
- 学習画面下部は高さ96固定（ヒント⇔評価ボタンを AnimatedSwitcher で切替。レイアウトジャンプ防止）

---

## 9. テスト

```bash
flutter test          # 全テスト
flutter analyze       # 静的解析（エラー0を維持すること）
```

| ファイル | 対象 |
|---------|------|
| `test/unit/srs_engine_test.dart` | SM-2の全遷移（初回正答・忘却リセット・EF下限・mastered昇格） |
| `test/unit/streak_test.dart` | 日付差分ロジック・ストリーク継続/リセット |
| `test/unit/daily_set_test.dart` | デイリーセット関連のSRS計算・定数 |

未整備: Widgetテスト（flip_card / rating_buttons / 各画面）。

---

## 10. よくある開発タスクの手順

### カードを追加する

1. `assets/data/cards.json` にカードを追記（書式は CLAUDE.md 参照）
2. **同ファイルの `"version"` を上げる**（上げないと再投入されない）
3. アプリ再起動でシードが走る。既存の学習進捗は保持される

### 画面を追加する

1. `lib/features/<feature>/presentation/` に画面を作成
2. `lib/app.dart` にルートを追加（タブ配下なら ShellRoute 内 + NoTransitionPage、フルスクリーンなら外）
3. 状態が必要なら `providers/` にプロバイダーを追加

### DBカラムを追加する

1. `database_helper.dart` の `_databaseVersion` をインクリメント
2. `_onUpgrade` に `if (oldVersion < N) { ALTER TABLE ... }` を追記
3. `_onCreate` にも新スキーマを反映（新規インストーラー用）

---

## 11. ハマりどころ（必読）

- `Color.withValues(alpha:)` は Flutter 3.24 に存在しない → `withOpacity()` を使う
- **学習進捗を書き換えたら `invalidateProgressProviders(ref)` を呼ぶ**。ホーム・カテゴリの FutureProvider はキャッシュするため、忘れると「習得済み 0/195」のような古い表示が残る
- **進捗の主指標は `studiedCount`（status != 'new'）**。`mastered` は21日間隔到達が条件のため、主指標にすると数週間0のままになる
- iOSでTTSを鳴らすには `setIosAudioCategory(playback, ...)` が必須（既定のambientカテゴリはサイレントスイッチに従い無音になる）
- `AppBar.actions` に幅不定Widget（LinearProgressIndicator等）を置くとクラッシュする（過去バグ）
- cards.json の `version` を上げ忘れるとカードが投入されない
- `AppConstants.appVersion` は `pubspec.yaml` の version と**手動同期**（設定画面のフッターに表示される）
- タブ画面の遷移は `NoTransitionPage` 必須（デフォルトだとスライドアニメーションが入る）
- UI文言を追加するときは `AppStrings` の ja / en **両方**に定義する（required なので片方忘れはコンパイルエラー）
- `context_en` を再生成する場合、Gemini のモデル名は `gemini-2.5-flash` を使う（`gemini-2.0-flash` は 404）
- Bundle ID はまだ `com.example.shipItEnglish`。**リリース前に必ず変更**（`docs/app_store_connect_submission.md` STEP 0）
