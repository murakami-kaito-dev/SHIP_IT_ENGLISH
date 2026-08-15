# ShipIt English — CLAUDE.md

Claude Code がこのプロジェクトを触る際に必ず参照するコンテキスト。

## 情報のありか（新規セッションの初動でまず把握する地図）

このプロジェクトの全体像は下記を辿れば掴める（＝新規参画時に見る順番）:
- **このファイル `CLAUDE.md`** … 固有ルール・不変条件・禁忌・コーディング規約
- **仕様（正）** [.claude/spec/README.md](.claude/spec/README.md) … 画面別・システム別の最新仕様（**コードを読む前にここ**。仕様駆動開発）
- **リリース履歴** [.claude/docs/release-log.md](.claude/docs/release-log.md) … どのビルドで何を出したか・配信状態
- **ドキュメント索引** [docs/README.md](docs/README.md) … ビルド/申請/音声生成 等の人間向け操作手順
- **`.claude/rules/`** … パス限定で常時効くルール（例 [.claude/rules/flutter-conventions.md](.claude/rules/flutter-conventions.md)＝`lib/**/*.dart` の Flutter 規約）／**プロジェクト Skill** [.claude/skills/ios-app-release-local](.claude/skills/ios-app-release-local/SKILL.md)（このアプリの App Store 固有値。手順はグローバル `ios-app-release`）
- **自動メモリ** `~/.claude/projects/<repo>/memory/`（索引 `MEMORY.md`）… これまでの経緯・決定・学び
- **共通ルール（Git・秘密・タグ・記録・越境禁止）は グローバル [`~/.claude/CLAUDE.md`](~/.claude/CLAUDE.md) と各 Skill** を参照（`git-workflow` / `ios-app-release` / `release-log` / `project-hygiene`）

---

## プロジェクト概要

- **アプリ名**: ShipIt English
- **目的**: 海外テック企業で働くための技術英語を、毎日5〜10分のSRS学習で習得するFlutterアプリ
- **仕様（正）**: `.claude/spec/`（画面別・システム別の最新仕様。索引は `.claude/spec/README.md`）。`docs/shipit_english_spec_v4.md` は初期の詳細要件（参考・履歴）
- **現フェーズ**: Phase 1 MVP 完成済み・実機動作確認済み・App Store申請準備中

### 関連ドキュメント

> **画面・システムの仕様は `.claude/spec/` が「正」**（仕様駆動開発）。コードを読む前に
> まず該当 spec を1〜2ファイル読む。**実装を変えたら対応する spec を必ず更新する**。
> 索引は `.claude/spec/README.md`。`docs/` は人間向けの操作手順（下記）。

| ドキュメント | 用途 |
|-------------|------|
| `.claude/spec/` | **画面別・システム別の仕様（コードを読む前にここ）** |
| `.claude/docs/release-log.md` | **リリース履歴（正）。バージョン/ビルド番号を上げたら必ずその場で追記する**（「ビルドしただけ」と「配信した」は git から判別できない） |
| `docs/app_store_connect_submission.md` | App Store Connect 申請の全手順・全入力値 |
| `docs/subscription_setup_guide.md` | サブスク（ShipIt Pro）の有効化手順・App Store Connect操作・Sandboxテスト |
| `docs/backup_and_restore.md` | 学習データのバックアップ/復元の仕様と操作手順 |
| `docs/feature_recommendations.md` | 追加機能の優先度リスト |
| `docs/build_and_release.md` | ビルド・署名・ストア申請の操作手順 |
| `docs/app_store_free_release_checklist.md` | 課金なし配布の対応済み項目＋開発者の手作業チェックリスト |
| `docs/tts_audio_generation.md` | 発音音声（Amazon Polly）の生成手順・AWSセットアップ・差分生成コマンド |

---

## 技術スタック

| 項目 | 内容 |
|------|------|
| Flutter | 3.24.3 / Dart 3.5.3 |
| 状態管理 | Riverpod（StateNotifier / FutureProvider / autoDispose） |
| ローカルDB | SQLite（sqflite） |
| ルーティング | go_router（ShellRoute + NoTransitionPage） |
| 通知 | flutter_local_notifications + timezone |
| 設定 | shared_preferences |

---

## ディレクトリ構成

