import 'package:flutter/material.dart';
import 'package:ship_it_english/dev/design_previews/design_a_home.dart';
import 'package:ship_it_english/dev/design_previews/design_b_home.dart';
import 'package:ship_it_english/dev/design_previews/design_c_home.dart';
import 'package:ship_it_english/dev/design_previews/design_d_home.dart';
import 'package:ship_it_english/dev/design_previews/design_e_home.dart';
import 'package:ship_it_english/dev/design_previews/design_f_home.dart';
import 'package:ship_it_english/dev/design_previews/design_g_home.dart';
import 'package:ship_it_english/dev/design_previews/design_h_home.dart';

/// 【デザインプレビュー専用エントリポイント】
///
/// 実アプリ（lib/main.dart）には一切手を入れず、デザイン候補の静的モックだけを
/// 起動する。DBもプロバイダーも初期化しない（完全に見た目だけ）。
/// **左右スワイプで実装済みの案を切り替えて比較できる。**
///
/// 起動方法:
///   flutter run -t lib/main_design_preview.dart
/// 通常のアプリに戻すには普通に `flutter run`（本体コードは無変更）。
void main() {
  runApp(const DesignPreviewApp());
}

class DesignPreviewApp extends StatefulWidget {
  const DesignPreviewApp({super.key});

  @override
  State<DesignPreviewApp> createState() => _DesignPreviewAppState();
}

class _DesignPreviewAppState extends State<DesignPreviewApp> {
  static const _designs = [
    // 最新：E×F ハイブリッド（色=E / 骨格=F / ノート・ペン意匠なし）
    ('案H E×Fハイブリッド', DesignHHome()),
    // 前ラウンドの案
    ('案E スタディノート', DesignEHome()),
    ('案F ソフトアーケード', DesignFHome()),
    ('案G 単語帳デスク', DesignGHome()),
    // 旧案（比較用に残置）
    ('案C リキッドグラス', DesignCHome()),
    ('案A アーケード', DesignAHome()),
    ('案B キャンディ', DesignBHome()),
    ('案D クレイ', DesignDHome()),
  ];

  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design Preview',
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: [
          PageView(
            onPageChanged: (i) => setState(() => _page = i),
            children: [for (final d in _designs) d.$2],
          ),
          // 現在の案ラベル（スワイプで切替できることを示す小さなチップ）
          Positioned(
            top: 62,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xCC26283A),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${_designs[_page].$1}（← スワイプで切替 →）',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
