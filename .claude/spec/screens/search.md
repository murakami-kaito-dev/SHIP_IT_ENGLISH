# Search 画面（`/search`）

- ファイル：[search_screen.dart](../../../lib/features/search/presentation/search_screen.dart) / [search_providers.dart](../../../lib/features/search/providers/search_providers.dart)
- 役割：フレーズ・和訳・例文の部分一致検索。Categories タブの🔍から遷移。

## 構成
- AppBar：`TextField`（`searchHint`）。入力を `_query` に反映。
- `searchResultsProvider(_query)`（family）で結果取得。
  - 空クエリ→ヒント、0件→`searchEmpty`、結果→ `CardListTile` リスト。
- タップで `card_detail_sheet`（詳細/読み上げ/評価）。無料プランで Pro カテゴリのカードは `/paywall`。

## 注意
- 評価は詳細シートから。`invalidateProgressProviders` が `searchResultsProvider` も無効化するので結果表示も更新される。
