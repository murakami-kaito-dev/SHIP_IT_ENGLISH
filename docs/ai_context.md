# ShipIt English — AI実装コンテキスト

> このファイルは AI アシスタント（Claude Code 等）が次の実装セッションで最短で文脈を回復するためのもの。
> 人間向けの説明は `docs/technical_overview.md`、日常ルールは `CLAUDE.md` を参照。
> **このファイルは実装を変えたら必ず更新すること。**

最終更新: 2026-07-26（第13セッション: 学習履歴カレンダー）

---

## 現在地（1分で把握する）

- Phase 1 MVP + 優先度「高」「中」の機能をすべて実装済み。**App Store 未申請**（申請手順は `docs/app_store_connect_submission.md` に完備）
- 申請のブロッカー2つ: ① Bundle ID が `com.example.shipItEnglish` のまま ② アプリアイコンが Flutter デフォルトのまま
- `flutter analyze` エラー0、`flutter test` 26件全パス
- **UI は "Terminal-grade" デザインに全面刷新済み**（第14セッション）。色・影・文字は `AppTheme` に集約。詳細は下記セッション記録と CLAUDE.md「デザインシステム」節
- **コンテンツ: 1500枚 / 14カテゴリ（cards.json v1.5.0）**。iPhone専用ビルド（TARGETED_DEVICE_FAMILY=1）
  - カテゴリ: code_review(130) / git_cicd(110) / meetings(110) / slack(110) / architecture(110) / incident(105) / interview(105) / planning(105) / career(105) / remote_work(105) / documentation(105) / tech_debt(100) / qa_testing(100) / security(100)
- **2言語モード搭載**: 初回起動のオンボーディングで選択、設定で切替可能
- **通知は2系統**: 定時リマインダー（設定可） + ストリーク危機通知（未学習の日だけ23:00固定・設定UIなし・メッセージ10種ランダム）
- **サブスクリプション（ShipIt Pro）はコード完了・休眠状態**: `MonetizationConfig.subscriptionEnabled = false`。失効判定・管理/解約導線・設定からの復元まで実装済み。**App Store Connect の商品登録等（ユーザー作業）完了までフラグONは厳禁**（パウォールが機能せずロックカテゴリに入れなくなる）。手順は `docs/subscription_setup_guide.md`
- **学習データのバックアップ/復元あり**（設定→データ。`docs/backup_and_restore.md`）
- 依存追加済み: `flutter_tts`、`in_app_review`、`in_app_purchase`、`url_launcher`、`share_plus`、`file_picker`
- 次の実装候補: トライアル導線 > 分析ダッシュボード（AI解説はAPIキーの扱いを理由に保留。`docs/feature_recommendations.md`）

## 不変条件（壊してはいけないもの）

1. **cards.json が唯一のコンテンツ本体**。カード追加時は必ず JSON の `version` も上げる（上げないとシードされない）。現在 version **1.5.0**（1500枚/14カテゴリ）。配列は categoryDefs順→カテゴリ内ID番号順に整列済み。**IDは不変キー**（並べ替え・大量追加をしても既存IDは変えない。card_numberは配列順で採番されるのでカテゴリ内で連続する）
2. **手動プロバイダーのみ**。riverpod_generator / build_runner のコード生成は使わない
3. **domain層（SrsEngine・models）は Flutter 非依存の純粋 Dart** を維持（ユニットテスト対象のため）
4. **実行時の通信ゼロ**。ネットワークを使う機能を足すと App Store のプライバシー申告（「データ収集なし」）が崩れる。追加時は必ずユーザーに確認。TTSは端末内蔵音声、context_en は開発時に Gemini で一括生成して JSON に焼き込む方式（`dart_defines.json` に GEMINI_API_KEY あり。スクリプト例は git 履歴 or 下記参照）
5. `withOpacity()` を使う（`withValues(alpha:)` は Flutter 3.24 に無い）
6. タブ3画面（`/`, `/categories`, `/settings`）は ShellRoute + NoTransitionPage。フルスクリーン画面（`/study`, `/category/:id`, `/session-complete`, `/onboarding`）はシェル外に置く
7. 色・寸法・文字スタイルは `AppTheme` 経由。**UI文言はハードコードせず `stringsProvider`（`AppStrings`）経由**。カードのコンテンツ（phrase等）は対象外
8. `AppConstants.appVersion` と `pubspec.yaml` の version は手動同期
9. **UI文言を追加するときは `app_strings.dart` の ja / en 両方に追加**（コンストラクタが required なので片方忘れはコンパイルエラーになる）
10. **Pro判定は必ず `isProProvider` を経由する**（`entitlementProvider` を直接見ない）。サブスク無効時は常に true を返す設計で、この一点が「フラグOFF=従来動作」を保証している
11. **無料/Proの線引きの変更は `MonetizationConfig` のみで行う**（freeCategoryIds / freeMaxNewCardsPerDay）。画面側にリテラルを書かない
12. **復習カードは無料プランでも制限しない**（既存ユーザーの学習進捗を壊さないための意図的な設計。変更するな）
13. **学習進捗を書き換えたら必ず `invalidateProgressProviders(ref)` を呼ぶ**。集計系（キャッシュされる）とカード一覧系（family）の両方をここで無効化しているので、**新しいカード一覧プロバイダーを足したらこの関数にも追加する**（忘れると画面に反映されない）
14. **進捗の主指標は `studiedCount`（status != 'new'）**。`mastered` を主指標にすると21日間隔到達まで0のままになる
15. **UIに出す学習状況は `Rating`（忘れた/曖昧/覚えてた・null=未学習）だけ**。`CardStatus` は内部状態でありユーザーに見せない（語彙を2系統にしないこと）
16. **権利(Pro)は必ず再検証する**。`setPro(true)` だけでは解約が反映されない。検証ロジックを変えるときは「オフラインで即剥奪しない」猶予期間の設計を壊さないこと
17. **カード番号はシード時採番**。cards.json の既存カードの順序を入れ替えると番号がずれるので、新規カードは各カテゴリの末尾に追加する

