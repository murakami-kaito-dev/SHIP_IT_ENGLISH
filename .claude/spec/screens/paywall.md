# Paywall 画面（`/paywall`）

- ファイル：[paywall_screen.dart](../../../lib/features/paywall/presentation/paywall_screen.dart)
- 役割：ShipIt Pro の購入導線。**現在は課金休眠中**（`MonetizationConfig.subscriptionEnabled=false`）のため通常は到達しない。詳細は [systems/monetization.md](../systems/monetization.md)。

## 構成
- タイトル「ShipIt Pro」＋サブタイトル（機能解放の訴求）。
- 機能リスト（全カテゴリ・新規無制限・カテゴリ集中学習 等）。
- `_PlanCard`：月額/年額（`monthlyPlan`/`yearlyPlan`・トライアル注記）。`purchaseServiceProvider` の商品情報から表示。
- 購入：`purchaseService.buy(product)`／復元：`purchaseService.restore()`。
- 文言は画面内 `_PaywallStrings`（ja/en）に集約。

## 注意
- 休眠中は `purchase_service` の各メソッドが即returnし、Settings/カテゴリからの導線も出さない設計。
- 有効化は `docs/subscription_setup_guide.md` ＋ `subscriptionEnabled=true`。
