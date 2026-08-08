# System: 課金（ShipIt Pro・現在は休眠）

- コード：[core/monetization/](../../../lib/core/monetization/)（monetization_config / purchase_service / entitlement_provider）＋ [paywall_screen.dart](../../../lib/features/paywall/presentation/paywall_screen.dart)。
- 手順書：`docs/subscription_setup_guide.md`。

## マスタースイッチ
- `MonetizationConfig.subscriptionEnabled`（現在 **false**）。
  - false の間＝**全機能無料開放・パウォール導線なし・IAP呼び出しは即return・データ収集なし**（現行アプリの動作）。
  - true にすると：無料カテゴリ限定（`freeCategoryIds`=code_review/meetings/slack）、新規カード上限（`freeMaxNewCardsPerDay=5`）、カテゴリ集中学習のPro限定、`/paywall` 導線が有効化。

## Pro判定・境界
- **Pro判定は `isProProvider` 経由のみ**（休眠時は常にtrue）。無料/Proの線引きは `MonetizationConfig` だけで変更。
- 権利は `pro_entitlement`（bool）に保存。`entitlement_provider` が起動時/復帰時に **`verify()` で再検証**（解約/返金を反映して失効。`entitlementRecheckInterval`/`GracePeriod`/`entitlementVerifyTimeout`）。**`setPro(true)` で終わりにしない**。

## 商品・購入
- `productIds`：`shipit_pro_monthly` / `shipit_pro_yearly`（in_app_purchase）。
- `purchase_service`：`subscriptionEnabled=false` の間は全メソッドが no-op。有効時に buy/restore/商品取得。
- 管理/解約：`manageSubscriptionsUrl`。復元：Settings/Paywall から `restore()`。

## 有効化時の注意
- 無料配布→後から課金化すると既存ユーザーが急にロックされる体験になる。グランドファーザリング等は
  有効化時に別途検討（現状ロジックは未実装）。