## ファイル早見表（どこを触るか）

| やりたいこと | 触るファイル |
|-------------|-------------|
| ルート追加 | `lib/app.dart`（`createRouter()`。オンボーディング未完了なら initialLocation が `/onboarding`） |
| UI文言の追加・変更 | `lib/core/i18n/app_strings.dart`（ja/en 両方）。画面では `ref.watch(stringsProvider)` |
| 言語モード | `lib/core/providers/language_provider.dart`（`languageModeProvider` / `stringsProvider`。初期値は main.dart で prefs から override） |
| 音声読み上げ | `lib/core/services/tts_service.dart`（`speakTarget(text, mode)`: jaモード=en-US / enモード=ja-JP） |
| レビュー依頼条件 | `lib/core/services/review_service.dart` + `AppConstants.reviewRequestMinStreak` |
| 色・スタイル | `lib/core/theme/app_theme.dart`（`cardShadow` あり） |
| 定数・prefsキー | `lib/core/constants/app_constants.dart` |
| DBスキーマ変更 | `lib/core/database/database_helper.dart`（`_databaseVersion`（現在3）++ と `_onUpgrade`） |
| SQLクエリ追加 | `lib/features/study/data/local_card_repository.dart`（抽象は `card_repository.dart`。ただし画面側は `as LocalCardRepository` キャストで具象メソッドを呼んでいる箇所あり） |
| SRSロジック | `lib/features/study/domain/srs_engine.dart`（変更時は `test/unit/srs_engine_test.dart` も） |
| 学習フロー | `lib/features/study/providers/study_providers.dart`（StudySessionNotifier。`loadSession(categoryId:)` でカテゴリ限定） |
| カテゴリ定義 | `lib/features/categories/providers/categories_providers.dart` の `categoryDefs`（トップレベルconst、14カテゴリ、description/description_en） |
| 課金・権利まわり | `lib/core/monetization/`（config / entitlement_provider / purchase_service）。検証の呼び出しは `app.dart` |
| バックアップ | `lib/core/services/backup_service.dart`（`_formatVersion` の管理に注意） |
| オンボーディング | `lib/features/onboarding/presentation/onboarding_screen.dart`（文言はこのファイル内にローカル定義） |
| 設定項目追加 | `lib/features/settings/providers/settings_providers.dart` + `app_constants.dart` にキー追加 |

## 第14セッション（2026-07-26）で変えたこと

### 新規カード数の上限を「カード総数」に拡大＋スライダー廃止
- 従来は `AppConstants.maxNewCardsPerDay = 20` が上限で、Homeのスライダーで1〜20を選択していた
- 上限を **総カード数（`overallProgressProvider.totalCount` ≈ 1500）に変更**。1〜総数を自由に選べる
- 1〜1500をスライダーで選ぶのは刻みが細かすぎて非現実的なため、**スライダーを廃止**し `home_screen.dart` に以下を新設：
  - `_NewCardsStepper`（ConsumerStatefulWidget）: `− [直接入力TextField] ＋`。number keyboard・`FilteringTextInputFormatter.digitsOnly`・フォーカス喪失/submitで確定＆クランプ。フォーカス中は外部値でテキストを書き換えない
  - `_NewCardsPresets`: プリセットchip（5/10/25/50/100のうち総数未満のもの）＋末尾に「最大 (N)」
  - どちらも無料プラン超過時は `freeMaxNewCardsPerDay` にクランプしてパウォールへ（サブスク休眠中は isPro=true なので実質無制限）
- `AppConstants.maxNewCardsPerDay`(=20) は practice セッションの limit と読込中フォールバックにのみ残存（新規カード上限としては不使用）
- 文言追加: `newCardsMaxLabel`（最大/Max）。`proSliderHint` を「Proで最大20枚」→「Proで無制限」に更新
- **数値入力は即確定**（`onChanged: _liveApply`）。別の場所をタップしなくても入力したそばから反映。キーボードの「完了」/外側タップでも確定
- **1日の新規枠は消化制**にした: `loadSession`・`dailySessionInfoProvider` が「上限 − 今日学習した新規（`daily_stats.new_cards`／`getNewCardsStudiedToday()`）」で残り枠を計算。40枚設定で3枚やって再開すると 0/37 になる（以前は毎回 0/40 に戻っていた）

