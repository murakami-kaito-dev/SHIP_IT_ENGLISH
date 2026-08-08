# CategoryDetail 画面（`/category/:id`）

- ファイル：[category_detail_screen.dart](../../../lib/features/categories/presentation/category_detail_screen.dart)
- 役割：1カテゴリ内のカード一覧＋詳細、そこからの学習開始。

## 入力
- パス `:id`＝カテゴリID。`categoryCardsProvider(categoryId)` でカード一覧（学習状況チップ付き）。
- `categoryDefs` から `{icon, name}` を引いて AppBar タイトルに。

## 構成
- 無料プランで Pro カテゴリなら**ロック画面**（`proLockedCategory` ＋「Proにアップグレード」→`/paywall`）。
- 一覧：`CardListTile`（番号・フレーズ・状況）。タップ→ `card_detail_sheet`（訳/例文/使用場面/読み上げ/その場で評価）。
- 下部 CTA「このカテゴリを学習」`studyThisCategory`：
  - Pro/無料でOK → 範囲指定シート（`showRangeStudySheet(fixedCategoryId: id)`）。
  - ロック時 → `/paywall`。

## 注意
- 詳細シートで評価すると裏の一覧も即更新（`invalidateProgressProviders` が family も無効化）。
- 範囲指定シートは [screens/study.md](study.md) のカテゴリ学習モードへ繋がる。
