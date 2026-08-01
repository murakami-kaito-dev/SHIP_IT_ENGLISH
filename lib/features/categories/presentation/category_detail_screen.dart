import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/features/study/presentation/widgets/range_study_sheet.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';
import 'package:ship_it_english/shared/widgets/card_detail_sheet.dart';
import 'package:ship_it_english/shared/widgets/card_list_tile.dart';
import 'package:ship_it_english/shared/widgets/gradient_button.dart';

/// カテゴリ内の全カードをステータス付きで一覧表示する画面。
/// タップでカード詳細（例文・使用場面）をボトムシート表示する。
/// 下部の「このカテゴリを学習」からカテゴリ限定セッションを開始できる。
class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(categoryCardsProvider(categoryId));
    final strings = ref.watch(stringsProvider);
    final isPro = ref.watch(isProProvider);
    final def = categoryDefs.firstWhere(
      (d) => d['id'] == categoryId,
      orElse: () => const {'name': 'Cards', 'icon': ''},
    );

    // 無料プランでPro限定カテゴリに直接遷移された場合のガード
    final isLocked =
        !isPro && !MonetizationConfig.freeCategoryIds.contains(categoryId);
    if (isLocked) {
      return AppBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text('${def['icon']} ${def['name']}')),
        body: Center(
            child: Padding(
              padding: AppTheme.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 48, color: AppTheme.ratingUncertain),
                  const SizedBox(height: 16),
                  Text(strings.proLockedCategory,
                      style: AppTheme.bodyText, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/paywall'),
                    child: Text(strings.upgradeToPro),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('${def['icon']} ${def['name']}'),
      ),
      body: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(strings.cardsLoadError, style: AppTheme.bodyText),
          ),
          data: (cards) => ListView.builder(
            padding: AppTheme.screenPadding,
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final item = cards[index];
              return CardListTile(
                item: item,
                strings: strings,
                // 評価による一覧更新は invalidateProgressProviders 側で行われる
                onTap: () => showCardDetailSheet(
                  context: context,
                  card: item.card,
                  rating: item.rating,
                  strings: strings,
                ),
              );
            },
          ),
        ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          // このカテゴリを、学習状況・範囲・出題順を指定して学習する
          // （Pro限定機能。無料プランはパウォールへ）
          child: GradientButton(
            label: strings.studyThisCategory,
            icon: isPro ? Icons.play_arrow_rounded : Icons.lock_outline,
            onPressed: () => isPro
                ? showRangeStudySheet(context, fixedCategoryId: categoryId)
                : context.push('/paywall'),
          ),
        ),
      ),
      ),
    );
  }

}