### 評価ボタンに次回復習間隔を表示（エビングハウス基準）
- 「忘れた／曖昧／覚えてた」の各ボタン下に次回間隔を表示（例: 「10分」「1日」「3日」）
- カードをめくった時に `flipCard()`（async 化）が現在のSRS状態を読み `StudySessionState.currentProgress` に保持。`study_screen` が `SrsEngine.projectedInterval(current, rating)` で3評価分を予測し `RatingButtons(intervals:)` に渡す
- **表示＝実挙動**を保証: `projectedInterval` は内部で `processReview`（副作用なし）を呼ぶので、押した結果と一致
- 「忘れた」は `next_review = now + relearnStepMinutes(=10)分`（従来は now 即時）。`intervalDays` は 0 のまま。セッション内の即時再出題は `retryCount` 側で別管理につき影響なし
- 文言整形は `AppStrings.nextReviewIn(Duration)`（分/時間/日/週間/か月・ja/en）
- テスト更新: `srs_engine_test`／`daily_set_test` の forgot 期待値を「約10分後・当日中」に変更、`projectedInterval` のテストを追加。`study_session_test` の `_flipAndRate` は `await notifier.flipCard()` に修正

### 学習カードのセクションタグ表記を変更
- FlipCard の `_fileTag()` を「`// git/cicd #15`」→「`Git / CI/CD  #15`」に変更（`//` コメント風プレフィックス廃止・`categoryDefs` の表示名を使用）

### フルスクリーン画面の背景黒バグ＋ホームのちらつき修正
- フルスクリーン遷移は `AppBackground(child: Scaffold(...))` で Scaffold ごと包む（body だけ包むと AppBar/ステータスバー裏・下部が黒残り）。対象: study/session-complete/history/category詳細/search/paywall/onboarding
- ホームの新規枚数±変更時のちらつきは `sessionInfo.when(skipLoadingOnReload: true)` で解消

### デザイン全面刷新（"Terminal-grade" — 機能は不変）
- ユーザー要望「平面的で奥行きがない／使っていて楽しくない」に対し、**機能を一切変えず**見た目だけ刷新
- **`core/theme/app_theme.dart` に全集約**（フィールド名は互換維持。既存の全画面が `AppTheme.*` を参照するため、ここを直すと波及する）
  - インディゴ基調（`primary = #5B54E6`）＋グラデCTA（`primaryGradient`）＋背景グラデ（`backgroundGradient`）
  - 多層影 `cardShadow` / `heroShadow`（学習カード）/ `buttonShadow`。`AppTheme.cardDecoration` で統一
  - モノスペース識別子：`monoFont = 'Menlo'`（iOS内蔵・オフライン）で数値/率/タグを表示。`monoNumber` / `monoNumberLarge` / `monoLabel`。**`google_fonts` は使わない**（実行時通信になり「データ収集なし」申告と衝突）
- **新規共通部品**：`shared/widgets/gradient_button.dart`（主要CTA）、`shared/widgets/app_background.dart`（背景グラデ）
  - タブ画面（Home/Categories/Settings）は AppShell が `AppBackground` で包むので Scaffold を `backgroundColor: Colors.transparent` にするだけ
  - フルスクリーン遷移（study / session-complete / history / category詳細 / search / paywall / onboarding）は各 body を `AppBackground` で包む＋Scaffold透明化
- **影のクリッピング対策**：`borderRadius` を持つ `Material` は子をクリップして内側 boxShadow が消える → `DecoratedBox(cardDecoration) > Material(transparent, clip antiAlias) > InkWell > Padding` の順で組む（`card_list_tile.dart` が基準実装）
- **学習カード（FlipCard）をヒーロー化**：`heroShadow`＋表面グラデ＋mono の `// category/sub #n` ファイルタグ＋下向きヒント
- **アイコンは `_rounded` 系に統一**、ボトムナビは上部ヘアライン＋上向き影
- 検証：`flutter analyze` 0件 / `flutter test` 26件パス / iOS simulator 起動確認済み
- 詳細ルール・落とし穴は CLAUDE.md「デザインシステム」節に記載

## 第13セッション（2026-07-26）で変えたこと

### 学習履歴カレンダー
- ホームのストリークバッジ🔥（`StreakBadge` に `onTap` を追加、カレンダーアイコン表示）をタップ → `/history`
- `features/history/`：`getAllStudyDays()`（daily_stats で cards_studied>0 の日付→枚数）→ `studyDaysProvider` → `HistoryScreen`
- 自前カレンダーグリッド（外部パッケージ不使用）。日曜始まり、学習日を primary 色で塗り、今日は炎色の枠。月を前後に送れる（未来の月へは進めない）。今月/累計の学習日数を表示
- `invalidateProgressProviders` に `studyDaysProvider` を追加（学習後にカレンダーも即更新）

## 第12セッション（2026-07-26）で変えたこと（UX改善3件）## 第12セッション（2026-07-26）で変えたこと（UX改善3件）

