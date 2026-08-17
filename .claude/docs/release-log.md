# リリースログ（ShipIt English）

バージョン・ビルド番号が動いたら**その場で**先頭に追記する。
「ビルドしただけ」と「配信した」は git から判別できないため、必ず区別して書く。

- bundle id: `jp.co.shipitenglish.app` / App Store Connect app id: `6799681201`
- ビルド番号は**単調増加**。失敗した番号も再利用しない。

---

## 1.0.0 (build 8) — 2026-08-17 · TestFlight

**build 7 以降の全変更をまとめて配信**（build 7 は 8/14。以降 20コミット分が未配信だった）。

- マスコット「ダッキー」🦆 追加＋ランク進化／**アプリアイコンをアヒルに刷新**
- デイリークエスト＋宝箱／マイルストーンバッジ18種／パーフェクトセッションボーナス
- ユニット制＋卒業テスト／出題形式の多様化（4択・音声・穴埋め）／技術英語カバレッジ＋初期診断
- iOSホーム画面ウィジェット（🔥ストリーク・今日の進捗）
- 称号の再設計（閾値 5/10/16/24/34/50・英語表記）／デザイン刷新（Soft Arcade Warm）Phase 1〜2b
- レベルアップ演出を学習中に出さず完了画面へ集約／リセット後に学習不能になる不具合修正

**ビルドに必要だった修正**（このビルドで初めて発覚）:
- `ios/Runner.xcodeproj/project.pbxproj` のプロジェクト全体 Debug/Release にあった
  `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon;` の2行を削除。
  **真偽値(YES/NO)の設定キーに `AppIcon` を代入**しており（正しくは `ASSETCATALOG_COMPILER_APPICON_NAME`）、
  `actool` が異常終了して `CompileAssetCatalogVariant failed` になっていた。
  8/15 のウィジェット追加時に混入。**build 8 以降は誰もビルドできない状態だった**。

**配信**: TestFlight にアップロード済み（Delivery UUID: `9273bf28-20e7-4903-8164-bf399d434b02`）
**状態**: 審査未提出（審査中の v1.0 は build 4 に紐づいたままで、本ビルドは影響しない）
**検証**: `flutter analyze` エラー0 / `flutter test` 110件パス
**警告**: altool 90068（MinimumOSVersion 13.0）

### 署名まわりの記録（次回同じ所で詰まらないために）

ウィジェット追加により **2つ目のバンドルID `jp.co.shipitenglish.app.widget`** と
**App Group `group.jp.co.shipitenglish.app`** が入り、`flutter build ipa` の書き出しが
`No profiles` / `doesn't include the App Groups capability` で失敗した。

- `-allowProvisioningUpdates` ＋ ASC APIキー認証（`-authenticationKeyPath` 等）は
  **`Cloud signing permission error` で不可**（Xcodeのクラウド署名はAPIキーの権限では通らなかった）
- **解決策＝プロファイルをASC APIで自前作成し、手動署名で書き出す**：
  1. `POST /v1/profiles`（`IOS_APP_STORE`）を**本体とウィジェットの2つ**作成
     （bundleId `95T7TG74N7` / `83H48V5CS7`、証明書 `S9HFN4J4U4`＝ローカルの
     `Apple Distribution: Kaito Murakami (XX24WCN326)` と有効期限で一致）
  2. `profileContent` を base64 デコードして
     `~/Library/MobileDevice/Provisioning Profiles/<uuid>.mobileprovision` に配置
  3. `signingStyle: manual` ＋ `provisioningProfiles` にバンドルID→プロファイル名を
     マッピングした ExportOptions.plist で `xcodebuild -exportArchive`
- `APP_GROUPS` capability は両バンドルIDとも**既に有効**だったため、追加設定は不要だった
- 作成したプロファイル: `ShipIt English AppStore` / `ShipIt English Widget AppStore`

---

## 1.0.0 (build 7) — 2026-08-14 · TestFlight

学習画面の2本のゲージを作り直した。

- **XPゲージが溜まって見えるようになった（不具合修正）**。`FractionallySizedBox` に `widthFactor` しか指定しておらず、塗りが**高さ0に潰れて1pxも描画されていなかった**。171/180（95%）でもバーが真っ白のままだった
- **上下2本のバーが何を表すか分かるようにした**。セッション進捗を AppBar 直下の**全幅4pxヘアライン**（線）に、XPを**カード上の部品**（面）に変え、形で区別できるようにした。従来は同じ形の横棒が6px間隔で並び、下のバーは AppBar の数字と情報が完全に重複していた
- **数字に単位を付けた**：`9 / 15枚`、`144 / 180 XP`。あわせて「のこり◯枚」を表示
- **「あと◯XPでLV◯」を常時表示**。85%を超えると枠が強調され「あと◯XP!」に切り替わる
- **獲得XPがバーへ吸い込まれる演出**を追加（`XpFlyToBar`）。正解→XP→ゲージが伸びる、の因果が見えるようにした
- 25%ごとの刻み目を追加し、1回分（+12XP程度）の増加も目で分かるようにした
- FEVER中は炎色＋`×1.5`、コンボ中は `🔥 コンボN` をバー上に表示