```
lib/
├── app.dart                        # GoRouter + AppShell + BottomNavigationBar
├── main.dart                       # 起動・初期化フロー
├── core/
│   ├── constants/app_constants.dart
│   ├── database/database_helper.dart   # SQLite初期化・マイグレーション
│   ├── database/seed_data.dart         # JSONからカード投入（バージョン管理付き）
│   ├── providers/core_providers.dart   # databaseProvider / cardRepositoryProvider / srsEngineProvider
│   ├── services/notification_service.dart
│   ├── services/streak_manager.dart
│   ├── theme/app_theme.dart
│   └── utils/date_utils.dart
└── features/
    ├── home/
    │   ├── presentation/home_screen.dart
    │   └── providers/home_providers.dart
    ├── study/
    │   ├── data/card_repository.dart           # 抽象クラス
    │   ├── data/local_card_repository.dart     # SQLite実装
    │   ├── domain/models/card_model.dart
    │   ├── domain/models/learning_progress.dart
    │   ├── domain/models/study_session.dart
    │   ├── domain/srs_engine.dart              # SM-2アルゴリズム
    │   ├── presentation/study_screen.dart
    │   ├── presentation/session_complete_screen.dart
    │   ├── presentation/widgets/flip_card.dart
    │   ├── presentation/widgets/rating_buttons.dart
    │   ├── presentation/widgets/swipe_card_wrapper.dart
    │   └── providers/study_providers.dart      # StudySessionNotifier / lastSessionResultProvider
    ├── categories/
    │   ├── presentation/categories_screen.dart
    │   ├── presentation/category_detail_screen.dart   # カテゴリ内カード一覧+詳細シート（/category/:id）
    │   └── providers/categories_providers.dart        # categoriesProvider / categoryCardsProvider / categoryDefs
    └── settings/
        ├── presentation/settings_screen.dart
        └── providers/settings_providers.dart
assets/
└── data/cards.json    # 単語カードの本体（135枚 / 7カテゴリ）
docs/
├── shipit_english_spec_v4.md   # 実装仕様書
└── build_and_release.md        # ビルド・App Store申請手順書
test/
└── unit/
    ├── srs_engine_test.dart
    ├── streak_test.dart
    └── daily_set_test.dart
```

---

## 単語カードの追加方法

単語カードの**唯一の本体**は `assets/data/cards.json`。

### カードの書式

```json
{
  "id": "cr_026",
  "phrase": "Let's take this offline",
  "translation": "この話は別途話しましょう",
  "example": "That's a good point, but let's take this offline so we don't block the rest of the team.",
  "example_translation": "良い指摘だけど、チームの議論を止めないよう別途話しましょう。",
  "context": "会議中に脱線しそうな話題を後回しにする際に使う定番フレーズ。",
  "context_en": "A standard phrase for deferring a topic that risks derailing a meeting.",
  "category": "meetings",
  "difficulty": 1
}
```

> `context_en` は英語話者モード用。省略すると空文字になり `context`（日本語）にフォールバックする。
> まとめて生成する場合は Gemini API（`dart_defines.json` の GEMINI_API_KEY / モデルは gemini-2.5-flash）で一括翻訳する。

### カテゴリID一覧（計1500枚 / 14カテゴリ・cards.json v1.5.0）

| ID | カテゴリ | 枚数 | 無料/Pro(※) |
|----|---------|------|------------|
| `code_review` | Code Review | 130枚 | 無料 |
| `meetings` | Meetings | 110枚 | 無料 |
| `slack` | Slack | 110枚 | 無料 |
| `git_cicd` | Git & CI/CD | 110枚 | Pro |
| `architecture` | Architecture | 110枚 | Pro |
| `incident` | Incident Response | 105枚 | Pro |
| `interview` | Tech Interview | 105枚 | Pro |
| `planning` | Sprint Planning | 105枚 | Pro |
| `career` | 1on1 / Career | 105枚 | Pro |
| `remote_work` | Remote / Async | 105枚 | Pro |
| `documentation` | Docs / Writing | 105枚 | Pro |
| `tech_debt` | Refactoring & Tech Debt | 100枚 | Pro |
| `qa_testing` | QA & Testing | 100枚 | Pro |
| `security` | Security & Compliance | 100枚 | Pro |

