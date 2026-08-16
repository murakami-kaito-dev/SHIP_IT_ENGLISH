import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';
import 'package:ship_it_english/shared/widgets/new_cards_setting.dart';

/// 「1日の新規学習カード数」設定UI（プリセット＋ダイヤル連動）のテスト。
/// プリセット押下が真実の源（settingsProvider）へ反映されることを保証する。
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pumpSetting(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      isProProvider.overrideWithValue(true),
      stringsProvider.overrideWithValue(AppStrings.of(LanguageMode.ja)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: NewCardsSetting()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('3つのプリセット（マイペース/スタンダード/スピード学習）が表示される',
      (tester) async {
    await pumpSetting(tester);
    expect(find.text('マイペース'), findsOneWidget);
    expect(find.text('スタンダード'), findsOneWidget);
    expect(find.text('スピード学習'), findsOneWidget);
    expect(find.text('新規カードの1日上限'), findsOneWidget); // 見出し
  });

  testWidgets('プリセット押下で newCardsPerDay が該当値に更新される',
      (tester) async {
    final container = await pumpSetting(tester);

    // 初期は既定値（5）
    expect(container.read(settingsProvider).newCardsPerDay, 5);

    await tester.tap(find.text('スタンダード'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).newCardsPerDay, 10);

    await tester.tap(find.text('スピード学習'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).newCardsPerDay, 25);

    await tester.tap(find.text('マイペース'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).newCardsPerDay, 5);
  });
}
