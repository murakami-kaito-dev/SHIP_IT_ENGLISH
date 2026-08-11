# ShipIt English — CLAUDE.md

Claude Code がこのプロジェクトを触る際に必ず参照するコンテキスト。

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
- [x] ストリーク危機通知（未学習の日だけ23:00固定・設定不可・メッセージ10種ランダム）
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
| 裏面をスワイプしかけて戻すと表面に戻る | `SwipeCardWrapper` の Stack 先頭にスワイプ中だけ出るフィードバック背景があり、ドラッグ開始でカードのindexが0→1にずれてFlipCardのStateが破棄・再生成され、フリップが表面(controller=0)にリセットされる | Stack children に `ValueKey` を付与し、条件付きの子が出入りしてもFlipCardのStateを保持 |
| 学習が設定枚数で終わらず最初に戻る | ①`StudySessionState.copyWith` の `currentCard: currentCard ?? this.currentCard` で完了時に `null` を渡しても無視され、最後のカードが残り再表示 ②完了処理の副作用が実機で失敗すると `context.go` 前で止まる | ①copyWithをセンチネル方式にして `null` 設定を可能に ②`_completeSession` を try/catchで囲み副作用が失敗しても必ず遷移、`_completing` で二重起動防止。`test/unit/study_session_test.dart` で完了ロジックを恒久ガード |
| カード詳細で評価しても一覧の表示が変わらない | 一覧プロバイダーを再取得していなかった | `invalidateProgressProviders()` が**カード一覧系のfamilyプロバイダーも無効化**するようにした（引数なしinvalidateで全インスタンスが対象）。シートを開いたまま裏の一覧が更新される |
| 途中でやめて再開すると新規カウントが 0/40 に戻る（減らない） | `getNewCards(limit)` は毎回上限まで新規を補充する。学習済みは status!='new' なので除外されるだけで、残り枠の概念が無かった | 「その日の残り新規枠 = 1日の上限 − 今日学習した新規（`daily_stats.new_cards`）」を `getNewCardsStudiedToday()` で算出し、`loadSession` と `dailySessionInfoProvider` の両方で適用。3枚やって再開すると 0/37 になる（＝1日の新規枠を消化する挙動） |
| フルスクリーン画面の周囲が黒くなる | 背景グラデを body だけに敷いていたため AppBar・ステータスバー裏やコンテンツ下部が黒く残った | `AppBackground(child: Scaffold(...))` で Scaffold ごと包む形に変更（AppShell と同じ方式） |
| ホームで新規枚数を±変更すると画面全体がちらつく | `dailySessionInfoProvider`（設定依存）の再計算中にローディング表示へ落ちていた | `sessionInfo.when(skipLoadingOnReload: true, ...)` で再取得中も前回値を表示 |

---

## コーディング上の注意事項

