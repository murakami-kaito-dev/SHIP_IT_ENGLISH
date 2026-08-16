# Settings 画面（`/settings` タブ）

- ファイル：[settings_screen.dart](../../../lib/features/settings/presentation/settings_screen.dart) / [settings_providers.dart](../../../lib/features/settings/providers/settings_providers.dart)
- 役割：言語モード・課金・通知・データ管理・アプリ情報。セクション分割の `ListView`。

## セクション（上→下）
1. **学習モード（言語）**：`SegmentedButton<LanguageMode>`（ja/en）＋モード説明。切替で `languageModeProvider.setMode` → UIと学習対象言語が切替。
1b. **学習：1日の新規学習カード数**（`sectionStudy`）：`NewCardsSetting`（見出し `newStudyCardsHeading`）。上部に3プリセット（**マイペース5／スタンダード10／スピード学習25**）、下部に **ダイヤルピッカー**（`CupertinoPicker`・1〜`AppConstants.maxNewCardsSetting`=100・1刻み）。両者は `settingsProvider.newCardsPerDay` を唯一の真実の源として**双方向連動**（プリセット押下→ピッカーが該当値へスクロール／ピッカー操作で 5・10・25 になると対応プリセットがアクティブ）。以前はホームにあったが設定タブへ移動。オンボーディングと同じ共通ウィジェット。
2. **ShipIt Pro**（休眠中は導線が実質無効/非表示になりうる）：
   - ステータス（Free/Active）。Free時「Proにアップグレード」→`/paywall`。
   - Pro時「サブスク管理」（`manageSubscriptionsUrl`）／「購入を復元」（`purchaseService.restore`）。
3. **通知**：トグルは**2本**。どちらも既定ON。
   - 「毎日のリマインダー」（`reminder_enabled`）＋時刻（`reminder_hour/minute`。既定08:00）。
     - **通知時刻の行はトグルの「子」**。`_CollapsibleSection`（`AnimatedSize` + `heightFactor` + `AnimatedOpacity`）でオフのときは畳んで消し、オンのときだけ現れる。並べて灰色表示にすると対等な2項目に見えてしまうため、開閉の動きで従属関係を伝える。行自体も左インデント＋縦のつなぎ線＋一段落とした文字色で子であることを示す（`_ReminderTimeRow`）。OS通知がオフのときも畳む（時刻を選ばせる意味がないため）。
     - 時刻の選択は **`showWheelTimePicker`**（[wheel_time_picker.dart](../../../lib/shared/widgets/wheel_time_picker.dart)）。時・分の2連ホイールのボトムシート。**Material の `showTimePicker` は使わない**——24時間制のアナログ文字盤は内周と外周に数字が二重に並び、どちらを選んでいるか読み取りにくいため。「時」「分」は数字に付けず**列見出し**に置く（英語モードで "08Hour" になるのを避ける）。ハイライト帯は2列にまたがって1本だけ描き、時と分で1つの時刻であることを示す。数値・帯の見た目は `DialPicker` と揃える。
   - 「ストリークが途切れそうな日」（`streak_reminder_enabled`）。23:00固定・時刻は設定不可。副題で「学習していない日だけ」を明示。
   - **2本に分ける理由**：「毎朝の通知は不要だが、途切れそうな日だけは欲しい」層を拾うため。1本のマスタースイッチだとこの層がまとめてオフにするしかない。
   - オフ時は `NotificationService.scheduleStreakReminders()` が**7日分をまとめてキャンセル**する。予約を消さないと切ったあとも最長7日鳴り続ける。
   - **OSの通知許可がオフのとき**（`notificationPermissionProvider` == false）：
     - セクション先頭に警告バナー（`_SystemNotificationOffBanner`）＋「設定を開く」（`app-settings:` を `launchUrl`）。
     - 2本のトグルは**非活性・グレー表示**。値は保持したまま見せる（OSを戻したとき以前の設定が復活する／「オンなのに鳴らない」を作らない）。**通知欄ごと隠さない**——隠すと「通知機能が無い」と誤解されるため。
   - 許可の要求は「未決定＝OSダイアログを出す」「拒否済み＝設定アプリへ誘導」を `notif_permission_requested` で出し分ける（iOSは一度拒否すると `requestPermissions()` が無言で false を返し、袋小路になるため）。
   - 許可状態は `app.dart` の `didChangeAppLifecycleState(resumed)` で毎回読み直し、拒否→許可に変わったら `NotificationService.rescheduleAll()` で予約を組み直す（許可が無い間の `zonedSchedule` はOSに黙って捨てられる）。
4. **データ**：バックアップ書き出し／読み込み（[systems/platform-and-ui.md](../systems/platform-and-ui.md) の BackupService）・学習データリセット（確認ダイアログ）。
5. **フッター**：アプリバージョン（`AppConstants.appVersion`。pubspecと手動同期）。

## 注意
- 新規カード数の設定は Settings ではなく **Home の「今日のセッション」内**にある。
- Pro判定・境界は `isProProvider` / `MonetizationConfig` のみ（[systems/monetization.md](../systems/monetization.md)）。

## 学習セクションの拡張（2026-08-16）
- 見出しを**「新規カードの1日上限」**に変更（`newStudyCardsHeading`。「1日の新規学習カード数」から改名）。
- `NewCardsSetting(todayStudiedNew: ...)` で**今日への影響をライブ表示**:
  「今日すでにX枚学習 → 今日はあとY枚」（`newCardsTodayImpact`。設定タブのみ。オンボーディングでは出さない）。
- **「復習をクイズ形式でも出題」トグル**（`SettingsState.quizEnabled`・既定ON・`keyQuizEnabled`）。
  OFF時はユニットテスト以外すべてフリップカード（study_screen 側で `quizModeFor` をスキップ）。
