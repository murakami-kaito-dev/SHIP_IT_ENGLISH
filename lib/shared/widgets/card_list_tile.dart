import 'package:flutter/material.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/shared/widgets/card_detail_sheet.dart';

/// カード1件の行（カテゴリ詳細・検索・フィルタ結果で共用）。
/// 先頭にカテゴリ内の通し番号、末尾に学習状況チップを表示する。
class CardListTile extends StatelessWidget {
  final CardWithStatus item;
  final AppStrings strings;
  final VoidCallback onTap;

  /// カテゴリ横断の一覧（検索・フィルタ）ではカテゴリ名も表示する
  final bool showCategoryName;

  /// Pro限定でロックされている場合は鍵アイコンを出す
  final bool locked;

  const CardListTile({
    super.key,
    required this.item,
    required this.strings,
    required this.onTap,
    this.showCategoryName = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppTheme.cardBorderRadius);
    final def = categoryDefs.firstWhere(
      (d) => d['id'] == item.card.category,
      orElse: () => const {'name': '', 'icon': ''},
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // 外側で影を描き、内側 Material でインクをクリップする
      // （Material の borderRadius が影を切り取ってしまうのを避ける）
      child: DecoratedBox(
        decoration: AppTheme.cardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
              children: [
                // カテゴリ内の通し番号（モノスペースで "行番号" のように）
                Container(
                  width: 36,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${item.card.cardNumber}',
                    style: AppTheme.monoLabel.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showCategoryName)
                        Text(
                          '${def['icon']} ${def['name']}',
                          style: AppTheme.captionText.copyWith(fontSize: 11),
                        ),
                      Text(
                        item.card.phrase,
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.card.translation,
                        style: AppTheme.captionText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (locked)
                  const Icon(Icons.lock_outline,
                      size: 18, color: AppTheme.ratingUncertain)
                else
                  CardStatusChip(rating: item.rating, strings: strings),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