- **`Color.withValues(alpha:)` は使わない** → Flutter 3.24では未定義。`withOpacity()` を使う
- **`riverpod_generator` / `build_runner` は導入済みだがコード生成は使っていない**（手動プロバイダーで統一）
- **`AppBar.actions` に幅が不定のWidgetを置かない**（LinearProgressIndicator など）
- **カードのseed投入**: `seed_data.dart` が `seed_version` と JSON の `version` を比較して差分のみ投入する。バージョンを上げないと再投入されない。**JSONから削除したカードはDBからも自動削除される**（cards.jsonが唯一の正）
- **`AppConstants.appVersion` は `pubspec.yaml` の version と手動同期**（設定画面フッターに表示）
- **実行時のネットワーク通信を伴う機能の追加は要確認**（App Storeの「データ収集なし」申告が崩れるため）
- **UI文言はハードコード禁止**: `core/i18n/app_strings.dart` に ja/en 両方を定義し、`stringsProvider` 経由で取得する
- **Pro判定は `isProProvider` 経由のみ**（サブスク無効時は常にtrue）。無料/Proの線引きは `MonetizationConfig` だけで変更する
- **権利は `setPro(true)` して終わりにしない**。解約・返金を反映するため `EntitlementNotifier.verify()` が起動時／フォアグラウンド復帰時に再検証する（間隔・猶予期間は `MonetizationConfig`）
- **バックアップのフォーマットを変えたら `BackupService._formatVersion` を上げる**（上げないと古いアプリが新しいファイルを中途半端に読み込む）
- **学習進捗を変更したら `invalidateProgressProviders(ref)` を呼ぶ**（`core/providers/progress_refresh.dart`）。ホーム・カテゴリのFutureProviderはキャッシュするため、これを忘れると古い集計が表示される
- **カードの学習状況の表示は `Rating`（忘れた/曖昧/覚えてた、未評価はnull=未学習）で統一**。`CardStatus`（new/learning/review/mastered）はSRS内部状態であり画面には出さない
- **「忘れた」の次回復習は当日中の短い再学習ステップ**（`relearnStepMinutes = 10`分後）。以前は `next_review = now`（即時）だったが、エビングハウス基準で数十分後に変更。ただし `intervalDays` は 0 のまま（＝graduated扱いしない）。セッション内の即時再出題は `retryCount` 側で別管理なので影響なし
- **評価ボタンの次回間隔は必ず `SrsEngine.projectedInterval()` を使う**（表示と実際の `processReview` 結果が一致する。独自計算で二重管理しない）
- **カード番号はカテゴリごとの通し番号**（`cards.card_number`）。シード時に cards.json の並び順で1から採番するため、**カードの順序を入れ替えると番号が変わる**（追加は末尾に）
- **進捗表示は `studiedCount`（status != 'new'）を使う**。`mastered` は21日間隔到達が条件で数週間かかるため、これを主指標にすると「学習しても0のまま」になる
- **カードに新フィールドを足すとき**: cards.json + `card_model.dart` + `seed_data.dart` + `database_helper.dart`（DBバージョン++とマイグレーション）の4点セット。翻訳が必要なら `dart_defines.json` の GEMINI_API_KEY で開発時に一括生成（実行時API呼び出しはしない）
- **発音音声は「開発時に OpenAI TTS(nova) で一括生成→同梱、実行時は再生のみ（非通信）」・英語/日本語の2ロケール**。`speakTarget` は対象ロケール（ja→en-US / en→ja-JP）で同梱クリップがあれば `AudioClipService.playIfAvailable(text, locale)` で再生、無ければ `flutter_tts` にフォールバック。生成は `dart run tools/generate_tts.dart --locale <en-US|ja-JP> --generate`（差分生成・要 `OPENAI_API_KEY`）。OpenAIからWAV取得→`afconvert`でAAC(.m4a)化。ファイル名は `sha1(trimしたテキスト)`.m4a。en-US=3826件/約124MB・ja-JP=3822件/約158MB 同梱済み。カード追加時は両ロケール差分生成してコミット（手順は `docs/tts_audio_generation.md`）
- **ゲーミフィケーションのXP/コンボ判定は `gamificationProvider` に集約**。study_screen は `registerAnswer(rating, firstTry)` を呼んで返る `AnswerOutcome`（combo/xpGained/fever/leveledUp）でエフェクトを発火するだけ。XP量・コンボ閾値・FEVER倍率・デイリー目標は `GamificationConfig` の定数のみで調整する
- **XP総量だけを永続化**（`keyTotalXp`）。レベルとレベル内進捗は `GamificationSnapshot.fromTotalXp()` で都度算出（別々に保存しない）。コンボ・セッションXPはセッション内の一時状態で永続化しない（`startSession()` でリセット）
- **効果音/振動は必ず `SoundService` 経由**（直接 HapticFeedback を撒かない）。実SFXを足すときは `_sfx()` をローカルアセット再生に差し替える（ネットワーク非通信・データ収集なしの方針を維持）
- **`dart_defines.json` は秘密（GEMINI_API_KEY）を含むため `.gitignore` 済み**。コミット/Pushに含めない
- **`file_picker` を使うので `NSPhotoLibraryUsageDescription` が必須**（`ios/Runner/Info.plist`）。写真は実際には使わないが、file_pickerが写真ライブラリAPIを参照するため用途文字列が無いと **ITMS-90683 でアップロードが弾かれる**（実機に届く前の自動処理で失敗しメール通知）。写真は収集しない旨を文字列に明記済み。**data収集なし申告とは矛盾しない**（用途文字列＝端末機能の許可であり、App Privacyのデータ収集宣言とは別物）。
- **iOSのバックグラウンド/ロック画面再生（Now Playing）は `mixWithOthers` を付けない**。付けると「他の音と混ざる控えめな再生」扱いになり**アプリがNow Playingの座を取れず、ロック画面に曲名・操作が出ない／リモート操作が効かない**。主役として鳴らす連続再生（耳学）は `playback`＋オプション無しの専用コンテキストを使う（発音ボタンの単発再生は `mixWithOthers` のままで可）。表示/操作は `NowPlayingService`＋`AppDelegate.swift`（`MPNowPlayingInfoCenter`/`MPRemoteCommandCenter`）。チャンネル設定は `super.application` の**後**（rootViewController確定後）。
- **リスト並び替え（ReorderableList）＆スライダー（シークバー）のちらつき対策（ベストプラクティス）**:
  - **キーは安定・一意に**：`ReorderableListView`/`Sliver...` の各行は `ValueKey(不変のid)`（カード番号やインデックス等の可変値をkeyにしない）。`onReorder` はメインで**同期的に**state更新（重い永続化は後追い/バックグラウンド）。再生中要素は id で追従させる（本アプリの耳学キューが該当）。
  - **スライダーは「離した直後にライブ値へ即戻さない」**：`onChangeEnd` で live 値に戻すと、内部状態（再生位置/対象行）が一瞬食い違い**つまみがカクッと飛ぶ**。ドラッグ解放後は**目標値でつまみを保持**し、実際の再生位置が目標へ追いつく（対象行が一致し誤差が小さくなる）まで live 追従を再開しない（`_hold`/`_holdLine`＋保険Timer。`listening_screen.dart` の `_SeekBar` 参照）。
  - **アニメーションの範囲を最小化**：`AnimatedContainer` 等は変化させたい要素だけに限定し、リスト全体を包む `.animation` 相当の広域再描画を避ける。

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