※ 無料/Pro の区分はサブスク有効化後のみ意味を持つ（現在は全カテゴリ開放）。区分の変更は `MonetizationConfig.freeCategoryIds`。
カテゴリを追加したら `categories_providers.dart` の `categoryDefs` にも追加すること。

### カードを追加したあとの手順

1. `cards.json` の `"version"` を**必ず**変更する（例: `"1.5.0"` → `"1.6.0"`）
2. カテゴリを追加した場合は `categories_providers.dart` の `categoryDefs` にも追加する（**忘れるとカテゴリタブに表示されない**）
3. アプリを再起動するとシードが自動で取り込まれる
4. 既存の学習進捗（SRS状態）は保持される

> ⚠️ **バージョンを上げ忘れると、カードを増やしてもDBに反映されない**（過去に790枚のまま止まっていた実績あり）。
> 反映確認は `sqlite3 <db> "SELECT COUNT(*) FROM cards;"` が早い。

---

## 実装済み済み機能（Phase 1 MVP）

- [x] SM-2 ベース SRS アルゴリズム
- [x] フリップカード（Y軸3Dアニメーション 300ms）
- [x] スワイプ操作（左=忘れた / 右=覚えてた、閾値30%）
- [x] 評価ボタン（忘れた / 曖昧 / 覚えてた）
- [x] 「忘れた」カードの再出題（上限2回）
- [x] デイリーセッション（復習カード全件 + 新規カード上限設定枚数）
- [x] ストリーク管理（2日以上空いたらリセット）
- [x] ローカル通知（毎日08:00、設定変更可）
- [x] 学習データリセット機能
- [x] BottomNavigationBar のタブ切り替え（アニメーションなし即時切替）
- [x] ユニットテスト（SRS全ケース・ストリーク・デイリーセット）
- [x] カテゴリ詳細画面（カード一覧+ステータスチップ+詳細ボトムシート）
- [x] UIUX改善（ハプティクス・カードシャドウ・学習画面レイアウト安定化・設定セクション化）
- [x] 2言語モード（日本語話者=技術英語を学ぶ / 英語話者=技術日本語を学ぶ）+ 全UIローカライズ
- [x] オンボーディング（初回起動時の言語モード選択+使い方説明）
- [x] TTS音声読み上げ（flutter_tts・端末内蔵音声・オフライン）
- [x] カテゴリ別学習セッション（`/study?category=<id>`）
- [x] アプリ内レビュー依頼（in_app_review・ストリーク3日以上で一度だけ）
- [x] サブスクリプション「ShipIt Pro」一式（**休眠状態**。`MonetizationConfig.subscriptionEnabled = false`。有効化は `docs/subscription_setup_guide.md` 参照）
  - 課金・パウォール・ゲートに加え、**失効判定**（解約/返金を起動・復帰時に検出してPro解除）・**管理/解約導線**・**設定からの復元**まで実装済み