### 新規カード数の設定をHomeへ移動
- 以前は設定タブの「学習」セクションにあり、Homeの「新規」枚数表示と別タブで分かりにくかった
- `_TodaySessionCard`（ConsumerWidget化）内、今日のセッションのすぐ下にスライダーを設置。設定タブからは削除（`sectionStudy` セクションごと撤去）。無料プランの上限ガード（clamp+paywall誘導）も移設

### カテゴリ学習を「枚数指定なし・設定シート化」
- **枚数指定を廃止**（カテゴリ学習は該当する全カードが対象）。従来の `/study?category=<id>`（新規＋復習を設定枚数で組む）方式をやめた
- カテゴリ学習は設定シート（`range_study_sheet.dart` を拡張）で以下を指定:
  1. **学習状況フィルタ**（未学習/忘れた/曖昧/覚えてた・複数選択OR・未選択=全て）。値は `last_rating`（'new'=未学習=last_rating IS NULL）
  2. **番号範囲**（RangeSlider）
  3. **出題順**（番号順=card_number ASC / ランダム=RANDOM()）
- ルート: `/study?category=<id>&from=<n>&to=<m>&statuses=<csv>&order=<asc|random>`
- 実装: `LocalCardRepository.getCategoryStudyCards()` / `countCategoryStudyCards()`（WHERE句は `_categoryStudyWhere` で共用）、`StudySessionNotifier.loadCategoryStudySession()`、`categoryStudyCountProvider`（件数プレビュー）、`CategoryStudyConfig`（== キー）
- 入口: Homeの🎛アイコン（カテゴリ選択可）／カテゴリ詳細の「このカテゴリを学習」（カテゴリ固定）。どちらもPro限定は既存どおりゲート
- 旧 `loadRangeSession` / `getCardsInRange` は `loadCategoryStudySession` / `getCategoryStudyCards` に置換済み

## 第11セッション（2026-07-26）で変えたこと

### 学習セッションを途中で抜けても学習分を記録する
- 課題: 戻る/システムバックで途中離脱できるが、**各カードのSRS状態は評価時に保存される一方、当日の統計(daily_stats)・ストリークは `buildSessionResult`（＝完走時）でしか確定しなかった**ため、途中でやめると「今日学習した」実績（週間バー・ストリーク・hasStudiedToday）に計上されなかった
- 修正: `study_screen` の終了処理を `_exitSession()` に一本化。評価済みが1枚以上あれば確認ダイアログ→**その時点までを `buildSessionResult()` で記録してからホームへ**。PopScope とAppBar戻るの両方を統一（従来はAppBar側が invalidate を呼んでおらず集計が古いままだった不整合も解消）。`_exiting` フラグで多重実行防止
- 「新規/復習」設計は不変。カテゴリ学習の枚数も不変（下記）

### カテゴリ学習の枚数（調査結果・固定ではない）
- カテゴリ詳細「このカテゴリを学習」= `/study?category=<id>` → `loadSession(maxNewCards=設定値, categoryId)`
- 出題 = **そのカテゴリの復習期限到来カード全部** + **そのカテゴリの新規カードを「1日の新規カード数」設定の上限まで**（無料は最大5）
- つまり枚数 = (カテゴリ内の期限到来復習) + min(カテゴリ内の未学習, 新規設定)。**固定30ではない**。デフォルト新規設定は5（`defaultNewCardsPerDay`）、最大20

## 第10セッション（2026-07-22）で変えたこと

### スワイプしかけて戻すと表面に戻るバグ
- 原因: `SwipeCardWrapper` の `Stack` **先頭**にスワイプ中だけ出るフィードバック背景があり、ドラッグ開始で `_dragOffset != 0` になると背景が index0 に挿入され、メインカード(FlipCard)が index0→1 にずれる。keyが無いためFlutterがFlipCardのStateを破棄・再生成し、フリップ用 AnimationController が初期値0(表面)にリセットされていた
- 修正: Stack の各子に `ValueKey`（`swipe-card` / `swipe-feedback` / `swipe-icon-*`）を付与してStateを保持。**条件付きの子を出し入れするStackでは子にkeyを付ける**のが鉄則

### 範囲指定学習（新機能）
- カテゴリ内の通し番号 `from`〜`to` を指定して学習。ルート `/study?category=<id>&from=<n>&to=<m>`
- `LocalCardRepository.getCardsInRange()` / `StudySessionNotifier.loadRangeSession()` / `study_screen` の分岐で対応
- UI: `range_study_sheet.dart`（共通シート）。Homeの「範囲を指定して学習」ボタン（カテゴリ選択＋RangeSlider）、カテゴリ詳細の右側ボタン（カテゴリ固定）から開く
- 無料プランはロックされていないカテゴリのみ選択可（Home）／カテゴリ詳細のボタンはPro限定（無料はパウォール）。既存のPro判定と同じ導線
- 評価は通常どおりSRSに反映される（範囲内の全カードを番号順に出題）

