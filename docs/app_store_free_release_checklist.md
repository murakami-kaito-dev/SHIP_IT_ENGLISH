# App Store 無料配布チェックリスト（ShipIt English）

課金なし（MVP）でApp Storeに出すための手順。Claude側で対応済みの項目と、
**あなた（開発者）がやる必要がある項目**を分けて記載する。
Claudeに「App Storeに出す準備をして」と言うと `app-store-release` スキルがこの内容で動く。

---

## ✅ Claude が対応済み（リポジトリ側の設定）

| 項目 | 状態 | 備考 |
|------|------|------|
| Bundle ID を実IDに変更 | ✅ `jp.co.shipitenglish.app` | `com.example.*` から変更。テストは `.RunnerTests` |
| 暗号化の輸出コンプライアンス申告 | ✅ 設定済 | `Info.plist` の `ITSAppUsesNonExemptEncryption = false`（毎回の質問を回避） |
| プライバシーマニフェスト | ✅ 新規作成 | `ios/Runner/PrivacyInfo.xcprivacy`（トラッキング無し／データ収集無し／Required Reason API 申告）。Xcodeプロジェクトのリソースにも登録済み。**無いと審査で ITMS-91053 警告が来やすい忘れがち項目** |
| アプリ表示名 | ✅ `ShipIt English` | `Ship It English` から統一 |
| アイコンのalpha除去 | ✅ 確認済 | 1024pxアイコンは alpha 無し（App Store必須） |
| iPhone専用 | ✅ | `TARGETED_DEVICE_FAMILY = 1`（iPadスクショ不要） |
| 課金の休眠 | ✅ | `MonetizationConfig.subscriptionEnabled = false`＝全機能無料・パウォール無し・IAP呼び出し無し・データ収集無し |
| バージョン | ✅ `1.0.0+1` | `pubspec.yaml` と `AppConstants.appVersion` 同期済 |

> ⚠️ **Bundle ID はApp Store Connectでアプリを作成すると永久に変更不可**。`jp.co.shipitenglish.app` で確定。

---

## 🔲 あなたがやる必要がある作業

### 1. 署名（Xcode）
- `open ios/Runner.xcworkspace` → Runner ▸ Signing & Capabilities
- Team = `XX24WCN326`、Automatically manage signing にチェック
- Apple Developer Program（有料・年99USD）に加入済みであること

### 2. Bundle ID の登録
- [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) で
  `jp.co.shipitenglish.app` を Identifier として登録（未登録ならApp Store Connectのドロップダウンに出ない）

### 3. ビルドしてアップロード
```bash
flutter build ipa
```
- 生成された `build/ios/archive/Runner.xcarchive` を Xcode Organizer で開く
  （または Xcode で Product ▸ Archive）
- Distribute App ▸ App Store Connect ▸ Upload
- ※ 2回目以降のアップロードは **必ずビルド番号を上げる**（`pubspec.yaml` の `+N`）

### 4. App Store Connect でアプリ情報を入力
[appstoreconnect.apple.com](https://appstoreconnect.apple.com) ▸ My Apps ▸ + ▸ New App

- **Bundle ID**: `jp.co.shipitenglish.app`
- **価格**: Free
- **App Privacy**: 「**Data Not Collected**（データを収集しない）」を選択
  - このアプリはネットワーク通信なし・ローカル完結なので、この申告とプライバシーマニフェストが一致する
- **スクリーンショット**: iPhone 6.7インチ + 6.5インチ（iPadは不要）
- **説明文 / キーワード / サポートURL**
- **プライバシーポリシーURL**（**必須**）… 無料でもURLが必要。GitHub Pages等でホスト可
- **年齢制限（Age Rating）** アンケートに回答
- アップロードしたビルドを選択 ▸ **Submit for Review**

### 5. プライバシーポリシーの用意
- データ収集なしでも「収集しない」旨を明記したページが必要。
- **作成済み**: `store/privacy_policy/index.html`（日英）。GitHub Pages 等にホストしてURLを取得。

---

## 📦 申請アセット一式は `store/` に格納

| パス | 中身 |
|------|------|
| `store/metadata/app_store_listing_ja.md` / `_en.md` | 掲載テキスト（名前・説明・キーワード・URL） |
| `store/metadata/app_privacy_and_rating.md` | プライバシー回答・年齢制限回答 |
| `store/privacy_policy/index.html` | プライバシーポリシー（日英・ホスト用） |
| `store/icon/app_store_icon_1024.png` | 1024マーケティングアイコン |
| `store/screenshots/capture.sh` + `README.md` | スクショ撮影スクリプト＋サイズ仕様 |

詳細は `store/README.md`（何をConnectのどこに入れるか）を参照。

---

## 補足

- **Android** の `applicationId` はまだ `com.example.ship_it_english`。
  Google Play に出す場合のみ変更が必要（App Store配布には無関係）。
- **後から課金化する場合**: `docs/subscription_setup_guide.md` の手順を実施し、
  `MonetizationConfig.subscriptionEnabled = true` にする。既存無料ユーザーへの配慮
  （急なロック回避）は、その段階で別途検討する。
- 詳細なビルド/署名手順は `docs/build_and_release.md`、Connectの全入力値は
  `docs/app_store_connect_submission.md` を参照。
