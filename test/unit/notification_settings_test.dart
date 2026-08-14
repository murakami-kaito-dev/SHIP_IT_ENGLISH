import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/providers/notification_permission_provider.dart';
import 'package:ship_it_english/features/settings/presentation/settings_screen.dart';

/// 設定画面の「通知」セクションの恒久ガード。
///
/// 守りたい不変条件は1つだけ：**トグルの表示と、実際に鳴るかどうかを一致させる**。
/// - 定時リマインダーとストリーク危機通知は独立した2本のトグルである
/// - OSの通知が切られている間は、トグルを「操作できる」状態で見せない
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSettings(
    WidgetTester tester, {
    required bool systemNotificationEnabled,
    bool reminderEnabled = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'reminder_enabled': reminderEnabled,
    });
    // 設定画面は縦に長い ListView。既定の 800x600 だと通知セクションが
    // 遅延生成の範囲外に落ちて見つからないため、全体が収まる高さにする。
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        isProProvider.overrideWithValue(true),
        stringsProvider.overrideWithValue(AppStrings.of(LanguageMode.ja)),
        notificationPermissionProvider.overrideWith(
          (ref) => _FakeNotificationPermission(systemNotificationEnabled),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// タイトル文字列から、それを内包する SwitchListTile を引く
  SwitchListTile switchFor(WidgetTester tester, String title) {
    return tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text(title),
        matching: find.byType(SwitchListTile),
      ),
    );
  }

  testWidgets('通知トグルは「毎日のリマインダー」と「ストリーク」の2本に分かれている',
      (tester) async {
    await pumpSettings(tester, systemNotificationEnabled: true);

    expect(find.text('毎日のリマインダー'), findsOneWidget);
    expect(find.text('ストリークが途切れそうな日'), findsOneWidget);
    // 23:00固定である旨が副題で伝わること（隠し機能にしない）
    expect(find.text('学習していない日だけ、23:00にお知らせします'), findsOneWidget);

    // 既定はどちらもオン
    expect(switchFor(tester, '毎日のリマインダー').value, isTrue);
    expect(switchFor(tester, 'ストリークが途切れそうな日').value, isTrue);
  });

  testWidgets('OS通知がオンなら両トグルとも操作できる', (tester) async {
    await pumpSettings(tester, systemNotificationEnabled: true);

    expect(switchFor(tester, '毎日のリマインダー').onChanged, isNotNull);
    expect(switchFor(tester, 'ストリークが途切れそうな日').onChanged, isNotNull);
    // 警告バナーは出ない
    expect(find.text('iOSの設定で通知がオフになっています'), findsNothing);
  });

  testWidgets('OS通知がオフなら警告バナーを出し、両トグルを非活性にする',
      (tester) async {
    await pumpSettings(tester, systemNotificationEnabled: false);

    // 「通知機能が無い」と誤解されないよう、欄ごと隠さずに理由と導線を出す
    expect(find.text('iOSの設定で通知がオフになっています'), findsOneWidget);
    expect(find.text('現在このアプリからの通知は届きません'), findsOneWidget);
    expect(find.text('設定を開く'), findsOneWidget);
    expect(find.text('毎日のリマインダー'), findsOneWidget);
    expect(find.text('ストリークが途切れそうな日'), findsOneWidget);

    // onChanged が null＝タップしても状態が変わらない（＝オンにできない）
    expect(switchFor(tester, '毎日のリマインダー').onChanged, isNull);
    expect(switchFor(tester, 'ストリークが途切れそうな日').onChanged, isNull);
  });

  /// 「通知時刻」行を包む開閉アニメーションの状態を読む。
  /// 畳んでいる間も要素はツリーに残る（heightFactor 0 で潰す）ため、
  /// 存在の有無ではなく不透明度で判定する。
  double timeRowOpacity(WidgetTester tester) {
    return tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text('通知時刻'),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
  }

  testWidgets('リマインダーがオンなら「通知時刻」が開いている', (tester) async {
    await pumpSettings(
      tester,
      systemNotificationEnabled: true,
      reminderEnabled: true,
    );
    expect(timeRowOpacity(tester), 1.0);
  });

  testWidgets('リマインダーがオフなら「通知時刻」は畳まれる', (tester) async {
    await pumpSettings(
      tester,
      systemNotificationEnabled: true,
      reminderEnabled: false,
    );
    expect(timeRowOpacity(tester), 0.0);
  });

  testWidgets('OS通知がオフなら「通知時刻」も畳まれる', (tester) async {
    // アプリ内トグルがオンでも、OSが切られていれば時刻を選ばせる意味がない
    await pumpSettings(
      tester,
      systemNotificationEnabled: false,
      reminderEnabled: true,
    );
    expect(timeRowOpacity(tester), 0.0);
  });
}

/// OSの許可状態を固定する差し替え。実機のプラグイン呼び出しを避ける。
class _FakeNotificationPermission extends NotificationPermissionNotifier {
  _FakeNotificationPermission(bool enabled) : super(_NoopRef()) {
    state = enabled;
  }

  @override
  Future<void> refresh() async {}
}

/// [NotificationPermissionNotifier] はコンストラクタで Ref を保持するだけで、
/// refresh() を潰している間は一切触らないためダミーで足りる。
class _NoopRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
