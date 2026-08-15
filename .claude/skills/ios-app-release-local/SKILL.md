---
name: ios-app-release-local
description: Project-local companion to the GLOBAL `ios-app-release` skill — holds ShipIt English's fixed App Store Connect facts (bundle id, ASC app id, signing team, privacy-manifest reasons, monetization state, device family). Use the global `ios-app-release` for the actual submit / upload / review procedure; look here only for THIS app's fixed values. This is not a procedure.
---

# ShipIt English — App Store 固有情報（グローバル `ios-app-release` の補完）

> **申請・ビルド・アップロード・審査提出などの手順はすべてグローバル Skill `ios-app-release` を使う。**
> このファイルは *ShipIt English 固有の確定値* だけを持つ companion（手順は書かない）。
> グローバル手順の各所（Bundle ID・Team・app id・価格・プライバシー等）に、下の値を当てはめて進める。
> リリース記録は毎回 `.claude/docs/release-log.md` に追記（グローバル必須ルール）。背景の詳細手順は
> `docs/app_store_free_release_checklist.md` / `docs/build_and_release.md`。

## このアプリの確定値
- **Bundle ID**: `jp.co.shipitenglish.app`（テスト: `jp.co.shipitenglish.app.RunnerTests`）。恒久。`com.example` に戻さない
- **App Store Connect app id**: `6799681201`
- **署名 Team**: `XX24WCN326`（Xcode 自動署名）
- **配信形態**: 無料（Free）／IAP なし／**App Privacy = Data Not Collected**（実行時ネットワーク非通信）
- **課金フラグ**: `MonetizationConfig.subscriptionEnabled = false`（有効化手順は `docs/subscription_setup_guide.md`）
- **バージョン同期**: `pubspec.yaml` の `version: X.Y.Z+N` と `AppConstants.appVersion`（設定フッター表示）を手動同期
- **端末対象**: iPhone 専用（`TARGETED_DEVICE_FAMILY = 1`）→ App Store の iPad スクショ不要
- **アイコン**: 1024px はアルファ無し（`pubspec.yaml` の `remove_alpha_ios: true`。差し替え時は `dart run flutter_launcher_icons`）
- **Export compliance**: `ios/Runner/Info.plist` に `ITSAppUsesNonExemptEncryption = false`
- **Privacy manifest**: `ios/Runner/PrivacyInfo.xcprivacy`（Runner の Resources に登録）。Required-Reason API: UserDefaults `CA92.1` / FileTimestamp `C617.1` / DiskSpace `E174.1` / SystemBootTime `35F9.1`。トラッキング無し・データ収集無し。新規プラグイン追加時は要見直し
- **Android applicationId**: `com.example.ship_it_english`（Google Play 配信時のみ修正。App Store には不要）

## 手順はここに置かない
申請前チェック・ビルド・アップロード（altool / ASC API）・メタデータ入力・提出フローは **グローバル `ios-app-release`** に従う。スクリーンショット撮影が必要な場合はグローバル `appstore-screenshots` を使う。
