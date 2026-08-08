# Onboarding 画面（`/onboarding`）

- ファイル：[onboarding_screen.dart](../../../lib/features/onboarding/presentation/onboarding_screen.dart)
- 役割：初回起動時のみ。言語モード選択＋使い方の説明。完了で `/` へ。

## フロー
- `main.dart` が `onboarding_done==false` のとき初期ルートを `/onboarding` にする。
- ページ1：**言語モード選択**（`_ModeCard`）。
  - 「日本語」= 現場の技術英語を学ぶ（ja）／「English」= 技術日本語を学ぶ（en）。
  - 選択で `languageModeProvider.setMode(mode)`。
- ページ2以降：使い方（`_InfoPage`）。「タップしてめくる」「科学的な間隔反復（SRS）」等。
- 完了時：`onboarding_done=true` を保存 → `context.go('/')`。

## 注意
- 文言は言語モードに応じて ja/en を出し分け（このファイルは一部リテラルを持つが、基本方針は `app_strings` 経由）。
