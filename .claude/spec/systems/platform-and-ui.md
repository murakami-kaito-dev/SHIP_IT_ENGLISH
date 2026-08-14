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
- flutter_local_notifications + timezone。**端末のローカルタイムゾーンで通知する**：`initialize()` で `flutter_timezone` の `getLocalTimezone()` から端末の IANA タイムゾーン（例 `Asia/Tokyo` / `America/Los_Angeles`）を取得し `tz.setLocalLocation` に設定（`tz.initializeTimeZones()` だけだと `tz.local` が UTC のままでずれるため）。取得失敗時のフォールバックのみ `Asia/Tokyo`。`main.dart` が起動ごとに再スケジュールするので端末のTZ変更にも追従する。
- 毎日のリマインダー（既定08:00・時刻変更可・`reminder_enabled`）＋ ストリーク危機通知（未学習日だけ23:00固定・時刻不可・メッセージ10種・`streak_reminder_enabled`）。**2つは独立にオン/オフできる**（[screens/settings.md](../screens/settings.md)）。**いずれも端末ローカル時刻**（8:00 は端末の朝8時、23:00 は端末の夜11時）。
- **オフにしたら必ず予約を取り消す**。`scheduleStreakReminders()` はフラグが false なら `cancelAllStreakReminders()` して return する。7日分を先に積む設計なので、消さないと切ったあとも最長7日鳴り続ける。
- `rescheduleAll({required studiedToday})` が「定時＋危機の再スケジュール ＋ 学習済みなら当日分キャンセル」をまとめる。起動時（`main.dart`）とOS許可の復帰時（`notificationPermissionProvider`）の両方がこれを呼ぶ。
- **OSの通知許可**：`isSystemNotificationEnabled()`（iOS `checkPermissions()` / Android `areNotificationsEnabled()`）。判定不能時は true（誤って警告を出さない）。状態は `notificationPermissionProvider` が保持し、`app.dart` の `resumed` で毎回更新する（許可はアプリ外で変えられるため）。拒否→許可に変わったら `rescheduleAll()` を呼ぶ（許可が無い間の `zonedSchedule` は例外を投げず黙って捨てられるため、組み直さないと復活しない）。
- 起動時に許可要求（`DarwinInitializationSettings` の requestPermission）。要求したことを `notif_permission_requested` に記録し、設定画面が「未決定」と「拒否済み」を区別できるようにする。**許可要求をオンボーディング後へ移す場合、この記録も一緒に移すこと。**

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
