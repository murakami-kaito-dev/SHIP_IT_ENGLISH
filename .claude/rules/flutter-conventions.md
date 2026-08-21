---
paths:
  - "lib/**/*.dart"
---

# Flutter コーディング規約（`lib/**/*.dart` 編集時に常時適用）

> `lib/**/*.dart` を編集する時に適用されるパス限定ルール（`CLAUDE.md` の
> 「コーディング上の注意事項」からコード規約を移設）。カード追加手順・音声生成・
> リリース同期などの**プロセス/データ/ツーリング系は `CLAUDE.md` 側に残している**。

## UI / Widget
- **`Color.withValues(alpha:)` は使わない** → Flutter 3.24では未定義。`withOpacity()` を使う
- **`AppBar.actions` に幅が不定のWidgetを置かない**（LinearProgressIndicator など）
- **`FractionallySizedBox` で `widthFactor` だけを指定しない**。高さの制約が緩いまま渡り、子を持たない `DecoratedBox` / `Container` は**高さ0に潰れて1pxも描画されない**。必ず `heightFactor: 1.0` も付ける（`test/unit/xp_progress_bar_test.dart` で恒久ガード）
- **学習画面に同じ形の横棒を2本並べない**。セッション進捗＝AppBar直下の全幅ヘアライン（線）、XP＝カード上の部品（面）と形を分ける。進捗の数字には必ず単位（枚 / XP）を付ける
- **時刻の選択に `showTimePicker`（Materialのアナログ文字盤）を使わない** → `shared/widgets/wheel_time_picker.dart` の `showWheelTimePicker` を使う。「時」「分」は数字に付けず列見出しに置く（英語モードで "08Hour" になるため）
- **UI文言はハードコード禁止**: `core/i18n/app_strings.dart` に ja/en 両方を定義し、`stringsProvider` 経由で取得する

## 画面遷移（go_router）
- **「戻る」に `context.go()` を使わない** → `popOrGo(context, フォールバック先)`（`core/utils/nav_utils.dart`）を使う。`go` は履歴を作り直すため、タブ（ShellRoute）の外の全画面ルートへ go すると**そのページ1枚だけのスタック＝戻るボタンもタブも無い行き止まり**になる（アプリ再起動しか脱出できない。ユニットテスト終了後の `go('/category/:id')` で実際に発生）
- **`go` の遷移先になり得る全画面ルートは、戻るボタンを `automaticallyImplyLeading` 任せにしない**。pop 先が無いと黙って消えるため、`leading` を明示して常に脱出口を出す（恒久ガード: `test/widget/nav_dead_end_test.dart`）

## 状態管理 / データ更新
- **`riverpod_generator` / `build_runner` は導入済みだがコード生成は使っていない**（手動プロバイダーで統一）
- **学習進捗を変更したら `invalidateProgressProviders(ref)` を呼ぶ**（`core/providers/progress_refresh.dart`）。ホーム・カテゴリのFutureProviderはキャッシュするため、これを忘れると古い集計が表示される
- **カードの学習状況の表示は `Rating`（忘れた/曖昧/覚えてた、未評価はnull=未学習）で統一**。`CardStatus`（new/learning/review/mastered）はSRS内部状態であり画面には出さない
- **進捗表示は `studiedCount`（status != 'new'）を使う**。`mastered` は21日間隔到達が条件で数週間かかるため、これを主指標にすると「学習しても0のまま」になる

## SRS / 学習ロジック
- **評価ボタンの次回間隔は必ず `SrsEngine.projectedInterval()` を使う**（表示と実際の `processReview` 結果が一致する。独自計算で二重管理しない）
- **「忘れた」の次回復習は当日中の短い再学習ステップ**（`relearnStepMinutes = 10`分後）。以前は `next_review = now`（即時）だったが、エビングハウス基準で数十分後に変更。ただし `intervalDays` は 0 のまま（＝graduated扱いしない）。セッション内の即時再出題は `retryCount` 側で別管理なので影響なし

