import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/dev/design_previews/design_a_home.dart';
import 'package:ship_it_english/dev/design_previews/design_b_home.dart';
import 'package:ship_it_english/dev/design_previews/design_c_home.dart';
import 'package:ship_it_english/dev/design_previews/design_d_home.dart';
import 'package:ship_it_english/dev/design_previews/design_e_home.dart';
import 'package:ship_it_english/dev/design_previews/design_f_home.dart';
import 'package:ship_it_english/dev/design_previews/design_g_home.dart';
import 'package:ship_it_english/dev/design_previews/design_h_home.dart';

/// デザインプレビュー4案のスモークテスト。
/// iPhone 16 Pro 相当の論理サイズで描画し、ビルド例外（オーバーフロー等）が
/// 出ないことを機械的に保証する（シミュレータで全ページを目視スワイプする
/// 代わりの安全網）。
void main() {
  const size = Size(402, 874); // iPhone 16 Pro logical points

  final designs = <String, Widget>{
    '案A アーケード': const DesignAHome(),
    '案B キャンディ': const DesignBHome(),
    '案C リキッドグラス': const DesignCHome(),
    '案D クレイ': const DesignDHome(),
    '案E スタディノート': const DesignEHome(),
    '案F ソフトアーケード': const DesignFHome(),
    '案G 単語帳デスク': const DesignGHome(),
    '案H E×Fハイブリッド': const DesignHHome(),
  };

  for (final entry in designs.entries) {
    testWidgets('${entry.key} がレイアウト例外なく描画できる', (tester) async {
      tester.view.physicalSize = size * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(home: entry.value));
      // ダッキーのアニメーションは repeat なので settle は使わず数フレームだけ回す
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('今日のセッション'), findsOneWidget);
      expect(find.text('今日のクエスト'), findsOneWidget);
    });
  }
}