- [x] 学習データのバックアップ/復元（JSON書き出し・読み込み。`docs/backup_and_restore.md`）
- [x] ストリーク危機通知（未学習の日だけ23:00固定・時刻は設定不可・メッセージ10種ランダム）
- [x] 通知設定の分離とOS許可ゲート（設定画面の通知トグルを「毎日のリマインダー」「ストリークが途切れそうな日」の2本に分離。OS通知オフ時は警告バナー＋「設定を開く」導線を出しトグルを非活性化）
- [x] 時刻選択をホイール式に変更（`showWheelTimePicker`。時・分の2連ホイール。Materialのアナログ文字盤を廃止）＋「通知時刻」をリマインダートグルの子として開閉表示（オフで畳む）
- [x] 週間学習サマリー（ホームに直近7日の棒グラフ）
- [x] 学習履歴カレンダー（ホームのストリークバッジ🔥をタップ→`/history`。月送り・学習日をマーク・今月/累計の学習日数）
- [x] カード検索（`/search`。フレーズ・和訳・例文の部分一致）
- [x] 学習セッションの途中終了（戻る/システムバックでその時点まで記録＝ストリーク・統計に反映）
- [x] カテゴリ学習の設定シート（学習状況フィルタ〈未学習/忘れた/曖昧/覚えてた・複数可〉＋番号範囲＋出題順〈番号順/ランダム〉。枚数指定なし＝一致する全カード。Homeの🎛アイコン／カテゴリ詳細の「このカテゴリを学習」から。`/study?category=<id>&from=<n>&to=<m>&statuses=<csv>&order=<asc|random>`）
- [x] 新規カード数の設定はホームの「今日のセッション」内に配置（設定タブからは移動）。**上限はカード総数（≈1500）**。スライダーをやめ「− 直接入力 ＋」ステッパー＋プリセット（5/10/25/50/100/最大）に変更（`_NewCardsStepper` / `_NewCardsPresets`。上限は `overallProgressProvider.totalCount` で動的取得）
- [x] iPhone専用化（`TARGETED_DEVICE_FAMILY = 1`。iPadスクリーンショット不要に）
- [x] ゲーミフィケーション演出一式（`features/gamification/`。SKILL: gamification-us / animation-effects 準拠）
  - **コンボ＆FEVER**: 連続で1回正解するとコンボ加算→`ComboOverlay`が elasticOut で弾む＋ネオングロー。5コンボで`FeverFrame`（画面枠パルス発光）＋獲得XP1.5倍
  - **XP＆レベル**: 評価ごとにXP獲得（`XpGainPopup`が浮上）→`XPProgressBar`が easeOutQuart で滑らかに増加。レベルアップで`showLevelUpModal`（elasticOutで拡大バウンド＋`ConfettiCelebration`紙吹雪）
  - **デイリーストリーク**: `StreakWidget`（🔥が breathing パルス。今日の目標`dailyGoalCards`達成で強発光＋チェック）をホーム＆完了画面に配置
  - **正解演出**: `SparkleBurst`（CustomPainterの軽量パーティクル）。不正解は`_KeepGoingChip`「どんまい！」でポジティブ誘導（負の感情の軽減）
  - **触覚/音**: `SoundService`（`core/services/`）が tap/correct/combo/fever/levelUp/celebrate/retry のフックを提供（現状ハプティクス＋SystemSound。実SFXは`_sfx()`差し替えで対応）
  - **タップ物理**: `GradientButton`は押下で scale(0.95)→離すと elasticOut で弾む（`PressScale`も再利用部品として提供）
  - パッケージは`confetti`のみ追加（純Dart・オフライン・軽量）。他はFlutter組み込み（AnimationController/CustomPainter/HapticFeedback/SystemSound）で実装
- [x] 今日のセッションの新規表示を「残りX / 上限Y枚」に変更（1日の上限が同じ画面で分かる）＋今日学習した新規枚数の補足キャプション。ヘルプ「?」ボタンで各要素の意味を説明するボトムシート（`_showSessionHelp` / `AppStrings.sessionHelpEntries()`）
- [x] 学習カレンダーの拡張: 日付タップでその日の学習枚数を表示（`_SelectedDayDetail`）＋今月/累計の「学習枚数」も表示（従来の学習日数に加えて。`studyDaysProvider` は日付→枚数のMapなのでリポジトリ変更不要）
- [x] 評価ボタンに次回復習間隔を表示（「忘れた 10分」「覚えてた 1日」等）。カードをめくった時に現在のSRS状態を読み込み（`StudySessionState.currentProgress`）、`SrsEngine.projectedInterval()` で各評価の次回間隔を予測して表示。表示＝実挙動を保証（内部で `processReview` を呼ぶ副作用なし予測）。「忘れた」は当日中の短い再学習ステップ（`AppConstants.relearnStepMinutes = 10`分後）＝エビングハウスの忘却曲線基準。文言整形は `AppStrings.nextReviewIn(Duration)`（分/時間/日/週間/か月）

---

## 既知のバグ修正履歴

