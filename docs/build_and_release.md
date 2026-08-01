# ShipIt English — ビルド & リリース手順書

> このドキュメント1枚で「実機確認」→「App Store/Google Play 申請」まで完結します。

---

## 目次

1. [前提条件・環境確認](#1-前提条件環境確認)
2. [リリース前の必須設定変更](#2-リリース前の必須設定変更)
3. [iOS 実機ビルド](#3-ios-実機ビルド)
4. [App Store 申請](#4-app-store-申請)
5. [Android 実機ビルド](#5-android-実機ビルド)
6. [Google Play 申請](#6-google-play-申請)
7. [バージョン管理ルール](#7-バージョン管理ルール)
8. [トラブルシューティング](#8-トラブルシューティング)

---

## 1. 前提条件・環境確認

### 必要なツール

| ツール | 最低バージョン | 確認コマンド |
|--------|--------------|------------|
| Flutter | 3.24.x | `flutter --version` |
| Xcode | 15.0以上 | `xcode-select --version` |
| CocoaPods | 1.13以上 | `pod --version` |
| Android Studio | 2023.1以上 | — |
| Java (JDK) | 17以上 | `java -version` |

### 環境一括チェック

```bash
flutter doctor -v
```

全項目に ✓ がつくことを確認する。
`[!]` が残っている場合は、表示されるコマンドに従って解消する。

### 必要なアカウント

- **Apple Developer Program**: [https://developer.apple.com](https://developer.apple.com) (年額 $99)
- **Google Play Console**: [https://play.google.com/console](https://play.google.com/console) (初回 $25)

---

## 2. リリース前の必須設定変更

### 2-1. Bundle ID / Application ID を変更する

デフォルト値 (`com.example.*`) のままではストアに申請できない。
自分のドメインに合わせて変更すること。

#### iOS Bundle ID

`ios/Runner.xcodeproj/project.pbxproj` を直接編集するか、Xcode で変更する。

**Xcode で変更する方法（推奨）:**

```bash
open ios/Runner.xcworkspace
```

Xcode で `Runner` ターゲット → `Signing & Capabilities` タブを開き、
`Bundle Identifier` を `com.yourcompany.shipitEnglish` に変更する。

#### Android Application ID

`android/app/build.gradle` を開いて編集する：

```groovy
// 変更前
applicationId = "com.example.ship_it_english"

// 変更後（例）
applicationId = "com.yourcompany.shipitEnglish"
```

> **重要**: iOS と Android の ID は同じ値にする必要はないが、一貫性のために揃えることを推奨。

### 2-2. アプリ表示名を確認する

#### iOS

`ios/Runner/Info.plist` の `CFBundleDisplayName` を確認：

```xml
<key>CFBundleDisplayName</key>
<string>ShipIt English</string>
```

#### Android

`android/app/src/main/AndroidManifest.xml` の `android:label` を確認：

```xml
<application
    android:label="ShipIt English"
    ...>
```

### 2-3. バージョン番号を設定する

`pubspec.yaml` の `version` を更新する：

```yaml
# 書式: バージョン名+ビルド番号
version: 1.0.0+1
#        ↑     ↑
#        |     App Store/Google Play に送る内部ビルド番号（整数、毎回インクリメント）
#        ユーザーに見えるバージョン表示（例: 1.0.0）
```

> ビルド番号は申請のたびに必ずインクリメントすること。同じ番号は再申請不可。

---

## 3. iOS 実機ビルド

### 3-1. 事前準備（初回のみ）

#### Apple Developer で Identifier を登録

1. [developer.apple.com → Certificates, IDs & Profiles](https://developer.apple.com/account/resources/identifiers/list) にアクセス
2. `Identifiers` → `+` → `App IDs` を選択
3. `Bundle ID` に `com.yourcompany.shipitEnglish` を入力して登録

#### Provisioning Profile の設定

Xcode の `Automatic signing` を使えば自動で行われる（推奨）。

```
Xcode → Runner → Signing & Capabilities
  ✅ Automatically manage signing
  Team: [自分のチームを選択]
```

### 3-2. シミュレータで動作確認

実機不要で手軽に動作確認する場合はシミュレータを使う。

```bash
# 起動中のシミュレータ一覧を確認
flutter devices

# シミュレータを起動（Xcode が自動で立ち上がる）
open -a Simulator

# デフォルトのシミュレータで起動
flutter run

# デバイスを指定して起動（devices で確認した ID を使う）
flutter run -d "iPhone 16 Pro"

# リリースモードでシミュレータ起動（パフォーマンス確認用）
flutter run --release
```

> **注意**: シミュレータはローカル通知の動作確認が制限される場合がある。
> 通知のテストは実機で行うことを推奨。

### 3-3. 実機へのインストール

1. iPhone を Mac に USB 接続
2. iPhone でデバイスを信頼する（初回のみ）

```bash
# 接続中のデバイスを確認
flutter devices

# 実機にデバッグビルドでインストール
flutter run

# 実機にリリースビルドでインストール（本番に近い動作確認用）
flutter run --release
```

または Xcode から直接 Run ボタンで実行する。

### 3-4. Release ビルド生成（.ipa）

```bash
# IPA ファイルを生成（App Store 申請用）
flutter build ipa
```

生成物: `build/ios/ipa/ship_it_english.ipa`

---

## 4. App Store 申請

### 4-1. App Store Connect でアプリを登録

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) にログイン
2. `マイ App` → `+` → `新規 App`
3. 以下を入力して「作成」：

| 項目 | 入力値 |
|------|--------|
| プラットフォーム | iOS |
| 名前 | ShipIt English |
| 主要言語 | 日本語 |
| バンドル ID | com.yourcompany.shipitEnglish（2-1 で登録したもの） |
| SKU | shipitEnglish（任意の英数字、変更不可） |

### 4-2. ビルドをアップロードする

**方法A: Xcode から直接アップロード（推奨）**

```bash
# Xcode を開く
open ios/Runner.xcworkspace
```

Xcode のメニュー: `Product` → `Archive` → アーカイブ完了後 `Distribute App` → `App Store Connect` → `Upload`

**方法B: コマンドラインでアップロード**

```bash
# IPA を生成してアップロード
flutter build ipa
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/ship_it_english.ipa \
  --apiKey <API_KEY> \
  --apiIssuer <ISSUER_ID>
```

> API Key は [App Store Connect → ユーザーとアクセス → キー](https://appstoreconnect.apple.com/access/api) で発行。

### 4-3. App Store Connect でメタデータを入力

App Store Connect の `App 情報` と `App Store` タブで以下を入力する：

**必須項目:**

| 項目 | 内容 |
|------|------|
| スクリーンショット | iPhone 6.5" (1284×2778px) 以上、最低1枚 |
| アプリ名 | ShipIt English |
| サブタイトル | 海外テック英語を毎日5分で習得 |
| プロモーションテキスト | （任意） |
| 説明 | アプリの説明文（最大4000字） |
| キーワード | 英語学習,テック英語,SRS,海外就職,エンジニア |
| サポートURL | 自分のウェブサイトやGitHubのURL |
| カテゴリ | 教育 |
| 年齢制限 | 4+ |
| プライバシーポリシーURL | プライバシーポリシーページのURL（必須） |

**スクリーンショットのサイズ一覧:**

| デバイス | サイズ (px) | 必須 |
|---------|------------|------|
| iPhone 6.5" | 1284 × 2778 | ✅ 必須 |
| iPhone 5.5" | 1242 × 2208 | 任意 |
| iPad Pro 12.9" | 2048 × 2732 | iPad対応時のみ |

### 4-4. 通知権限の使用理由を記載する（必須）

このアプリはローカル通知を使用するため、App Store Connect の
`App プライバシー` → `データの種類` で通知について申告する。

`ios/Runner/Info.plist` に使用理由が記載されていることも確認：

```xml
<!-- 通知は Info.plist への記載は不要だが、以下があれば削除しない -->
<key>NSUserNotificationUsageDescription</key>
<string>毎日の学習リマインダーを送信するために通知を使用します。</string>
```

### 4-5. 申請して審査に提出

1. `ビルド` セクションで 4-2 でアップロードしたビルドを選択
2. `App の審査へ提出` をクリック
3. 審査質問に回答（暗号化の使用など）
4. `提出` をクリック

審査は通常 **1〜3営業日**。初回は長めにかかる場合がある。

---

## 5. Android 実機ビルド

### 5-1. 実機へのインストール

Android の設定で `開発者オプション` → `USBデバッグ` を有効にする。

```bash
# デバッグビルドで実機確認
flutter run

# リリースビルドで実機確認
flutter run --release
```

### 5-2. 署名キーストアの作成（初回のみ）

```bash
keytool -genkey -v \
  -keystore ~/keystore/shipit_english.keystore \
  -alias shipit_english \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

> ⚠️ **このキーストアファイルは絶対に紛失しないこと。**
> 失うと既存アプリの更新ができなくなる。Git にはコミットしないこと。

### 5-3. 署名設定をプロジェクトに追加

`android/key.properties` ファイルを新規作成（**Git に追加しない**）：

```properties
storePassword=<キーストア作成時のパスワード>
keyPassword=<キーのパスワード>
keyAlias=shipit_english
storeFile=/Users/<username>/keystore/shipit_english.keystore
```

`android/app/build.gradle` に署名設定を追加：

```groovy
// ファイル先頭付近に追加
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... 既存の設定 ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release  // debug から release に変更
        }
    }
}
```

### 5-4. Release APK / AAB の生成

```bash
# Google Play 用 AAB（推奨）
flutter build appbundle

# 直接配布用 APK
flutter build apk --release
```

| 生成物 | パス | 用途 |
|--------|------|------|
| AAB | `build/app/outputs/bundle/release/app-release.aab` | Google Play 申請 |
| APK | `build/app/outputs/flutter-apk/app-release.apk` | 直接インストール |

---

## 6. Google Play 申請

### 6-1. Google Play Console でアプリを作成

1. [play.google.com/console](https://play.google.com/console) にログイン
2. `アプリを作成` をクリック
3. 以下を入力：

| 項目 | 入力値 |
|------|--------|
| アプリ名 | ShipIt English |
| デフォルトの言語 | 日本語 |
| アプリまたはゲーム | アプリ |
| 無料または有料 | 無料 |

### 6-2. ストアの掲載情報を入力

`ストアでの表示` → `メインのストアの掲載情報`：

| 項目 | 内容 |
|------|------|
| 簡単な説明 | 海外テック企業で働くための英語をSRSで毎日5分習得（80字以内） |
| 詳細な説明 | アプリの詳細説明（最大4000字） |
| スクリーンショット | 2枚以上（電話: 1080×1920px 推奨） |
| アプリアイコン | 512×512px PNG |
| フィーチャーグラフィック | 1024×500px |
| カテゴリ | 教育 |

### 6-3. AAB をアップロード

1. `リリース` → `本番環境` → `新しいリリースを作成`
2. `App Bundle をアップロード` → `app-release.aab` を選択
3. リリースノートを入力（例: `初回リリース`）
4. `保存` → `確認` → `本番環境へのリリースを開始`

### 6-4. アプリのコンテンツを申告

`ポリシー` → `アプリのコンテンツ` で以下を申告：

- プライバシーポリシー URL（必須）
- 広告の有無: なし
- ターゲット層と利用内容: 18歳以上
- データセーフティ: ローカルデータのみ（クラウド同期なし）

審査は通常 **1〜7営業日**。

---

## 7. バージョン管理ルール

### バージョン番号の更新

```yaml
# pubspec.yaml
version: X.Y.Z+N
#        | | | |
#        | | | ビルド番号（毎回 +1）
#        | | パッチ（バグ修正）
#        | マイナー（機能追加）
#        メジャー（破壊的変更）
```

**更新コマンド（flutter_gen を使わない手動更新）:**

```bash
# pubspec.yaml の version 行を手動で編集してから:
flutter pub get
```

### リリース前チェックリスト

```
□ pubspec.yaml のバージョン番号をインクリメントした
□ Bundle ID / Application ID を com.example.* から変更した
□ flutter analyze でエラーが0件
□ flutter test で全テストがパス
□ 実機で動作確認済み
□ プライバシーポリシーページを用意した
□ スクリーンショットを撮影した
□ App Store / Play Console のメタデータを入力した
```

---

## 8. トラブルシューティング

### iOS: `No signing certificate` エラー

```bash
# キーチェーンとプロビジョニングをリセット
cd ios && rm -rf Pods Podfile.lock
pod install
```

Xcode で `Signing & Capabilities` を確認し、チームが選択されているか確認。

### iOS: `CocoaPods not installed`

```bash
sudo gem install cocoapods
cd ios && pod install
```

### Android: `Gradle build failed`

```bash
cd android && ./gradlew clean
flutter clean
flutter pub get
flutter build appbundle
```

### `flutter build ipa` が失敗する

```bash
# Xcode から Archive する方法を試す
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

### 通知が届かない（iOS）

- 設定アプリ → ShipIt English → 通知 → 許可されているか確認
- `notification_service.dart` の `requestPermission()` が呼ばれているか確認

### Android: `key.properties not found`

`android/key.properties` ファイルが存在するか確認。
Git の `.gitignore` に `key.properties` が含まれているため、新しい環境では手動で再作成が必要。

---

## 参考リンク

- [Flutter 公式: iOS デプロイ](https://docs.flutter.dev/deployment/ios)
- [Flutter 公式: Android デプロイ](https://docs.flutter.dev/deployment/android)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play ポリシーセンター](https://play.google.com/about/developer-content-policy/)