**配信**: TestFlight にアップロード済み（Delivery UUID: `dffe0d4a-a6ca-45c8-9e88-35a8786137dd`）
**状態**: このビルド自体は審査未提出（v1.0 の審査は 2026-08-10 に **build 4** で提出済み・`WAITING_FOR_REVIEW`。以降のビルドは審査対象に紐づいていない）
**検証**: `flutter analyze` エラー0 / `flutter test` 55件パス（`xp_progress_bar_test.dart` を新設し「塗りの高さ > 0」を恒久ガード）／シミュレータで実描画を確認
**警告**: altool 90068（MinimumOSVersion 13.0。2027年春以降は15.0以上が必須。現時点では受理される）
**確認してほしいこと**: 学習画面でカードを数枚めくり、**XPバーが実際に伸びるか**

---

## 1.0.0 (build 6) — 2026-08-14 · TestFlight

設定画面の時刻選択と通知セクションの見せ方を変更。

- **通知時刻の選び方をホイール式に変更**。Materialのアナログ文字盤（24時間制で数字が内周・外周に二重に並ぶ）をやめ、時・分を縦に回すピッカーにした
- **「通知時刻」がリマインダーのトグルに連動して開閉するようになった**。オフだと畳まれて消え、オンで現れる。左インデントと縦のつなぎ線で従属関係を示す

**配信**: TestFlight にアップロード済み（Delivery UUID: `2472ba66-9215-41d5-8c1a-bb7986e48e86`）
**状態**: このビルド自体は審査未提出（v1.0 の審査は 2026-08-10 に **build 4** で提出済み・`WAITING_FOR_REVIEW`。以降のビルドは審査対象に紐づいていない）
**検証**: `flutter analyze` エラー0 / `flutter test` 48件パス／シミュレータで実描画を確認
**警告**: altool 90068（MinimumOSVersion 13.0）

---

## 1.0.0 (build 5) — 2026-08-14 · TestFlight

通知の「オフにしたのに鳴る」を解消。

- **通知設定のトグルが2本になった**：「毎日のリマインダー」と「ストリークが途切れそうな日」を独立して切り替えられる
- **アプリ内でストリーク通知をオフにすると本当に鳴らなくなった（不具合修正）**。従来は7日分の予約をOSに積んだまま消していなかったため、オフにしても最長7日間 23:00 の通知が鳴り続けていた（`cancelAllStreakReminders()` はコード中どこからも呼ばれていなかった）
- **iOSの設定で通知を切っている間は、その旨を明示するようになった**：警告バナーと「設定を開く」ボタンを出し、トグルは非活性にする。以前は「オン」と表示されているのに1通も届かなかった
- **通知を一度拒否したあとの行き止まりを解消**：iOSは一度拒否すると許可ダイアログを二度と出さないため、設定アプリへの導線を出すようにした
- フォアグラウンド復帰のたびにOSの許可状態を読み直し、拒否→許可に変わったら予約を組み直す（`rescheduleAll()`）

**配信**: TestFlight にアップロード済み（Delivery UUID: `f5661b10-8b8c-4bda-952c-01a2d822283f`。処理完了・`VALID`）
**状態**: このビルド自体は審査未提出（v1.0 の審査は 2026-08-10 に **build 4** で提出済み・`WAITING_FOR_REVIEW`。以降のビルドは審査対象に紐づいていない）
**検証**: `flutter analyze` エラー0 / `flutter test` 48件パス
**警告**: altool 90068（MinimumOSVersion 13.0）
**メモ**: この時点でこのアプリにはベータグループが1つも無く、`READY_FOR_BETA_TESTING` でも TestFlight アプリに現れない状態だった（build 2〜4 も同様）。グループ作成後に配信されるようになった

---

## 1.0.0 (build 4) — 2026-08-10 · App Store 審査提出（審査中）

- iOS13対応・全文音声マーク版の申請用（コミット `7b86d8c`）

**配信**: App Store Connect にアップロード済み（`VALID`）
**状態**: **v1.0 の審査に紐づいているのはこのビルド**。2026-08-10 に提出し `WAITING_FOR_REVIEW` のまま（8/17 時点で1週間経過）。提出アイテムは `READY_FOR_REVIEW` で不備なし＝Apple側のキュー待ち

---

## 1.0.0 (build 3) — 日付不明 · 配信不明（git から復元）

- 最新変更の再申請用（コミット `bf59d20`）

**配信**: 不明（git から復元。App Store Connect 上では `VALID`・minOS 12.0）
**状態**: 不明