| 症状 | 原因 | 修正 |
|------|------|------|
| Start Learning押下でクラッシュ (`BoxConstraints forces an infinite width`) | AppBarの`actions`内に`LinearProgressIndicator`を置いていた | `actions`から削除。`body`側の進捗バーのみ残した |
| タブ切り替えで右から左スライドアニメーションが発生 | go_routerのデフォルト遷移がiOSスタイルのスライド | ShellRoute内のルートを`pageBuilder` + `NoTransitionPage`に変更 |
| 実機でスピーカーを押しても音が鳴らない | iOSのオーディオセッション未設定。既定の ambient カテゴリはサイレントスイッチに従うため消音状態で無音になる | `TtsService`で`setSharedInstance(true)` + `setIosAudioCategory(playback, [defaultToSpeaker, mixWithOthers])` を初回に実行 |
| 学習しても「習得済み 0/195」のまま | ①FutureProviderのキャッシュがセッション後に更新されない ②`mastered`は21日間隔到達が条件のため数週間反映されない | ①`invalidateProgressProviders()`をセッション完了・途中離脱・カード評価時に呼ぶ ②進捗バーと数値を`studiedCount`（status != 'new'）ベースに変更し、mastered は補助表示に |
| 「もう一度復習する」で「復習するカードはありません」 | ①上記キャッシュ ②「曖昧」評価でも`next_review`が翌日になり当日は対象0件 | `getPracticeCards()`を追加し、`/study?mode=practice`で**その日に学習したカード**を苦手順に出題（過去日の学習分は含めない） |
| 週間サマリーの曜日が火曜始まりだった | 直近7日のローリング表示だった | 暦の週（日曜始まり・土曜終わり）に変更 |
| 通知が設定時刻と全く違う時間に鳴る | `tz.initializeTimeZones()` だけで `tz.local` がUTCのまま。zonedScheduleがUTC基準で組まれJST(+9h)とずれる | `initialize()` で **`flutter_timezone` の `getLocalTimezone()` から端末の IANA タイムゾーンを取得**し `tz.setLocalLocation` に設定（端末ローカル時刻で通知＝どの国でもその端末の時刻に同期。取得失敗時のみ `Asia/Tokyo` フォールバック）。以前は `Asia/Tokyo` 固定だったが海外端末で誤時刻になるため端末TZ検出に変更 |
| XPゲージがどれだけXPを得ても空のまま | `_Bar` の `FractionallySizedBox` に `widthFactor` しか指定しておらず、高さ制約が緩いまま子を持たない `DecoratedBox` に渡り、塗りが**高さ0**に潰れていた（幅は正しく計算されていた） | `heightFactor: 1.0` を追加。`test/unit/xp_progress_bar_test.dart` で「塗りの高さ > 0」を恒久ガード |
| 学習画面の上下2本のバーが何を表すか分からない | 同形の横棒が6px間隔で並び、下のバーは AppBar の `9 / 15` と情報が完全重複。単位・ラベルも無し | セッション進捗を **AppBar直下の全幅4pxヘアライン**に変更（線）、XPは**カード上の部品**に変更（面）。数字に単位（枚 / XP）と「のこり◯枚」「あと◯XPでLV◯」を追加 |
| 裏面をスワイプしかけて戻すと表面に戻る | `SwipeCardWrapper` の Stack 先頭にスワイプ中だけ出るフィードバック背景があり、ドラッグ開始でカードのindexが0→1にずれてFlipCardのStateが破棄・再生成され、フリップが表面(controller=0)にリセットされる | Stack children に `ValueKey` を付与し、条件付きの子が出入りしてもFlipCardのStateを保持 |
| 学習が設定枚数で終わらず最初に戻る | ①`StudySessionState.copyWith` の `currentCard: currentCard ?? this.currentCard` で完了時に `null` を渡しても無視され、最後のカードが残り再表示 ②完了処理の副作用が実機で失敗すると `context.go` 前で止まる | ①copyWithをセンチネル方式にして `null` 設定を可能に ②`_completeSession` を try/catchで囲み副作用が失敗しても必ず遷移、`_completing` で二重起動防止。`test/unit/study_session_test.dart` で完了ロジックを恒久ガード |
| カード詳細で評価しても一覧の表示が変わらない | 一覧プロバイダーを再取得していなかった | `invalidateProgressProviders()` が**カード一覧系のfamilyプロバイダーも無効化**するようにした（引数なしinvalidateで全インスタンスが対象）。シートを開いたまま裏の一覧が更新される |
| 途中でやめて再開すると新規カウントが 0/40 に戻る（減らない） | `getNewCards(limit)` は毎回上限まで新規を補充する。学習済みは status!='new' なので除外されるだけで、残り枠の概念が無かった | 「その日の残り新規枠 = 1日の上限 − 今日学習した新規（`daily_stats.new_cards`）」を `getNewCardsStudiedToday()` で算出し、`loadSession` と `dailySessionInfoProvider` の両方で適用。3枚やって再開すると 0/37 になる（＝1日の新規枠を消化する挙動） |
| フルスクリーン画面の周囲が黒くなる | 背景グラデを body だけに敷いていたため AppBar・ステータスバー裏やコンテンツ下部が黒く残った | `AppBackground(child: Scaffold(...))` で Scaffold ごと包む形に変更（AppShell と同じ方式） |
| ホームで新規枚数を±変更すると画面全体がちらつく | `dailySessionInfoProvider`（設定依存）の再計算中にローディング表示へ落ちていた | `sessionInfo.when(skipLoadingOnReload: true, ...)` で再取得中も前回値を表示 |

