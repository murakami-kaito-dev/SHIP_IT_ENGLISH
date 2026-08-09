# System: 耳学（リスニング再生）

- コード：[features/listening/](../../../lib/features/listening/)（domain / providers / presentation）。
- 目的：指定条件のカードの**音声を自動で流し続ける**“聴くだけ”モード。**学習（SRS評価）とは完全に独立**し、SRS・ストリーク・XP・統計には一切影響しない。

## 動線（入口A→入口B→再生）
- **入口A**：カテゴリ詳細（[category_detail_screen](../../../lib/features/categories/presentation/category_detail_screen.dart)）に「学習する」「🎧 聴く」の2ボタン。どちらも**同じ範囲指定シート**（[range_study_sheet](../../../lib/features/study/presentation/widgets/range_study_sheet.dart)）を開き、`RangeSheetMode`（study/listen）だけを引き継ぐ。
- **入口B**：範囲指定シート。中身（カテゴリ・番号範囲・状況フィルタ・**番号順/ランダム**）は共通。最終ボタンと遷移先だけモードで変わる：
  - study → 「この条件で学習」→ `/study?...`
  - listen → 「この条件で聴く」→ `/listen?...`
- ホームの🎛は従来どおり study モード。

## 再生ロジック（[listening_providers.dart](../../../lib/features/listening/providers/listening_providers.dart) / [listening_state.dart](../../../lib/features/listening/domain/listening_state.dart)）
- `/listen` は `ListenConfig`（category/from/to/statuses/random）を受け取り、`listeningCardsProvider` が `getCategoryStudyCards`（学習と同じクエリ）でカード取得。
- `ListeningController`（StateNotifier.autoDispose）が再生を駆動。取得後 `load(cards, mode)` で先頭から**自動再生**。
- **1枚 = 4行**。順序は `speechLinesFor(card, mode)`：
  - ja：フレーズ(en-US) → 訳(ja-JP) → 例文(en-US) → 例文訳(ja-JP)
  - en：訳(ja-JP) → フレーズ(en-US) → 例文訳(ja-JP) → 例文(en-US)
  - 各行は自分のロケールの同梱クリップで再生（無ければ端末TTS）。
- 各行は `TtsService.speakAndWait(text, locale, rate)` で**再生完了を待って**次へ。行間0.4秒／カード間0.8秒（`_lineGap`/`_cardGap`）。
- **繰り返しモード**（`repeat`）：OFF=最後で停止し `finished`（「再生完了」→もう一度）。ON=先頭へループ（音楽プレイヤー式）。
- **速度**（`speed`・`kListenSpeeds`=0.75/1.0/1.25/1.5）。速度・繰り返しは prefs 永続化（`keyListenSpeed`/`keyListenRepeat`）。
  - **速度変更は再生中のクリップにも即時反映**：`setSpeed` が `TtsService.setPlaybackRate`→`AudioClipService.setPlaybackRate`（`_player.setPlaybackRate`）を呼ぶ。`playAndWait` も毎回 `setPlaybackRate(rate)`（1.0でも）して前クリップの倍率持ち越しを防ぐ。
- **シーク**：`jumpTo(index)` でその位置の**カード**へ移動（キュー行タップ）。`seekToLine(line)` で**現在カード内の行**から再生し直す（シークバー＝1アイテム内の位置調整。カードは移動しない）。
- 停止/一時停止/スキップ/並べ替えは `_runToken`（世代トークン）で進行中ループを無効化して制御。`dispose` で停止。
- **バックグラウンド/画面ロック再生**：`ios/Runner/Info.plist` の `UIBackgroundModes=[audio]`＋`playback` カテゴリで、スリープ・アプリ切替中も再生継続。

## プレイヤーUI（[listening_screen.dart](../../../lib/features/listening/presentation/listening_screen.dart)）
- `AppBackground(Scaffold(...))`（フルスクリーン遷移の作法）。
- **画面全体が1枚の縦スクロール**（`CustomScrollView`）：先頭 sliver が**画面いっぱいの再生画面**（`SizedBox(height: viewportH)` の `_PlayerBody`）、その下に**続きとして「次に再生」キュー**（`_QueueHeader`＋`SliverReorderableList`）。**別画面/モーダルではなく画面の続き**として下へスクロールすると現れる（下端の狭いスワイプに依存しない＝iPhoneのホーム操作と競合しない）。
- 再生画面：進捗／現在カード（4行・再生中行ハイライト＋`graphic_eq`）／**シークバー `_SeekBar`**（このカードの4行を表し、つまみドラッグ→離した行から `seekToLine` で再生し直す＝1アイテム内の位置調整）／繰り返しトグル・速度セレクタ／⏮ 再生⏸ ⏭／下スクロール誘導ハンドル `_RevealHandle`（タップで `animateTo(viewportH)`）。
- キュー：`SliverReorderableList`＋右の `drag_handle`（`ReorderableDragStartListener`）でドラッグ並べ替え（`reorder`。再生中カードは追従）。行タップで `jumpTo`。

## 音声基盤の変更（[tts-audio.md](tts-audio.md) と共通）
- `TtsService.speakLocale(text, locale)`：ロケール明示の単発再生（カード詳細の両言語スピーカー＝依頼1-2で使用）。`speakTarget` はこれの薄いラッパに。
- `TtsService.speakAndWait(...)` / `AudioClipService.playAndWait(...)`：**完了待ち**再生（耳学の順次再生用）。
  - 完了検知は `onPlayerComplete`（自然終了）で解く。**外部 `stop()` は保持した `_activeWait` Completer を完了させて待機を解く**（一時停止/スキップに即応）。`onPlayerStateChanged`（stopped）だと再生開始直後の状態遷移で誤発火し「猛烈に速く進む」ため使わない。
  - iOSセッションは `playback`＋`mixWithOthers` のみ（`defaultToSpeaker` は付けない＝ `Error -50` 回避。[gamification.md](gamification.md) 参照）。

## 注意
- 耳学は**学習記録に非反映**。SRS/ストリーク/XPのコードには触れない。
- カード詳細シートは表示言語モードに関わらず**英語行・日本語行の両方**にスピーカーを出す（各行そのロケールで再生）。
