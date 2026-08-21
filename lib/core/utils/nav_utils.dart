import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 「戻る」の共通処理。積まれた履歴があれば pop、無ければ [fallbackLocation] へ go する。
///
/// `context.go()` は**履歴を作り直す**ため、タブ（ShellRoute）の外にある全画面ルート
/// （`/category/:id` など）へ go すると、そのページ1枚だけのスタックになる。
/// すると AppBar は戻るボタンを出さず（pop 先が無いため）タブも無い＝**どこにも移動
/// できない行き止まり**になり、ユーザーはアプリを再起動するしかなくなる。
/// 画面から戻るときは必ずこのヘルパーを通し、行き止まりを作らない。
void popOrGo(BuildContext context, String fallbackLocation) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackLocation);
  }
}