## セッション用語の定義（調査結果・第10セッションで確認）
- **新規(New)**: `learning_progress.status = 'new'`（一度も学習していない）カード数。表示は「1日の新規カード数」設定でクランプ（無料は最大5）。無料は許可カテゴリのみ
- **復習(Review)**: `status != 'new' かつ next_review <= 現在`（学習済みで次回予定日が到来）のカード数。**クランプなし＝期限到来分すべて**
- **合計** = 復習 + クランプ後の新規
- **もう一度復習する(Practice)**: `date(last_reviewed) = 今日` のカード（＝その日に学習したカード）を ease_factor 昇順で最大20枚。**当日学習分のみ**。過去日や未学習カードは含めない。予定日は無視

## 第9セッション（2026-07-22）で変えたこと（実機バグ修正2件）

### 通知が全く違う時刻に鳴る
- 原因: `tz.initializeTimeZones()` は呼ぶが `tz.local` を設定しておらず既定のUTCのまま。`zonedSchedule` がUTC基準で組まれ、日本時間と9時間ずれていた
- 修正: `NotificationService.initialize()` で `tz.setLocalLocation(tz.getLocation('Asia/Tokyo'))`。**日本時間固定でリマインドする仕様**（ユーザー要望）。定時リマインダー・ストリーク危機通知の両方に効く

### 学習が設定枚数で終わらず最初に戻る
- 原因1: `StudySessionState.copyWith` が `currentCard: currentCard ?? this.currentCard` で、完了時に `currentCard: null` を渡しても無視 → 最後のカードが残って再表示され「また学習し始める」ように見えた。遷移前の隙に再操作されると多重完了しうる
- 原因2: `_completeSession` の `buildSessionResult()`（ストリーク更新・通知キャンセル・統計保存）が実機で失敗すると `context.go('/session-complete')` に到達できず、学習画面に留まり「終われない」
- 修正: ①copyWithをセンチネル（`static const _keep`）方式にして `null` 設定を可能に ②`_completeSession` を try/catch で囲み、副作用が失敗しても必ず遷移。`_completing` フラグで二重起動防止
- **`test/unit/study_session_test.dart` を新規追加**（FakeRepoでNotifierを駆動し、5枚→ちょうど5回で完了・currentCard=null・「忘れた」再出題上限2回で完了を検証）。UIを介さずセッション完了ロジックを恒久ガード
- 注意: `copyWith` で他の nullable フィールドを null にしたくなったら同じセンチネル方式を使う

## 第8セッション（2026-07-21）で変えたこと

### cards.json を整列 + 1500枚に拡張
- **整列**: 従来は `cr_001, gc_001, mt_001…` と全カテゴリを1周ずつ繰り返すインターリーブ配置だった → categoryDefs順→カテゴリ内ID番号順にグルーピング。重複フレーズ1件（car_046＝car_034と同一）を除去
- **拡張**: 799→1500枚（+701）。**Gemini gemini-2.5-flash で開発時に一括生成**（実行時API呼び出しなし＝アーキテクチャ準拠。`context_en` と同じ方式）。生成スクリプトは scratchpad の `gen_cards_1500.py`
  - カテゴリ別サブテーマを与えて多様性を確保、既存フレーズを渡して重複回避、正規化重複除去＋スキーマ検証
  - 目標配分: code_review 130 / git_cicd・meetings・slack・architecture 110 / incident〜documentation 105 / tech_debt・qa_testing・security 100 = 1500
  - 検証済み: スキーマ不備0・難易度不正0・重複フレーズ0・重複ID0
- careerのIDは #46 が欠番（除去した重複の名残）だが、**card_numberは配列順採番なので表示番号は1..105で連続**。IDは不変キーとして欠番のまま維持
- DBの反映確認: `sqlite3 <db> "SELECT COUNT(*) FROM cards"` が 1500

## 第7セッション（2026-07-20）で変えたこと

### サブスクの穴を3つ塞いだ（有効化前の必須項目だった）
- **A: 失効判定** — `onEntitlementChanged(true)` しか無く、**解約・返金しても永久にProのまま**だった
  - `PurchaseService.verifyEntitlement()`: `restorePurchases()` を投げて対象商品が `restored` で返るかで判定（`in_app_purchase` に現在の権利を返すAPIが無いため）
  - `EntitlementNotifier.verify()`: active→維持 / inactive→**即失効** / unknown(オフライン)→猶予期間7日まで維持
  - 呼び出しは `app.dart` の initState と `didChangeAppLifecycleState(resumed)`。12時間間隔で再検証
  - 定数はすべて `MonetizationConfig`（recheckInterval / gracePeriod / verifyTimeout）
- **B: 管理・解約導線** — 購読中は設定の行が `onTap: null` で何も起きなかった。`manageSubscriptionsUrl` を `url_launcher` で開くようにした（Guideline 3.1.2 対応）
- **C: 復元導線** — パウォール内にしか無く、再インストール直後は全カテゴリがロックされて詰んでいた。設定のProセクションに常設した