---

## コーディング上の注意事項

> **`lib/**/*.dart` のコード規約は [.claude/rules/flutter-conventions.md](.claude/rules/flutter-conventions.md) に移設した**
> （`lib/**/*.dart` 編集時にパス限定で常時適用）。移設分＝`withOpacity`／手動プロバイダー／`FractionallySizedBox` の
> `heightFactor`／`invalidateProgressProviders`／`Rating` vs `CardStatus`／`SrsEngine.projectedInterval`／通知トグルの整合／
> 課金（Pro・エンタイトルメント）／ゲーミフィケーション／Now Playing／ちらつき対策 等。
> ここには**カード追加・音声生成・リリース同期などのプロセス/データ運用の手順系**だけを残す。
> 秘密ファイルの扱いは上の「Git / 秘密（運用ルール）」節を参照。

- **カードのseed投入**: `seed_data.dart` が `seed_version` と JSON の `version` を比較して差分のみ投入する。バージョンを上げないと再投入されない。**JSONから削除したカードはDBからも自動削除される**（cards.jsonが唯一の正）
- **`AppConstants.appVersion` は `pubspec.yaml` の version と手動同期**（設定画面フッターに表示）
- **カード番号はカテゴリごとの通し番号**（`cards.card_number`）。シード時に cards.json の並び順で1から採番するため、**カードの順序を入れ替えると番号が変わる**（追加は末尾に）
- **カードに新フィールドを足すとき**: cards.json + `card_model.dart` + `seed_data.dart` + `database_helper.dart`（DBバージョン++とマイグレーション）の4点セット。翻訳が必要なら `dart_defines.json` の GEMINI_API_KEY で開発時に一括生成（実行時API呼び出しはしない）
- **発音音声は「開発時に OpenAI TTS(nova) で一括生成→同梱、実行時は再生のみ（非通信）」・英語/日本語の2ロケール**。`speakTarget` は対象ロケール（ja→en-US / en→ja-JP）で同梱クリップがあれば `AudioClipService.playIfAvailable(text, locale)` で再生、無ければ `flutter_tts` にフォールバック。生成は `dart run tools/generate_tts.dart --locale <en-US|ja-JP> --generate`（差分生成・要 `OPENAI_API_KEY`）。OpenAIからWAV取得→`afconvert`でAAC(.m4a)化。ファイル名は `sha1(trimしたテキスト)`.m4a。en-US=3826件/約124MB・ja-JP=3822件/約158MB 同梱済み。カード追加時は両ロケール差分生成してコミット（手順は `docs/tts_audio_generation.md`）
- **バックアップのフォーマットを変えたら `BackupService._formatVersion` を上げる**（上げないと古いアプリが新しいファイルを中途半端に読み込む）
- **`file_picker` を使うので `NSPhotoLibraryUsageDescription` が必須**（`ios/Runner/Info.plist`）。写真は実際には使わないが、file_pickerが写真ライブラリAPIを参照するため用途文字列が無いと **ITMS-90683 でアップロードが弾かれる**（実機に届く前の自動処理で失敗しメール通知）。写真は収集しない旨を文字列に明記済み。**data収集なし申告とは矛盾しない**（用途文字列＝端末機能の許可であり、App Privacyのデータ収集宣言とは別物）。
- **実行時のネットワーク通信を伴う機能の追加は要確認**（App Storeの「データ収集なし」申告が崩れるため）

