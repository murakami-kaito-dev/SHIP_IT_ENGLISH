# ShipIt English — App Store Connect 申請完全ガイド

> **このドキュメントのゴール**: App Store Connect にアプリを登録し、審査に提出して「審査待ち（Waiting for Review）」状態に到達し、承認後は「配布ボタンを押すだけ」の状態にすること。
> 上から順に実行すれば漏れなく完了するように、**全項目・全入力値を省略なしで**記載しています。

---

## 目次

- [STEP 0. 申請前に必ず済ませるコード側の準備](#step-0-申請前に必ず済ませるコード側の準備)
- [STEP 1. Apple Developer での事前登録](#step-1-apple-developer-での事前登録)
- [STEP 2. App Store Connect で新規 App を作成](#step-2-app-store-connect-で新規-app-を作成)
- [STEP 3. 「App 情報」タブの入力](#step-3-app-情報タブの入力)
- [STEP 4. 「価格および配信状況」の設定](#step-4-価格および配信状況の設定)
- [STEP 5. 「App のプライバシー」の入力](#step-5-app-のプライバシーの入力)
- [STEP 6. ビルドのアップロード](#step-6-ビルドのアップロード)
- [STEP 7. バージョン情報ページ（1.0 提出用）の入力](#step-7-バージョン情報ページ10-提出用の入力)
- [STEP 8. 審査への提出](#step-8-審査への提出)
- [STEP 9. 審査ステータスの見方と承認後の配布](#step-9-審査ステータスの見方と承認後の配布)
- [付録A. そのまま使える申請用テキスト](#付録a-そのまま使える申請用テキスト)
- [付録B. プライバシーポリシーのテンプレートと公開方法](#付録b-プライバシーポリシーのテンプレートと公開方法)
- [付録C. リジェクトされやすいポイントと対策](#付録c-リジェクトされやすいポイントと対策)

---

## STEP 0. 申請前に必ず済ませるコード側の準備

現状のリポジトリで**未完了**の項目。これを済ませないと申請できません。

### 0-1. Bundle ID の変更（必須・現在 `com.example.shipItEnglish` のまま）

`com.example.*` は Apple に登録できません。

```bash
open ios/Runner.xcworkspace
```

Xcode → `Runner` ターゲット → `Signing & Capabilities` タブ:

| 設定 | 値 |
|------|-----|
| Bundle Identifier | `com.<あなたのID>.shipitenglish`（例: `com.kaitomurakami.shipitenglish`） |
| Automatically manage signing | ✅ チェック |
| Team | 自分の Apple Developer チームを選択 |

> 一度リリースすると Bundle ID は**二度と変更できません**。慎重に決めてください。

### 0-2. アプリアイコン（設定済み ✅）

`assets/icon/app_icon.png`（2048×2048）をマスターに、`flutter_launcher_icons` で
iOS/Android の全サイズを生成済み（iOSはアルファ除去済み＝Guideline 2.3.8 対応）。
アイコンを差し替えたい場合はマスター画像を置き換えて再生成する:

```bash
dart run flutter_launcher_icons
```

設定は `pubspec.yaml` の `flutter_launcher_icons:` セクションにある。

### 0-3. 輸出コンプライアンス設定（済み）

`ios/Runner/Info.plist` に `ITSAppUsesNonExemptEncryption = false` を設定済みです（本アプリは通信を一切行わないため、独自暗号化なし）。これにより、ビルドをアップロードするたびに表示される「輸出コンプライアンス」の質問が自動でスキップされます。

### 0-4. バージョン番号の確認

`pubspec.yaml`:

```yaml
version: 1.0.0+1   # このままでOK。再提出のたびに +1 する（1.0.0+2, ...）
```

### 0-5. 最終チェック

```bash
flutter analyze        # エラー0件であること
flutter test           # 全テストパス
flutter build ipa      # ビルドが通ること（署名設定後）
```

---

## STEP 1. Apple Developer での事前登録

### 1-1. Apple Developer Program 加入（未加入の場合）

- [https://developer.apple.com/programs/](https://developer.apple.com/programs/) → 「Enroll」→ 年額 $99（約15,000円）
- 個人開発なら「Individual」でよい。審査に1〜2日かかることがある。

### 1-2. App ID (Identifier) の登録

1. [developer.apple.com/account/resources/identifiers/list](https://developer.apple.com/account/resources/identifiers/list) を開く
2. `+` → **App IDs** → **App** を選択して Continue

| 項目 | 入力値 |
|------|--------|
| Description | ShipIt English |
| Bundle ID | **Explicit** を選び、STEP 0-1 で決めた ID（例: `com.kaitomurakami.shipitenglish`） |
| Capabilities | **何もチェックしない**（本アプリはローカル通知のみで、Push Notifications の Capability は不要） |

3. Continue → Register

> Xcode の Automatically manage signing を使う場合、この手順は Xcode が自動で行うこともあります。既に一覧に表示されていればスキップ可。

---

## STEP 2. App Store Connect で新規 App を作成

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) にログイン
2. **マイ App** → 左上の `+` → **新規 App**
3. ダイアログに以下を入力:

| 項目 | 入力値 | 補足 |
|------|--------|------|
| プラットフォーム | ✅ iOS | macOS 等はチェックしない |
| 名前 | `ShipIt English` | App Store 上の表示名。全世界で一意である必要あり。取られていた場合は `ShipIt English - エンジニア英語` などにする（30文字以内） |
| 主要言語 | `日本語` | メタデータのデフォルト言語 |
| バンドルID | STEP 1-2 で登録した ID をプルダウンから選択 | 表示されない場合は Identifier 登録が未完了 |
| SKU | `shipitenglish001` | 社内管理用の任意文字列。ユーザーには見えない。**後から変更不可** |
| ユーザアクセス | `フルアクセス` | 個人開発ならこれでよい |

4. **作成** をクリック → アプリのダッシュボードが開く

---

## STEP 3. 「App 情報」タブの入力

左サイドバー **一般** → **App 情報**:

| 項目 | 入力値 | 補足 |
|------|--------|------|
| 名前 | `ShipIt English` | STEP 2 と同じ |
| サブタイトル | `エンジニアの技術英語を毎日5分で` | 30文字以内。検索にも影響 |
| カテゴリ（プライマリ） | `教育` | |
| カテゴリ（セカンダリ） | `仕事効率化` | 任意だが設定推奨 |
| コンテンツ配信権 | 「サードパーティのコンテンツを含みません」を選択 | カードは自作コンテンツのため |
| 年齢制限指定 | 「編集」から質問票に回答（下表） | |

### 年齢制限指定の質問票への回答（すべて「なし」）

| 質問 | 回答 |
|------|------|
| 漫画または空想上の暴力 | なし |
| 現実的な暴力 | なし |
| 露骨な性的表現またはヌード | なし |
| 冒とく的表現または下品なユーモア | なし |
| アルコール、タバコ、ドラッグの使用または言及 | なし |
| 成人向けまたはわいせつなテーマ | なし |
| 性的表現またはヌード | なし |
| ホラー/恐怖をあおるテーマ | なし |
| 賭博の模倣 | なし |
| 医療または治療に関する情報 | なし |
| 制限のないWebアクセス | いいえ |
| ギャンブルとコンテスト | いいえ |

→ 結果として **4+** になります。

---

## STEP 4. 「価格および配信状況」の設定

左サイドバー **一般** → **価格および配信状況**:

| 項目 | 入力値 |
|------|--------|
| 価格 | `0円（無料）` — 「価格表」から `JPY 0` を選択 |
| 配信可否 | すべての国と地域（デフォルトのまま）。日本のみにしたい場合は「編集」から日本だけチェック |
| App Store 配信 | ✅（デフォルト） |
| 事前注文 | オフのまま |

---

## STEP 5. 「App のプライバシー」の入力

左サイドバー **一般** → **App のプライバシー**。
本アプリは**通信を一切行わず、全データが端末内 SQLite / SharedPreferences に保存される**ため、申告は最も簡単なパターンです。

### 5-1. プライバシーポリシー URL（必須）

| 項目 | 入力値 |
|------|--------|
| プライバシーポリシー URL | 付録B の手順で公開した URL（例: `https://<あなたのID>.github.io/shipit-english-privacy/`） |
| プライバシーポリシーの連絡先情報（任意） | 空欄でよい |

### 5-2. データ収集の質問

1. 「開始」をクリック
2. **「このAppからデータを収集していますか？」→「いいえ、このAppからデータを収集していません」を選択**
3. 「公開」をクリック

→ ストアには「**データは収集されません**」と表示されます（ユーザーへの強いアピールポイントにもなる）。

> 将来クラウド同期や分析ツール（Firebase Analytics 等）を入れた場合は、このページの再申告が必須になります。

---

## STEP 6. ビルドのアップロード

### 6-1. アーカイブとアップロード（Xcode 経由・推奨）

```bash
flutter build ipa
```

が通ることを確認したうえで:

```bash
open ios/Runner.xcworkspace
```

1. Xcode 上部のデバイス選択を **Any iOS Device (arm64)** にする
2. メニュー **Product → Archive**
3. 完了後に開く Organizer で **Distribute App** → **App Store Connect** → **Upload**
4. オプションはすべてデフォルトのまま **Upload**

### 6-2. 処理待ち

- アップロード後、App Store Connect の **TestFlight** タブにビルドが現れるまで **10〜60分** かかる（「処理中」表示）
- 完了すると Apple からメールが届く

### 6-3. 輸出コンプライアンス

`ITSAppUsesNonExemptEncryption = false` を Info.plist に設定済みのため、**質問は表示されず自動で完了**します。もし表示された場合は:

- 「暗号化を使用していますか？」→ **いいえ**（本アプリは HTTPS 通信すら行わない）

---

## STEP 7. バージョン情報ページ（1.0 提出用）の入力

左サイドバー **iOS App** → **1.0 提出準備中** を開き、上から順に入力します。

### 7-1. スクリーンショット（必須）

| 枠 | サイズ | 必要枚数 |
|----|--------|---------|
| iPhone 6.9インチ（iPhone 16 Pro Max 等） | 1320 × 2868 px | 最低1枚・最大10枚（**3〜5枚推奨**） |
| iPhone 6.5インチ | 1284 × 2778 or 1242 × 2688 px | 6.9インチを流用可（自動スケール）。専用に用意しても良い |
| iPad | — | **不要**（`TARGETED_DEVICE_FAMILY = 1` の iPhone 専用ビルドに変更済み） |

**撮影方法**（シミュレータで撮るのが最も簡単）:

```bash
open -a Simulator
# iPhone 16 Pro Max を起動して
flutter run -d "iPhone 16 Pro Max" --release
# Simulator メニュー: File → Save Screen（Cmd+S）
```

**撮影する画面の推奨構成（この順で並べる）:**

1. ホーム画面（今日のセッション + ストリーク）
2. 学習画面・カード表面（フレーズ表示）
3. 学習画面・カード裏面（和訳 + 例文 + 使用場面）
4. セッション完了画面（統計）
5. カテゴリ一覧画面

### 7-2. プロモーションテキスト（任意・170文字以内）

```
コードレビュー・スタンドアップ・障害対応。海外テック企業の「現場で本当に使う」英語フレーズ1500枚を、科学的な間隔反復（SRS）で毎日5〜10分だけ。今日から英語でShip itしよう。
```

> プロモーションテキストは**審査なしでいつでも変更可能**な唯一の項目です。

### 7-3. 説明（必須・4000文字以内）

→ [付録A](#付録a-そのまま使える申請用テキスト) の説明文をそのまま貼り付け

### 7-4. キーワード（必須・100文字以内、カンマ区切り）

```
英語,エンジニア,技術英語,英会話,SRS,単語帳,フラッシュカード,海外就職,コードレビュー,IT英語
```

> アプリ名・サブタイトルに含まれる語（ShipIt, English など）はキーワードに入れない（重複は無駄になる）。

### 7-5. URL 類

| 項目 | 入力値 | 補足 |
|------|--------|------|
| サポート URL（必須） | GitHub リポジトリの URL、または GitHub Pages のページ | 問い合わせ先が分かるページであること。付録Bのプライバシーポリシーページに連絡先を書いて兼用してもよい |
| マーケティング URL（任意） | 空欄でよい | |

### 7-6. ビルド

1. 「ビルド」セクションの `+`（または「ビルドを選択」）をクリック
2. STEP 6 でアップロードしたビルド `1.0.0 (1)` を選択 → 完了

### 7-7. App Review に関する情報

| 項目 | 入力値 |
|------|--------|
| サインイン情報 | **「サインインが必要です」のチェックを外す**（本アプリはログイン不要のため） |
| 連絡先情報：名 / 姓 | 自分の氏名 |
| 電話番号 | 自分の電話番号（国番号付き: `+81 90XXXXXXXX`） |
| メールアドレス | 連絡のつくメールアドレス |
| メモ（任意） | 下記を貼り付け（英語推奨） |

**審査員向けメモ（コピペ用）:**

```
This is an offline flashcard app for Japanese software engineers learning
workplace English (code review, standup, incident response, etc.).
- No account or sign-in is required. All features are available immediately.
- All data is stored locally on the device (SQLite). No network communication.
- The app uses local notifications only (daily study reminder at a
  user-configurable time). Permission is requested in the Settings screen.
How to test: Tap "Start Learning" on the Home screen, tap a card to flip it,
then rate your recall with the three buttons (or swipe left/right).
```

| 項目 | 入力値 |
|------|--------|
| 添付ファイル（任意） | 不要 |

### 7-8. バージョンのリリース

3択から選択:

| 選択肢 | 推奨 |
|--------|------|
| **このバージョンを手動でリリースする** | ✅ **これを選ぶ**。承認後「配布ボタンを押すだけ」の状態で止まる（今回のゴールに一致） |
| 審査に合格後、このバージョンを自動的にリリースする | 承認と同時に即公開したい場合のみ |
| 日付を指定して自動リリース | 公開日を決めたい場合のみ |

### 7-9. 著作権

| 項目 | 入力値 |
|------|--------|
| 著作権 | `2026 <あなたの氏名>`（例: `2026 Kaito Murakami`） |

---

## STEP 8. 審査への提出

1. ページ右上の **「審査へ提出」**（青いボタン）をクリック
2. 未入力項目があると赤くエラー表示される → 該当項目を埋めて再度クリック
3. 提出が受理されるとステータスが **「審査待ち（Waiting for Review）」** に変わる

**→ ここまで到達すれば今回のゴール達成です。**

---

## STEP 9. 審査ステータスの見方と承認後の配布

| ステータス | 意味 | 所要時間の目安 |
|-----------|------|--------------|
| 審査待ち (Waiting for Review) | 審査キューに入った | 通常1〜2日 |
| 審査中 (In Review) | 審査員が確認中 | 数時間〜1日 |
| リジェクト (Rejected) | 差し戻し。Resolution Center に理由が届く | 修正して再提出（メタデータのみの修正なら再ビルド不要） |
| **配信準備完了 (Pending Developer Release)** | **承認済み。あとはボタンを押すだけ** | — |
| 配信中 (Ready for Sale) | App Store で公開中 | リリース後1〜24時間で検索に反映 |

### 承認後の配布手順（手動リリースを選んだ場合）

1. App Store Connect → 対象バージョンを開く
2. **「このバージョンをリリース」** ボタンをクリック
3. 数時間以内に App Store に公開される

---

## 付録A. そのまま使える申請用テキスト

### 説明文（4000文字以内・コピペ用）

```
■ 海外テック企業で「本当に使う」英語だけを学ぶ

ShipIt English は、日本のソフトウェアエンジニアが海外テック企業・外資系企業・
グローバルチームで働くために必要な「現場の技術英語」を習得するためのアプリです。

TOEIC用の単語帳には載っていない、でも毎日の業務で必ず使う——
そんなフレーズだけを厳選して収録しました。

「LGTM! Just a small nit.」
「Let's take this offline.」
「I'm blocked on the API review.」

これらが自然に出てくるようになることが、このアプリのゴールです。


■ 収録コンテンツ：14の実務シーン・1500フレーズ

・Code Review — コードレビューで使う表現（25枚）
・Git / CI/CD — ブランチ運用・デプロイの表現（20枚）
・Meetings / Standup — 会議・朝会の定番表現（20枚）
・Slack Communication — テキストコミュニケーション（20枚）
・Architecture / Design — 設計議論の表現（20枚）
・Incident Response — 障害対応の緊急表現（15枚）
・Tech Interview — 技術面接の受け答え（15枚）
・Sprint Planning — 見積もり・プランニングの表現（15枚）
・1on1 / Career — 評価面談・キャリア相談の表現（15枚）
・Remote / Async — リモート・非同期ワークの表現（15枚）
・Docs / Writing — ドキュメント作成の表現（15枚）

すべてのフレーズに、実際の業務シーンを想定した例文・和訳・
「どんな場面で使うか」の解説付き。


■ 科学的な間隔反復学習（SRS）

忘却曲線に基づいた SM-2 アルゴリズムを搭載。
「覚えてた」「曖昧」「忘れた」の3段階で自己評価するだけで、
あなたの記憶度に合わせて最適なタイミングで復習カードが出題されます。

・覚えているカードは出題間隔がどんどん伸びる
・忘れたカードはすぐに再出題される
・21日間隔まで到達したカードは「習得済み」に

毎日の学習は5〜10分。忙しいエンジニアでも続けられます。


■ 主な機能

・フリップカード式の学習UI（タップでめくる／スワイプで評価）
・ネイティブ発音の読み上げ（オフライン対応）
・毎日の学習セッション（復習カード＋新規カード）
・カテゴリを絞った集中学習（面接前に Tech Interview だけ、など）
・新規カード枚数のカスタマイズ（1日1〜20枚）
・学習ストリーク（連続学習日数）の記録
・カテゴリ別の習得進捗と全カードの閲覧
・毎日のリマインダー通知（時刻変更可能）
・ストリークが途切れそうな日だけ夜に届くお守り通知
・週間の学習グラフとカード検索
・English mode: 英語話者が日本の技術現場の日本語表現を学ぶモードも搭載


■ プライバシーファースト

・アカウント登録不要。ダウンロードしたらすぐ使えます
・学習データはすべて端末内に保存。外部への送信は一切ありません
・広告なし・トラッキングなし


海外で働くという選択肢を、英語のせいで諦めない。
今日から毎日5分、一緒に始めましょう。Ship it!
```

### 新機能（バージョンアップ時の「このバージョンの新機能」欄・コピペ用）

初回リリース（1.0）では以下でよい:

```
ShipIt English の初回リリースです。
・14カテゴリ・1500フレーズの技術英語カード
・SRS（間隔反復）による毎日の学習セッション
・学習ストリークとカテゴリ別進捗
・毎日のリマインダー通知
```

---

## 付録B. プライバシーポリシーのテンプレートと公開方法

### 公開方法（GitHub Pages が最速・無料）

1. GitHub に `shipit-english-privacy` という public リポジトリを作成
2. 下記内容で `index.md` を作成してコミット
3. リポジトリの Settings → Pages → Branch: `main` → Save
4. 数分後に `https://<あなたのID>.github.io/shipit-english-privacy/` で公開される
5. この URL を STEP 5-1 とサポート URL に設定する

### プライバシーポリシー本文（コピペ用）

```markdown
# ShipIt English プライバシーポリシー / Privacy Policy

最終更新日: 2026年7月19日

## 日本語

ShipIt English（以下「本アプリ」）は、ユーザーのプライバシーを尊重します。

### 収集する情報
本アプリは、個人情報を一切収集しません。

### データの保存
学習の進捗データ（カードの復習履歴・学習統計・設定）は、すべて
お使いの端末内にのみ保存されます。外部サーバーへの送信は行いません。

### 通知
本アプリは、学習リマインダーのためにローカル通知を使用します。
通知はお使いの端末内で完結し、外部サービスは使用しません。
通知は設定画面からいつでも無効にできます。

### 第三者への提供
本アプリはデータを収集しないため、第三者への提供もありません。
広告 SDK・アクセス解析ツールは使用していません。

### お問い合わせ
本ポリシーに関するお問い合わせ: <あなたのメールアドレス>

## English

ShipIt English ("the App") respects your privacy.

- The App does not collect any personal information.
- All learning data is stored locally on your device only and is never
  transmitted to external servers.
- The App uses local notifications for study reminders only.
- The App contains no ads, no analytics, and no third-party SDKs that
  collect data.

Contact: <your email address>
```

---

## 付録C. リジェクトされやすいポイントと対策

| ガイドライン | リスク | 本アプリでの対策状況 |
|-------------|--------|-------------------|
| 2.3.8 メタデータ | Flutter デフォルトアイコン | ✅ 対応済み（`assets/icon/app_icon.png` から生成、iOSアルファ除去済み） |
| 2.1 完成度 | クラッシュ・明らかなバグ | ✅ 実機動作確認済み。提出前に `flutter analyze` / `flutter test` を再実行 |
| 4.2 最小限の機能 | 「単なる単語リスト」と判断されるリスク | ✅ SRS・進捗管理・通知など機能十分。審査メモで機能を説明済み |
| 5.1.1 プライバシー | 収集データの申告漏れ | ✅ データ収集なしで申告（STEP 5） |
| 5.1.2 通知の許可 | 起動直後に理由なく通知許可を求める | ⚠️ 現状 `main.dart` で初回起動時に通知初期化を行う。iOS では設定画面のトグル操作時に許可ダイアログが出る実装のため問題なし |
| 4.0 デザイン | iPad レイアウトの崩れ | ✅ iPhone のみ対応（`TARGETED_DEVICE_FAMILY = 1`）に変更済みのため対象外 |

### リジェクトされた場合の対応フロー

1. App Store Connect 上部の **Resolution Center** に理由が届く
2. メタデータのみの問題（説明文・スクリーンショット等）→ 修正して「審査へ再提出」（再ビルド不要）
3. バイナリの問題 → 修正 → `pubspec.yaml` のビルド番号を +1（例: `1.0.0+2`）→ 再アーカイブ → 再アップロード → ビルドを選び直して再提出
4. 反論したい場合は Resolution Center から返信できる（英語）
