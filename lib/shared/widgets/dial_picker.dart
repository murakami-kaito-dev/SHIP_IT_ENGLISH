import 'package:flutter/cupertino.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// iOS標準ライクなダイヤルピッカー（中央の値＝選択値）。
/// 値は `index + min`。学習枚数設定・リスニング範囲選択で**共通利用**し、
/// 操作感と見た目（テーマカラー）を統一する。
class DialPicker extends StatelessWidget {
  final FixedExtentScrollController controller;

  /// 選択肢の個数（value は `min` から `min + count - 1` まで）。
  final int count;
  final int min;
  final ValueChanged<int> onChanged;
  final double height;

  const DialPicker({
    super.key,
    required this.controller,
    required this.count,
    required this.min,
    required this.onChanged,
    this.height = 176,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: AppTheme.cardBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 44,
        diameterRatio: 1.25,
        squeeze: 1.05,
        useMagnifier: true,
        magnification: 1.12,
        // 中央のバンドを primary の淡色でハイライト（数字は透過して見える）。
        selectionOverlay: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSelectedItemChanged: (index) => onChanged(index + min),
        children: [
          for (var v = min; v < min + count; v++)
            Center(
              child: Text(
                '$v',
                style:
                    AppTheme.monoNumber.copyWith(color: AppTheme.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
