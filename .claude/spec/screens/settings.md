# Settings 画面（`/settings` タブ）

- ファイル：[settings_screen.dart](../../../lib/features/settings/presentation/settings_screen.dart) / [settings_providers.dart](../../../lib/features/settings/providers/settings_providers.dart)
- 役割：言語モード・課金・通知・データ管理・アプリ情報。セクション分割の `ListView`。

## セクション（上→下）
1. **学習モード（言語）**：`SegmentedButton<LanguageMode>`（ja/en）＋モード説明。切替で `languageModeProvider.setMode` → UIと学習対象言語が切替。
1b. **学習：1日の新規学習カード数**（`sectionStudy`）：`NewCardsSetting`（見出し `newStudyCardsHeading`）。上部に3プリセット（**マイペース5／スタンダード10／スピード学習25**）、下部に **ダイヤルピッカー**（`CupertinoPicker`・1〜`AppConstants.maxNewCardsSetting`=100・1刻み）。両者は `settingsProvider.newCardsPerDay` を唯一の真実の源として**双方向連動**（プリセット押下→ピッカーが該当値へスクロール／ピッカー操作で 5・10・25 になると対応プリセットがアクティブ）。以前はホームにあったが設定タブへ移動。オンボーディングと同じ共通ウィジェット。
2. **ShipIt Pro**（休眠中は導線が実質無効/非表示になりうる）：
   - ステータス（Free/Active）。Free時「Proにアップグレード」→`/paywall`。
   - Pro時「サブスク管理」（`manageSubscriptionsUrl`）／「購入を復元」（`purchaseService.restore`）。
3. **通知**：毎日のリマインダー ON/OFF（Switch）・時刻（`reminder_hour/minute`）。権限が無ければ要求。
   - ストリーク危機通知（未学習日だけ23:00固定）は設定不可（自動）。
4. **データ**：バックアップ書き出し／読み込み（[systems/platform-and-ui.md](../systems/platform-and-ui.md) の BackupService）・学習データリセット（確認ダイアログ）。
5. **フッター**：アプリバージョン（`AppConstants.appVersion`。pubspecと手動同期）。

## 注意
- 新規カード数の設定は Settings ではなく **Home の「今日のセッション」内**にある。
- Pro判定・境界は `isProProvider` / `MonetizationConfig` のみ（[systems/monetization.md](../systems/monetization.md)）。