## 通知
- **通知はトグルの表示と実挙動を必ず一致させる**。①アプリ内トグルをオフにしたら、既にOSへ積んだ予約も消す（`scheduleStreakReminders()` は7日分を先に積むため、止めるだけでは最長7日鳴り続ける）②OSの通知許可がオフのときはトグルを「オン」と表示しない（`notificationPermissionProvider` で非活性化＋バナー）。**通知欄ごと隠さない**（「通知機能が無い」と誤解されるため）③許可はアプリ外で変わるので `resumed` のたびに読み直し、復帰時は `rescheduleAll()` で予約を組み直す（許可が無い間の `zonedSchedule` は黙って捨てられる）

## 課金（Pro / エンタイトルメント）
- **Pro判定は `isProProvider` 経由のみ**（サブスク無効時は常にtrue）。無料/Proの線引きは `MonetizationConfig` だけで変更する
- **権利は `setPro(true)` して終わりにしない**。解約・返金を反映するため `EntitlementNotifier.verify()` が起動時／フォアグラウンド復帰時に再検証する（間隔・猶予期間は `MonetizationConfig`）

## ゲーミフィケーション
- **XP/コンボ判定は `gamificationProvider` に集約**。study_screen は `registerAnswer(rating, firstTry)` を呼んで返る `AnswerOutcome`（combo/xpGained/fever/leveledUp）でエフェクトを発火するだけ。XP量・コンボ閾値・FEVER倍率・デイリー目標は `GamificationConfig` の定数のみで調整する
- **XP総量だけを永続化**（`keyTotalXp`）。レベルとレベル内進捗は `GamificationSnapshot.fromTotalXp()` で都度算出（別々に保存しない）。コンボ・セッションXPはセッション内の一時状態で永続化しない（`startSession()` でリセット）
- **効果音/振動は必ず `SoundService` 経由**（直接 HapticFeedback を撒かない）。実SFXを足すときは `_sfx()` をローカルアセット再生に差し替える（ネットワーク非通信・データ収集なしの方針を維持）

## 音声再生（iOS）
- **iOSのバックグラウンド/ロック画面再生（Now Playing）は `mixWithOthers` を付けない**。付けると「他の音と混ざる控えめな再生」扱いになり**アプリがNow Playingの座を取れず、ロック画面に曲名・操作が出ない／リモート操作が効かない**。主役として鳴らす連続再生（耳学）は `playback`＋オプション無しの専用コンテキストを使う（発音ボタンの単発再生は `mixWithOthers` のままで可）。表示/操作は `NowPlayingService`＋`AppDelegate.swift`（`MPNowPlayingInfoCenter`/`MPRemoteCommandCenter`）。チャンネル設定は `super.application` の**後**（rootViewController確定後）
- **リスト並び替え（ReorderableList）＆スライダー（シークバー）のちらつき対策**:
  - **キーは安定・一意に**：`ReorderableListView`/`Sliver...` の各行は `ValueKey(不変のid)`（カード番号やインデックス等の可変値をkeyにしない）。`onReorder` はメインで**同期的に**state更新（重い永続化は後追い/バックグラウンド）。再生中要素は id で追従させる（本アプリの耳学キューが該当）
  - **スライダーは「離した直後にライブ値へ即戻さない」**：`onChangeEnd` で live 値に戻すと、内部状態（再生位置/対象行）が一瞬食い違い**つまみがカクッと飛ぶ**。ドラッグ解放後は**目標値でつまみを保持**し、実際の再生位置が目標へ追いつくまで live 追従を再開しない（`_hold`/`_holdLine`＋保険Timer。`listening_screen.dart` の `_SeekBar` 参照）
  - **アニメーションの範囲を最小化**：`AnimatedContainer` 等は変化させたい要素だけに限定し、リスト全体を包む広域再描画を避ける