### 学習データのバックアップ/復元
- `core/services/backup_service.dart`: 学習進捗・日別統計・ストリーク・設定を JSON 化 → `share_plus` で共有シート、`file_picker` で読み込み
- カード本体は含めない（cards.json から再生成されるため）。`format_version` で将来の互換性を管理
- 詳細は `docs/backup_and_restore.md`

### AI解説は見送り（ユーザー判断）
- アプリにGeminiキーを埋め込むと IPA から抽出され第三者に課金枠を使われるため、自前プロキシが前提になる。課金開始後に再検討

## 第6セッション（2026-07-20）で変えたこと

### DB v3（cards.json は v1.3.0 で再シード）
- `cards.card_number`: カテゴリ内の通し番号。**シード時に cards.json の並び順で1から採番**するので、既存カードの順序を入れ替えると番号が変わる（追加は末尾に）
- `learning_progress.last_rating`: 最後の自己評価。既存データは status から推定して移行（learning→forgot / review→uncertain / mastered→remembered）

### 表示ステータスを評価語彙に統一（ユーザー要望）
- 画面に出すのは **`Rating`（忘れた/曖昧/覚えてた）+ 未評価は「未学習」** のみ。`CardStatus`（new/learning/review/mastered）はSRS内部状態として残るが**UIには出さない**
- `CardWithStatus.status` → `.rating`、`CardStatusChip(rating:)` に変更。`AppStrings` から statusLearning/statusReview/statusMastered を削除
- 注意: `masteredCount` は依然として内部集計に使う（ホームの補助行のみ）

### カード番号の表示
- `shared/widgets/card_list_tile.dart`（新規・共通化）: 行頭に番号バッジ。検索/フィルタでは `showCategoryName: true` でカテゴリも表示
- `shared/widgets/card_number_label.dart`: 「💬 Code Review #3」形式のラベル（詳細シート用）

### カテゴリタブのフィルタ
- `CardFilter`（categories: OR / ratings: OR、両方指定は AND。null要素=未学習）+ `cardFilterProvider` + `filteredCardsProvider`
- `CardFilterBar`（カテゴリ画面上部）。フィルタが有効なときはカテゴリカードではなく**該当カード一覧**を表示する
- SQLは `filterCards()` で動的に WHERE を組み立てる

### 評価の即時反映（第7セッションで方式変更）
- 当初はシートの戻り値で一覧を更新していたが、**シートを閉じるまで反映されない**うえ `PopScope(canPop: false)` がスワイプで閉じる操作も潰していた
- 現在は `invalidateProgressProviders(ref)` が**カード一覧系プロバイダーも無効化**する方式。family プロバイダーは引数なし invalidate で全インスタンスが対象になるため、どの画面が背後にあっても評価した瞬間に更新される。呼び出し元は戻り値を扱わない

### 未学習に戻す（誤タップの取り消し）
- 詳細シートの3段階評価の下に「未学習に戻す」ボタン。`LearningProgress.initial()` を保存してSRS状態（ease_factor・間隔・回数・last_rating）ごと初期化する
- 評価ボタンは現在の状況を塗りつぶしで示す（`_RateButton.selected`）

### 発見・修正したデータ不整合（重要）
- cards.json が別途 **800枚/14カテゴリ** に拡張されていたが、**version が据え置きだったため再シードされず**、DBは790枚・番号未採番のままだった → version を 1.4.0 に上げて解消
- `categoryDefs` が11カテゴリのままで、**security / qa_testing / tech_debt の3つがカテゴリタブに出ていなかった** → 追加済み
- 教訓: **cards.json を触ったら version を上げる / カテゴリを足したら categoryDefs も足す**。反映確認は `sqlite3 <db> "SELECT COUNT(*) FROM cards;"`

### ホームの導線見直し
- 「学習を始める」を**常時表示**（学習済みの日は完了バナーを上に出すだけ）
- 「もう一度復習」は `practiceCardsCount` 付きボタンとして常設。対象は**その日に学習したカードのみ**（`date(last_reviewed) = today`。過去日の学習分は含めない）

## 第5セッション（2026-07-20）で変えたこと（実機バグ修正）

### TTSが実機で無音だった
- 原因: iOSのオーディオセッション未設定。既定の ambient カテゴリは**サイレントスイッチに従う**ため、消音状態だと再生されない
- 修正: `TtsService._ensureInitialized()` で `setSharedInstance(true)` + `setIosAudioCategory(playback, [defaultToSpeaker, mixWithOthers])`。あわせて `isLanguageAvailable` チェックと try/catch を追加

### 進捗が「0/195」から動かなかった（2つの原因が重なっていた）
1. **キャッシュ**: `dailySessionInfoProvider` 等は autoDispose なしの FutureProvider。セッション後に `context.go('/')` してもキャッシュのまま
   → `core/providers/progress_refresh.dart` の `invalidateProgressProviders(ref)` を新設し、**セッション完了時・途中離脱時・詳細シートでの評価時**に呼ぶ
2. **指標の選択ミス**: `mastered` は interval >= 21日が条件で数週間かかる
   → `getStudiedCardCount()` / `getCategoryStudiedCounts()`（status != 'new'）を追加し、進捗バーと数値は `studiedCount` ベースに。mastered はホームの補助行に格下げ（`studiedOf` / `masteredCountLabel`）

