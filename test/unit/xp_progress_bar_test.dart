import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/xp_progress_bar.dart';

/// XPゲージの恒久ガード。
///
/// 守りたいのは1点：**XPが溜まったら実際に塗られて見えること**。
/// 過去に `FractionallySizedBox` の heightFactor 未指定で塗りが高さ0に潰れ、
/// 171/180（95%）でもバーが真っ白のままという不具合を出している。
/// 幅だけでなく「高さ > 0」を必ず検証する。
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpBar(WidgetTester tester, {required int totalXp}) async {
    SharedPreferences.setMockInitialValues({'gamification_total_xp': totalXp});

    final container = ProviderContainer(
      overrides: [
        stringsProvider.overrideWithValue(AppStrings.of(LanguageMode.ja)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: XPProgressBar(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// ゲージの塗り（グラデーション部分）の描画サイズ。
  Size fillSize(WidgetTester tester) {
    return tester.getSize(
      find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(DecoratedBox),
      ),
    );
  }

  testWidgets('XPが溜まっていれば塗りに高さがある（高さ0に潰れない）',
      (tester) async {
    // LV1 に必要なのは 100XP。60XP なら 60%。
    await pumpBar(tester, totalXp: 60);

    final size = fillSize(tester);
    expect(size.height, greaterThan(0),
        reason: '高さ0だと画面上はゲージが空のままになる');
    expect(size.width, greaterThan(0));
  });

  testWidgets('XPが増えるほど塗りが横に伸びる', (tester) async {
    await pumpBar(tester, totalXp: 20);
    final narrow = fillSize(tester).width;

    await pumpBar(tester, totalXp: 80);
    final wide = fillSize(tester).width;

    expect(wide, greaterThan(narrow));
  });

  testWidgets('次の到達点（あと◯XPでLV◯）が表示される', (tester) async {
    await pumpBar(tester, totalXp: 60);
    // LV1(必要100XP) に 60XP → あと40XP
    expect(find.textContaining('あと 40 XP'), findsOneWidget);
  });

  testWidgets('レベルアップ間近（85%以上）は煽り文言に切り替わる',
      (tester) async {
    // 95XP / 100XP = 95%
    await pumpBar(tester, totalXp: 95);
    expect(find.text('あと 5 XP!'), findsOneWidget);
  });
}
