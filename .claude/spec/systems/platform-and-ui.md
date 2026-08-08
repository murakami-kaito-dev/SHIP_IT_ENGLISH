# System: i18n・テーマ・通知・ストリーク・バックアップ

## 多言語（[app_strings.dart](../../../lib/core/i18n/app_strings.dart)）
- `LanguageMode`（ja/en）。`AppStrings` に全UI文言を ja/en で定義、`stringsProvider` 経由で取得。
- **UI文言はハードコード禁止**。パラメータ付きは `mode` 分岐のメソッド（例 `cardsCount(n)`, `nextReviewIn(Duration)`, `monthDayLabel(d)`, `sessionHelpEntries()`）。
- 言語切替は `languageModeProvider.setMode`（`language_mode` に保存）。UIと学習対象言語の両方が切替。

## デザインシステム（[app_theme.dart](../../../lib/core/theme/app_theme.dart)）
- "Terminal-grade"（開発者ツール風）。**色/影/角丸/文字は `AppTheme.*` に集約**（ここを変えれば全画面波及）。
- インディゴ基調（primary #5B54E6）。CTA=`primaryGradient`+影、背景=`AppBackground`。
- 数値/タグは等幅 `monoFont`(Menlo)。**google_fonts不使用**（ネット非通信）。`withOpacity()` を使う（`withValues`不可）。
- 影のクリップ注意：`DecoratedBox(cardDecoration) > Material(transparent,clip) > InkWell` の順。
- 共通部品：`shared/widgets/`（gradient_button, app_background, card_list_tile, card_detail_sheet, progress_bar, card_number_label）。
- 全画面ルートは `AppBackground(child: Scaffold(...))` で包む（[navigation.md](../navigation.md)）。

## 通知（[notification_service.dart](../../../lib/core/services/notification_service.dart)）
- flutter_local_notifications + timezone。**`Asia/Tokyo` 固定**（`tz.setLocalLocation`。UTCずれ防止）。
- 毎日のリマインダー（既定08:00・設定変更可）＋ ストリーク危機通知（未学習日だけ23:00固定・メッセージ10種・設定不可）。
- 起動時に許可要求（`DarwinInitializationSettings` の requestPermission）。

## ストリーク（[streak_manager.dart](../../../lib/core/services/streak_manager.dart)）
- `streak_count` / `last_study_date`。学習完了で `recordStudyCompletion`（1日空きは継続、2日以上でリセット）。
- 表示は `StreakWidget`（[systems/gamification.md](gamification.md)）。当夜の危機通知は学習完了時にキャンセル。

## バックアップ/復元（[backup_service.dart](../../../lib/core/services/backup_service.dart)）
- 学習進捗をJSONで書き出し/読み込み（Settings のデータセクション）。`share_plus`/`file_picker`。
- **フォーマットを変えたら `_formatVersion` を上げる**（古いアプリが中途半端に読まないため）。

## レビュー依頼（[review_service.dart](../../../lib/core/services/review_service.dart)）
- `in_app_review`。ストリーク3日以上・過去未依頼のとき一度だけ（SessionComplete表示2秒後）。

## アプリアイコン
- マスター `assets/icon/app_icon.png`。差し替え後 `dart run flutter_launcher_icons`（iOS/Android再生成・iOSはalpha除去）。現行アイコンはターミナル風「> LGTM」。