### 「もう一度復習する」が常に空だった
- 原因: 上記キャッシュに加え、**「曖昧」も quality=3 で正解扱い**のため `next_review` が翌日になり、当日は対象0件になっていた
- 修正: `getPracticeCards()` / `getPracticeCardsCount()` を追加（**今日学習した未習得カード（learning/review）＋期限切れカード**を ease_factor 昇順）。`/study?mode=practice` → `loadPracticeSession()` で出題。ホームのボタン活性判定も `practiceCardsCount` に変更

### カード詳細から学習状況を変更できるように
- `card_detail_sheet.dart` を関数から `ConsumerStatefulWidget`（`_CardDetailSheet`）に変更し、3段階評価ボタンを追加
- 学習セッションと**同じ `SrsEngine` を通す**ので次回出題タイミングにも正しく反映される。評価後はチップ表示を即更新し `invalidateProgressProviders` を呼ぶ

## 第4セッション（2026-07-20）で変えたこと（差分の意図）

### ストリーク危機通知（feature_recommendations 旧7）
- `notification_service.dart`: 今後7日分を曜日別ID（2001〜2007）でスケジュールし、メッセージは10種（ja/en各）からランダム。学習完了時（`buildSessionResult`）と起動時（既に学習済みの場合）に**当日分だけ**キャンセル
- **時刻は23:00固定・ユーザー設定なし**（`AppConstants.streakReminderHour`）。当初は設定トグル+時刻を実装したが、ユーザー要望で撤去した経緯あり。**設定UIを再追加しないこと**
- 定時リマインダーの文言も言語モード対応に

### 週間サマリー / 検索 / iPhone専用化
- `weeklyStatsProvider`（`getRecentStudyCounts`）→ ホームに `_WeeklySummaryCard`（直近7日の棒グラフ）
- `/search`: `searchCards()`（phrase/translation/example の LIKE・50件上限）。入口はカテゴリ画面の検索アイコン。ロックカテゴリのカードは検索結果でロック表示
- カード詳細ボトムシートを `shared/widgets/card_detail_sheet.dart` に共通化（`CardStatusChip` も移動。カテゴリ詳細と検索で共用）
- pbxproj の `TARGETED_DEVICE_FAMILY` を 1 に（3コンフィグとも）

### コンテンツ拡充（cards.json v1.2.0 = 195枚 / 11カテゴリ）
- Web調査に基づき新カテゴリ4種×15枚: `planning`（見積もり・スプリント）/ `career`（1on1・評価・昇進）/ `remote_work`（非同期・時差・通話）/ `documentation`（RFC・ADR・ランブック）
- `context_en` は執筆時に直接付与（Gemini不要だった）。`categoryDefs` にも4件追加。パウォールの「全7カテゴリ」→「全11カテゴリ」に更新済み
- 新カテゴリはすべてPro側（`freeCategoryIds` は変更なし）

### サブスク有効化の判断
- **フラグは OFF のまま**。コンテンツは十分になったが、有効化には有料App契約・商品登録・Sandboxテスト（すべてユーザーの App Store Connect 作業）が必須。商品未登録でONにするとロックカテゴリに入れなくなるため

## 第3セッション（2026-07-20）で変えたこと（差分の意図）

### サブスクリプション「ShipIt Pro」— 実装完了・休眠状態
- **設計**: フリーミアム。無料=3カテゴリ（code_review/meetings/slack）+新規5枚/日+全コア機能（SRS/ストリーク/TTS/通知）。Pro=全7カテゴリ+新規20枚/日+カテゴリ集中学習
- **マスタースイッチ**: `lib/core/monetization/monetization_config.dart` の `subscriptionEnabled`（現在 false）。この1箇所を true にするだけで全ゲート・パウォール導線が有効化される
- 新規: `monetization/`（config / entitlement_provider / purchase_service）、`features/paywall/`（`/paywall`、文言はオンボーディング同様ファイル内ローカル）
- ゲート箇所: categories_screen（🔒+paywall遷移）、category_detail_screen（直リンクガード+集中学習ボタン）、settings_screen（スライダー上限+Proセクション※有効時のみ表示）、studyModeProvider（新規枚数clamp）、dailySessionInfoProvider / loadSession（新規カードを無料カテゴリに限定）
- リポジトリ: `getNewCards(allowedCategories:)` / `getNewCardsCount(allowedCategories:)` 追加
- 課金は公式 `in_app_purchase`（StoreKit 2）のみ。サーバー・第三者SDKなし → プライバシー「データ収集なし」維持。entitlementは端末内prefs保存（返金の厳密追跡はしない割り切り、ガイドに明記）
- 検証: フラグON/OFF両方でビルド・起動確認済み。OFF時は従来と完全同一動作
- **有効化前の必須作業**は `docs/subscription_setup_guide.md`（有料App契約→商品2つ登録→Sandboxテスト→フラグON→privacyPolicyUrl差し替え）

## 第2セッション（2026-07-19）で変えたこと（差分の意図）

