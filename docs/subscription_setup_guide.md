# ShipIt Pro — サブスクリプション有効化ガイド

> コード実装は**完成済み・無効化状態**でリポジトリに入っている。
> このドキュメントは「有効化を決めた日」に上から順に実行するための手順書。
> コード側のスイッチは1箇所だけ（下記 STEP 5）。

最終更新: 2026-07-20

---

## 全体像

| 項目 | 内容 |
|------|------|
| モデル | フリーミアム（自動更新サブスクリプション2種） |
| 無料 | SRS学習・ストリーク・通知・TTS・検索・3カテゴリ（Code Review / Meetings / Slack = 65枚）・新規5枚/日 |
| Pro | 全11カテゴリ（Pro側130枚: 面接・障害対応・キャリア・リモート等）・新規最大20枚/日・カテゴリ集中学習・今後の機能 |

> **有効化の判断（2026-07-20時点）**: コンテンツは195枚まで拡充済みでPro側の価値は十分に
> 立ち上がった。**コード側は即日有効化できる状態**だが、下記 STEP 1〜2・6（有料App契約・
> 商品登録・Sandboxテスト）は開発者アカウントでの手作業が必須のため、それらの完了を待って
> フラグを ON にすること。**商品未登録のままフラグをONにするとパウォールが機能せず
> ロックカテゴリに一切アクセスできなくなる**（絶対にやらないこと）。
| 商品 | 月額 `shipit_pro_monthly`（¥600）/ 年額 `shipit_pro_yearly`（¥4,800・7日間無料トライアル付き） |
| 実装 | 公式 `in_app_purchase` プラグイン（StoreKit 2）。外部サーバー・第三者SDKなし → 「データ収集なし」申告を維持 |
| 復習カードの扱い | 無料化後も**過去に学習開始したカードの復習は制限しない**（既存ユーザーの進捗を壊さない設計） |

### コード側の構成（参考）

| ファイル | 役割 |
|---------|------|
| `lib/core/monetization/monetization_config.dart` | **マスタースイッチ** / 無料枠定義 / プロダクトID / リンクURL |
| `lib/core/monetization/entitlement_provider.dart` | `isProProvider`（スイッチOFF時は常にtrue=全開放） |
| `lib/core/monetization/purchase_service.dart` | 購入・復元・トランザクション処理 |
| `lib/features/paywall/presentation/paywall_screen.dart` | パウォール（/paywall、日英対応） |
| ゲート箇所 | カテゴリ一覧（ロック表示）/ カテゴリ詳細（直リンクガード+集中学習ボタン）/ 設定スライダー / 新規カード出題フィルタ |

---

## STEP 1. 有料App契約の締結（初回のみ・審査前に必須）