---

## デザインシステム（"Terminal-grade" — 開発者ツール風）

「平面的で奥行きがない」を解消するために全画面を刷新した。**色・影・角丸・テキストスタイルはすべて `core/theme/app_theme.dart`（`AppTheme`）に集約**されており、各画面は `AppTheme.*` を参照するだけ。ここを変えれば全画面に波及する。

- **カラー**: インディゴ基調（`primary = #5B54E6`）。CTA は `primaryGradient`、背景は `backgroundGradient`（上から下へ僅かに沈む）
- **奥行き**: `cardShadow`（インク色2層）/ `heroShadow`（学習カード用の強い primary 影）/ `buttonShadow`（primary グロー）。カードは `AppTheme.cardDecoration` を使う
- **モノスペース識別子**: 数値・進捗率・タグは iOS 内蔵の等幅フォント `AppTheme.monoFont`（Menlo）。`monoNumber` / `monoNumberLarge` / `monoLabel` を使う。**`google_fonts` は使わない**（実行時ネットワーク取得になり「データ収集なし」申告と衝突する）
- **共通部品**:
  - `shared/widgets/gradient_button.dart` … 主要CTA（グラデ＋影＋ハプティクス）。ElevatedButton の代わりにこれを使う
  - `shared/widgets/app_background.dart` … 背景グラデーション。**タブ画面は AppShell が包む**ので Scaffold を `backgroundColor: Colors.transparent` にするだけ。**フルスクリーン遷移（study / session-complete / history / category詳細 / search / paywall / onboarding）は `AppBackground(child: Scaffold(...))` の形で Scaffold 全体を包む**（body だけを包むと AppBar・ステータスバー裏やコンテンツ下部が黒く残る＝グラデが画面全体に届かない。必ず Scaffold ごと包み、Scaffold と AppBar は透明のまま）
- **影のクリッピングに注意**: `borderRadius` を持つ `Material` は子をクリップするため、内側の `boxShadow` が消える。`DecoratedBox(cardDecoration) > Material(transparent, clipBehavior: antiAlias) > InkWell > Padding` の順で組む（`card_list_tile.dart` 参照）
- **アイコンは `_rounded` 系で統一**（home_rounded, play_arrow_rounded など）

---

## アプリアイコン

マスター画像は `assets/icon/app_icon.png`（2048×2048）。差し替えたら以下で再生成する:

```bash
dart run flutter_launcher_icons
```

iOS/Android の全サイズが生成される（iOSはアルファ除去＝審査対応）。設定は `pubspec.yaml` の `flutter_launcher_icons:` セクション。

---

## Git / 秘密（運用ルール）

- **Git 運用は個人共通ルール（[`~/.claude/CLAUDE.md`](~/.claude/CLAUDE.md)）と `git-workflow` スキルに従う。**
  （要点：ソロ開発なので通常は `main` 直コミット可／commit・push は**指示されたときだけ**／コミットは小さく明確に、末尾に
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`／秘密はコミット禁止・`git commit` 前にグローバルフックでも機械ブロック／
  **ストア申請したら提出コミットに `vX.Y.Z` タグ**／**バージョン/ビルド番号を変えた・配信したら `.claude/docs/release-log.md` に記録**。）
- **このプロジェクト固有の秘密ファイル**（絶対にコミット/共有・中身を読まない。`.gitignore` 済み）:
  - `dart_defines.json`（`GEMINI_API_KEY` / `OPENAI_API_KEY`）
  - `ios/AuthKey_*.p8`（App Store Connect API キー）／ `ios/AppStoreConnectKeyIdIssuerId.json`（Issuer/Key ID）

---

## ビルド・申請

詳細は `docs/build_and_release.md` を参照。

- **iOS実機**: `flutter run --release`
- **App Store**: `flutter build ipa` → Xcode でアップロード
- **Android**: `flutter build appbundle`
- **リリース前**: Bundle IDを `com.example.*` から変更すること

---

## Phase 2 以降の予定（着手しない）

- AI解説機能（カード裏面「もっと詳しく」）
- クラウド同期
- シーン別ロールプレイ（Slack・面接）
- ダークモード
- 学習分析ダッシュボード
