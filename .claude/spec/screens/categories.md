# Categories 画面（`/categories` タブ）

- ファイル：[categories_screen.dart](../../../lib/features/categories/presentation/categories_screen.dart) / [categories_providers.dart](../../../lib/features/categories/providers/categories_providers.dart) / [card_filter_bar.dart](../../../lib/features/categories/presentation/widgets/card_filter_bar.dart)
- 役割：14カテゴリの一覧と進捗表示。フィルタ時はカード一覧に切替。

## プロバイダー
- `categoriesProvider` → 各カテゴリの `{id, name, icon, description(_en), totalCount, studiedCount}`（`categoryDefs` ＋ DB集計）。
- `cardFilterProvider`（学習状況フィルタの状態）。フィルタ有効時は `filteredCardsProvider` に切替。
- `categoryDefs`（定数）：カテゴリ追加時はここにも追加必須。

## 構成
- AppBar：タイトル＋🔍（→`/search`）。
- `CardFilterBar`（学習状況＋カテゴリのチップフィルタ・機能はOR/AND据え置き）。見た目：`_Chip` は**未選択＝そのチップ色をごく薄く敷いた淡色ソフト（枠線なし）／選択＝ソリッド＋チェック＋グロー**（`AnimatedContainer`）。ヘッダーは tune アイコン（`primaryLight` 角丸ボックス）＋選択数バッジ＋クリア。セクションラベルは `monoLabel`。
- 未フィルタ：`_CategoryList`（カテゴリカード＝アイコン/名前/説明/`studiedOf(studied,total)`進捗）。タップ→`/category/:id`。
  - 無料プランでは Pro カテゴリにロック表示（`isProProvider`／休眠中は全開放）。
- フィルタ有効：`_FilteredCardList`（条件一致カードを `CardListTile` で。タップで `card_detail_sheet` 詳細/評価）。

## 注意
- カード評価はカード詳細シートから可能。評価すると `invalidateProgressProviders` により一覧も即更新。