1. [App Store Connect](https://appstoreconnect.apple.com) → **契約 / 税金 / 口座情報**（Business）
2. **有料 App 契約（Paid Applications Agreement）** の「規約に同意」
3. 以下を登録（すべて完了しないとサブスク商品が「送信準備完了」にならない）:
   - 銀行口座情報（振込先）
   - 税務情報（日本の場合 W-8BEN 相当のフォームに回答）
   - 連絡先情報
4. ステータスが「有効(Active)」になるまで待つ（数時間〜数日）

---

## STEP 2. サブスクリプショングループと商品の作成

### 2-1. グループ作成

1. App Store Connect → マイApp → ShipIt English → サイドバー **収益化 → サブスクリプション**
2. **サブスクリプショングループを作成**:

| 項目 | 入力値 |
|------|--------|
| 参照名 | `ShipIt Pro` |
| グループ表示名（日本語） | `ShipIt Pro` |

### 2-2. 月額プラン

グループ内で「サブスクリプションを作成」:

| 項目 | 入力値 |
|------|--------|
| 参照名 | `Pro Monthly` |
| 製品ID | `shipit_pro_monthly` ← **コードの `MonetizationConfig.monthlyProductId` と完全一致必須** |
| サブスクリプション期間 | 1ヶ月 |
| 価格 | ¥600（価格ポイントから選択） |
| ローカリゼーション（日本語） | 表示名: `Pro 月額プラン` / 説明: `全カテゴリと全機能が使い放題` |
| ローカリゼーション（英語） | 表示名: `Pro Monthly` / 説明: `Unlock all categories and features` |
| 審査用スクリーンショット | パウォール画面のスクショ（1284×2778px 等）をアップロード |

### 2-3. 年額プラン

| 項目 | 入力値 |
|------|--------|
| 参照名 | `Pro Yearly` |
| 製品ID | `shipit_pro_yearly` ← コードと完全一致必須 |
| サブスクリプション期間 | 1年 |
| 価格 | ¥4,800 |
| ローカリゼーション | 月額と同様（表示名: `Pro 年額プラン` / `Pro Yearly`） |
| 審査用スクリーンショット | 同上 |

### 2-4. 年額プランに無料トライアルを付ける

1. 年額プランを開く → **サブスクリプションの価格** → `+` → **お試しオファーを作成**（Introductory Offer）
2. 設定:

| 項目 | 入力値 |
|------|--------|
| 国と地域 | すべて |
| 開始日〜終了日 | 開始日=今日 / 終了日=なし |
| オファータイプ | **無料** |
| 期間 | **1週間** |

> パウォールの「7日間の無料トライアル付き」表記はこの設定と対応している。
> トライアルを付けない場合はパウォールの `trialNote` を削除すること。

---

## STEP 3. App のプライバシー・審査情報の確認

- **プライバシー申告は変更不要**。購入処理は Apple の StoreKit がすべて処理し、アプリ・開発者側はデータを収集・送信しない（外部サーバー・分析SDKなし）ため、「データは収集されません」のままでよい
- バージョン提出時、**初回のみ「App内課金」セクションで作成した2商品をバージョンに添付**する（バージョンページの「App内課金とサブスクリプション」欄）
- 審査員向けメモに追記推奨:

```
This version adds an auto-renewable subscription "ShipIt Pro"
(monthly / yearly with 7-day free trial on yearly).
Free tier: 3 categories (65 cards), 5 new cards/day. Pro: all 11
categories (195 cards), up to 20 new cards/day, category-focused study.
The paywall is reachable from: a locked category on the Categories tab,
the Settings screen ("ShipIt Pro" row), or the new-cards slider.
Purchases use StoreKit only; no account is required.
```

---

## STEP 4. パウォールのガイドライン要件チェック（実装済みだが最終確認）

App Store Review Guideline 3.1 関連。パウォール画面（`paywall_screen.dart`）は以下を満たしている:

- [x] 価格と期間の明示（ストアから取得したローカライズ済み価格を表示）
- [x] 「購入を復元」ボタン（**必須**。無いとリジェクト）
- [x] 利用規約（Apple標準EULA）とプライバシーポリシーへのリンク
- [x] 自動更新の説明文（解約方法への言及）
- [x] 機能・コンテンツの内容説明

**手動確認が必要なもの:**

- [ ] `MonetizationConfig.privacyPolicyUrl` を実際に公開しているURLへ差し替えたか（現在プレースホルダー）

---

## STEP 5. コード側の有効化（これだけ）

[monetization_config.dart](../lib/core/monetization/monetization_config.dart) の1行を変更する:

```dart
// 変更前（現在 = 全機能無料）
static const bool subscriptionEnabled = false;

// 変更後（課金導線・機能制限が全て有効になる）
static const bool subscriptionEnabled = true;
```

これだけで以下がすべて有効になる（他のコード変更は不要）:

1. カテゴリ一覧: Pro限定4カテゴリ（Git/CI/CD・Architecture・Incident・Interview）に🔒表示、タップでパウォール
2. カテゴリ詳細: 直リンクしてもロック画面。集中学習ボタンがPro限定に
3. 設定: 「ShipIt Pro」セクション出現。新規カードスライダーが5枚超でパウォール誘導
4. 学習セッション: 無料ユーザーの新規カードは無料カテゴリのみ・5枚/日上限
5. 起動時に StoreKit のトランザクション購読開始

**あわせて行うこと:**

- [ ] `privacyPolicyUrl` の差し替え（STEP 4）
- [ ] `pubspec.yaml` の version を上げる（例: `1.1.0+2`）+ `AppConstants.appVersion` も同期
- [ ] `flutter analyze` / `flutter test` がクリーンなことを確認

---

## STEP 6. Sandbox テスト（提出前に必ず実機で）

> **重要**: 下の「6-2. 失効・管理・復元のテスト」は、2026-07-20 に追加した
> 権利検証まわりの動作確認です。**課金の要**なので必ず通してください。

1. App Store Connect → **ユーザとアクセス → Sandbox → テスター** → `+` でテスト用 Apple ID を作成（本物のメールでなくてよいが未使用のアドレスであること）
2. **実機**の 設定 → App Store → サンドボックスアカウント にそのIDでサインイン（シミュレータでは購入テスト不可）
3. `flutter run --release` で実機起動
4. テスト項目:

### 6-1. 購入フローのテスト

```
□ ロックカテゴリのタップでパウォールが開く
□ パウォールに2プランと価格が表示される（表示されない=商品IDの不一致 or 契約未完了）
□ 年額プランを購入 → 「ShipIt Pro へようこそ！」→ 全カテゴリが解放される
□ 設定画面の表示が「Pro（有効）」になる
```

### 6-2. 失効・管理・復元のテスト（**必須**）

Sandbox では自動更新が高速化される（1年→1時間、1ヶ月→5分 など）ため、
短時間で解約・失効の挙動を確認できます。

```
□ 【復元】アプリを削除→再インストール→設定の「購入を復元」で Pro が復活する
   ※パウォールを開かなくても設定から復元できることを確認（再インストール直後は
     全カテゴリがロックされているため、ここが唯一の復元導線になる）

□ 【管理】Pro状態で 設定 → 「サブスクリプションを管理」をタップ
   → App Store のサブスクリプション画面が開く
   ※これが無いと審査ガイドライン 3.1.2 でリジェクトされる可能性がある

□ 【失効】App Store の管理画面で解約 → Sandboxの更新期限が切れるまで待つ
   → アプリに戻る（フォアグラウンド復帰）
   → 自動的に Pro が解除され、Pro限定カテゴリが再びロックされる
   ※すぐ反映されない場合は §失効判定の仕様 の「再検証の間隔」を確認

□ 【オフライン】機内モードでアプリを起動しても Pro が即座に剥奪されないこと
   （猶予期間7日以内なら維持されるのが正しい挙動）
```

### 失効判定の仕様（実装の中身）

`in_app_purchase` には「現在有効な権利」を直接返すAPIが無いため、以下の方式で判定しています。

| 項目 | 値 | 変更場所 |
|------|----|---------|
| 判定方法 | `restorePurchases()` を実行し、対象商品が `restored` として返るか | `PurchaseService.verifyEntitlement()` |
| 検証タイミング | アプリ起動時 + フォアグラウンド復帰時 | `app.dart` の `didChangeAppLifecycleState` |
| 再検証の間隔 | 12時間（毎回問い合わせない） | `MonetizationConfig.entitlementRecheckInterval` |
| 復元の待ち時間 | 10秒 | `MonetizationConfig.entitlementVerifyTimeout` |
| 猶予期間 | 7日（オフラインで判定不能な間は維持） | `MonetizationConfig.entitlementGracePeriod` |

- **有効と確認できた** → Pro維持・検証時刻を更新
- **ストアに繋がったが権利なし** → **即座に失効**（解約・返金の反映）
- **ストアに繋がらない** → 猶予期間内は維持、超えたら失効

> より厳密にやるなら StoreKit 2 の `Transaction.currentEntitlements` を
> ネイティブ側で読むか、RevenueCat の導入を検討してください。ただし
> RevenueCat は第三者SDKなので「データ収集なし」申告の見直しが必要です。

---

## STEP 7. 提出・リリース

1. アーカイブ → アップロード（`docs/app_store_connect_submission.md` STEP 6 と同じ）
2. バージョンページで **App内課金2商品を添付**（STEP 3）
3. 審査へ提出（アプリ本体とIAPが同時に審査される）
4. 承認後リリース

---

## 運用上の注意

- **既存無料ユーザーの扱い**: 復習カードは全カテゴリで無制限のまま（実装済みの設計）。有効化前に学習を始めたユーザーの進捗は失われないが、Pro限定カテゴリの「新規」カードは出題されなくなる。App Store の「このバージョンの新機能」で正直に告知すること
- **価格変更**: App Store Connect 上で変更可能。既存購読者は「価格上昇の同意フロー」が走る（値下げは自動適用）
- **解約率・売上の確認**: App Store Connect → 傾向（Trends）/ 収益化レポート
- **返金・解約**: Apple が処理する。アプリ側は起動時／フォアグラウンド復帰時の再検証で自動的に Pro を解除する（最大12時間・オフライン時は最大7日のラグがある）
- **Android（Google Play）対応時**: `in_app_purchase` はそのまま動くが、Play Console 側で定期購入商品（同じプロダクトID推奨）の登録が別途必要

## トラブルシューティング

| 症状 | 原因 |
|------|------|
| パウォールに商品が出ない | 製品IDの不一致 / 有料App契約が未完了 / 商品メタデータ不足（スクショ未添付等）/ 作成直後（反映に数時間かかることがある） |
| 「ストアに接続できませんでした」 | シミュレータで実行している / Sandboxアカウント未サインイン |
| 購入しても解放されない | purchaseStream が purchased を返しているか debugPrint で確認。`completePurchase` 漏れはキュー詰まりの原因（実装済み） |
| 審査リジェクト 3.1.2 | パウォールの価格・期間・復元・規約リンクの欠落（本実装は対応済み。文言を変更した場合は再確認） |
| 解約したのに Pro のまま | 再検証は12時間間隔。すぐ試すなら アプリ削除→再インストール、または `entitlementRecheckInterval` を一時的に短くしてビルド |
| オフラインで Pro が消えた | 猶予期間（7日）を超えている。`entitlementGracePeriod` で調整可能 |
