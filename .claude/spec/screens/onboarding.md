# Onboarding 画面（`/onboarding`）

- ファイル：[onboarding_screen.dart](../../../lib/features/onboarding/presentation/onboarding_screen.dart)
- 役割：初回起動時のみ。言語モード選択＋使い方の説明。完了で `/` へ。

## フロー
- `main.dart` が `onboarding_done==false` のとき初期ルートを `/onboarding` にする。
- ページ1：**言語モード選択**（`_ModeCard`）。
  - 「日本語」= 現場の技術英語を学ぶ（ja）／「English」= 技術日本語を学ぶ（en）。
  - 選択で `languageModeProvider.setMode(mode)`。
- ページ2〜3：使い方（`_InfoPage`）。「タップしてめくる」「科学的な間隔反復（SRS）」等。
- **ページ4：1日の新規学習カード数（1〜100）** ページ見出しは「1日の新規学習カード数」。`NewCardsSetting(showHeading: false)`（設定タブと同じ共通ウィジェット。3プリセット＋ダイヤルピッカーの双方向連動。ページ側に見出しがあるのでウィジェット内見出しは非表示）。あとで設定タブから変更可。
- **ページ5：かんたんレベル診断（初期診断）**：無料カテゴリから難易度をばらした10枚（`placementCardsProvider`・決定的選出）を一覧表示し、知っているフレーズをタップ選択。「この内容で始める」→ 選択カードを `placementKnownProgress`（review状態・間隔7日・次回7日後・覚えてた）として保存し、新規キューを飛ばしてSRSに乗せる。「スキップして始める」も可。→ 技術英語カバレッジ（[home.md](home.md) の `SkillScoreCard`）の初期値に反映される。
- 完了時（ページ5の開始/スキップ）：`onboarding_done=true` を保存 → `context.go('/')`。
- 通知許可は `main.dart` の `notificationService.initialize()`（`requestAlertPermission:true`）で**初回起動時にOSダイアログが出る**（オンボーディングとは別の仕組み）。設定タブでもトグル可。

## 注意
- 文言は言語モードに応じて ja/en を出し分け（このファイルは一部リテラルを持つが、基本方針は `app_strings` 経由）。
