import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// セクション見出し（白カードの「外・上」に左揃えで置く小さなラベル）。
/// 設定画面とホーム画面で共通利用し、デザインを統一する。
/// [trailing] を渡すと右端にウィジェット（ヘルプアイコン等）を並べられる。
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      style: AppTheme.captionText.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: trailing == null
          ? label
          : Row(children: [label, const Spacer(), trailing!]),
    );
  }
}