### 2言語モード + 全UIローカライズ
- `core/i18n/app_strings.dart`: `LanguageMode`（ja/en）と全UI文言。**ja=日本語話者が技術英語を学ぶ（従来動作）/ en=英語話者が技術日本語を学ぶ**
- カードの表は両モードとも英語フレーズ。裏は jaモード=和訳・日本語解説、enモード=日本語表現がメイン・解説は `context_en`（英語）
- `context_en`（135枚）は Gemini（gemini-2.5-flash）で開発時に一括生成 → cards.json v1.1.0 に焼き込み。**モデル名 `gemini-2.0-flash` は404になる**ので注意
- DB v2: `cards.context_en` カラム追加（`_onUpgrade` でALTER TABLE）
- ユーザー要望「学習アイテム表示までのUIは日本語で」→ jaモードのUIを全面日本語化することで対応

### TTS
- `flutter_tts` ^4.2.5。`TtsService().speakTarget(text, mode)`。カード裏面（フレーズ・例文）と詳細シートにスピーカーアイコン。iOSネイティブ設定は不要だった

### カテゴリ別学習
- `/study?category=<id>`。`getCardsForReview`/`getNewCards` に optional `categoryId` 追加
- ストリーク・daily_stats には通常どおり反映（仕様判断）。0枚なら空状態画面（StudyScreen に `_loaded` フラグ導入で無限スピナー回避）

### オンボーディング
- 3ページ PageView（スワイプ不可・ボタン誘導）。1ページ目=モード選択（バイリンガル表記）、2〜3ページ目=選択言語で説明
- `onboarding_done` フラグ。ルーターは `createRouter(showOnboarding:)` に変更（main.dart で prefs を読んで分岐）

### アプリ内レビュー
- SessionCompleteScreen 表示2秒後、ストリーク3日以上・未依頼なら `requestReview()`。`review_requested` フラグで一度きり

## 第1セッション（2026-07-19）で変えたこと（差分の意図）

### UIUX改善（HIG準拠）
- `rating_buttons.dart`: GestureDetector → Material+InkWell 化、`HapticFeedback.lightImpact()` 追加
- `flip_card.dart`: カードを親領域いっぱいに（`height: double.infinity`）、`AppTheme.cardShadow` 追加、フリップ時 `selectionClick`。カテゴリバッジをフレーズの上に移動
- `swipe_card_wrapper.dart`: スワイプ確定時 `mediumImpact`
- `study_screen.dart`: 下部を高さ96固定の AnimatedSwitcher に（フリップ前後のレイアウトジャンプ解消）。誤っていたヒント文言「Tap or swipe up to flip」→「カードをタップしてめくる」。進捗バーを共通 `ProgressBar` に統一
- `home_screen.dart`: ストリーク行に日付表示、Today's Session カードにアイコン行 + 合計を強調表示（`_InfoRow` に icon/iconColor 追加）
- `settings_screen.dart`: `_SectionHeader`（学習/通知/データ）+ バージョンフッター追加
- `ios/Runner/Info.plist`: `ITSAppUsesNonExemptEncryption=false` 追加（輸出コンプライアンス自動スキップ）

### 新機能: カテゴリ詳細
- 新規: `lib/features/categories/presentation/category_detail_screen.dart`
  - カード一覧（ステータスチップ: 未学習/学習中/復習中/習得済）+ タップで DraggableScrollableSheet に例文・使用場面
- `categories_providers.dart`: `categoryDefs` をトップレベルへ、`CardWithStatus` + `categoryCardsProvider`（autoDispose.family）追加
- `local_card_repository.dart`: `getStatusesByCategory(categoryId)` 追加（card_id→status のMap）
- `categories_screen.dart`: カテゴリカードを InkWell 化 → `context.push('/category/${cat.id}')`、chevron 追加
- `app.dart`: ルート `/category/:id` 追加（シェル外・通常遷移）

### ドキュメント
- `docs/app_store_connect_submission.md`: 申請の全手順・全入力値（説明文・キーワード・プライバシーポリシー文面含む）
- `docs/feature_recommendations.md`: 追加機能の優先度リストと「実装しなかった理由」
- `docs/technical_overview.md`: 新人向け技術ドキュメント
- `docs/ai_context.md`: 本ファイル

## 既知の未解決事項 / 注意

- Widgetテスト未整備（flip_card / rating_buttons / 各画面）
- `prefer_const_constructors` の info が10件強残っている（害なし。まとめて潰してよい）
- iPad レイアウトは未検証のまま iPad 対応ビルドになっている（申請前に `TARGETED_DEVICE_FAMILY = 1` にするか検証が必要）
- `_TodayCompleteCard` の「Review again」は復習カードが無いと SnackBar を出すだけ（仕様どおり）
- ホームの `hasStudiedToday` は daily_stats 基準。カテゴリ詳細からの閲覧は学習にカウントされない（正しい挙動）

## 検証コマンド

```bash
flutter analyze                 # エラー0を維持
flutter test                    # 23 tests
flutter run -d <simulator-id>   # xcrun simctl list devices available で確認
```
