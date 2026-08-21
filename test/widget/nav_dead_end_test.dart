import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/utils/nav_utils.dart';

/// 画面遷移が「行き止まり」にならないことの恒久ガード。
///
/// 背景: ユニットテスト終了後に `context.go('/category/<id>')` していたため、
/// 履歴が作り直されてカテゴリ詳細1枚だけのスタックになり、AppBar は戻るボタンを
/// 出さず（pop 先が無い）タブ（ShellRoute）も無い＝**どこにも移動できない**状態に
/// なっていた。ユーザーはアプリを再起動するしか脱出できなかった。
///
/// アプリと同じ骨格（タブ＝ShellRoute / 全画面ルート＝その外側）の縮小版ルーターで
/// `popOrGo` の挙動を検証する。
void main() {
  GoRouter buildRouter() => GoRouter(
        initialLocation: '/categories',
        routes: [
          ShellRoute(
            builder: (_, __, child) => Scaffold(
              body: child,
              bottomNavigationBar: const SizedBox(
                height: 40,
                child: Center(child: Text('TABS')),
              ),
            ),
            routes: [
              GoRoute(
                path: '/categories',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: Text('categories')),
              ),
            ],
          ),
          GoRoute(
            path: '/category/:id',
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => popOrGo(context, '/categories'),
                ),
              ),
              body: Text('detail:${state.pathParameters['id']}'),
            ),
          ),
          GoRoute(
            path: '/study',
            builder: (context, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  // ユニットテスト終了後の戻り処理と同じ呼び出し
                  onPressed: () => popOrGo(context, '/categories'),
                  child: const Text('finish'),
                ),
              ),
            ),
          ),
        ],
      );

  testWidgets('ユニット学習を終えるとカテゴリ詳細に戻り、さらに戻れる（行き止まりにならない）',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // カテゴリ一覧 → カテゴリ詳細 → ユニット学習
    router.push('/category/code_review');
    await tester.pumpAndSettle();
    router.push('/study');
    await tester.pumpAndSettle();
    expect(find.text('finish'), findsOneWidget);

    // 学習完了 → カテゴリ詳細へ戻る
    await tester.tap(find.text('finish'));
    await tester.pumpAndSettle();
    expect(find.text('detail:code_review'), findsOneWidget);

    // ここで戻る手段が残っていることが肝（以前は pop 先が無く行き止まりだった）
    expect(router.canPop(), isTrue);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('categories'), findsOneWidget);
    expect(find.text('TABS'), findsOneWidget);
  });

  testWidgets('履歴が無い状態でカテゴリ詳細に居ても、戻るボタンでタブのある画面へ抜けられる',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // 履歴を作り直す遷移（＝行き止まりを生む遷移）でカテゴリ詳細に居る状態
    router.go('/category/slack');
    await tester.pumpAndSettle();
    expect(find.text('detail:slack'), findsOneWidget);
    expect(find.text('TABS'), findsNothing);
    expect(router.canPop(), isFalse);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('categories'), findsOneWidget);
    expect(find.text('TABS'), findsOneWidget);
  });
}
