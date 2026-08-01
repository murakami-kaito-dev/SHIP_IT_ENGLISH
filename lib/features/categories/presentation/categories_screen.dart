import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/presentation/widgets/card_filter_bar.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/shared/widgets/card_detail_sheet.dart';
import 'package:ship_it_english/shared/widgets/card_list_tile.dart';
import 'package:ship_it_english/shared/widgets/progress_bar.dart';

/// カテゴリ一覧。
/// 上部のフィルタが有効なときは、カテゴリカードではなく
/// 条件に一致するカード一覧を表示する。
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final filter = ref.watch(cardFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(strings.categoriesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: strings.searchTitle,
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          const CardFilterBar(),
          Expanded(
            child: filter.isActive
                ? const _FilteredCardList()
                : const _CategoryList(),
          ),
        ],
      ),
    );
  }
}

/// フィルタ未適用時: カテゴリカードの一覧
class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final strings = ref.watch(stringsProvider);
    final isJa = strings.mode == LanguageMode.ja;
    final isPro = ref.watch(isProProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(strings.genericError, style: AppTheme.bodyText)),
      data: (categories) => ListView.builder(
        padding: AppTheme.screenPadding,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final borderRadius = BorderRadius.circular(AppTheme.cardBorderRadius);
          // 無料プランではPro限定カテゴリをロック表示（タップでパウォールへ）
          final isLocked =
              !isPro && !MonetizationConfig.freeCategoryIds.contains(cat.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: AppTheme.cardDecoration,
              child: Material(
                color: Colors.transparent,
                borderRadius: borderRadius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: () => context
                      .push(isLocked ? '/paywall' : '/category/${cat.id}'),
                  child: Padding(
                    padding: AppTheme.cardPadding,
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.name, style: AppTheme.headingMedium),
                                Text(
                                  isJa ? cat.description : cat.descriptionEn,
                                  style: AppTheme.captionText,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isLocked ? Icons.lock_outline : Icons.chevron_right,
                            color: isLocked
                                ? AppTheme.ratingUncertain
                                : AppTheme.textTertiary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings.studiedOf(cat.studiedCount, cat.totalCount),
                            style: AppTheme.bodyText,
                          ),
                          Text(
                            '${(cat.percentage * 100).round()}%',
                            style: AppTheme.monoNumber
                                .copyWith(color: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressBar(value: cat.percentage),
                    ],
                  ),
                ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// フィルタ適用時: 条件に一致するカード一覧
class _FilteredCardList extends ConsumerWidget {
  const _FilteredCardList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isPro = ref.watch(isProProvider);
    final cardsAsync = ref.watch(filteredCardsProvider);

    return cardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(strings.genericError, style: AppTheme.bodyText)),
      data: (cards) {
        if (cards.isEmpty) {
          return Center(
            child: Text(strings.filterResultEmpty, style: AppTheme.bodyText),
          );
        }
        return ListView.builder(
          padding: AppTheme.screenPadding,
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final item = cards[index];
            final isLocked = !isPro &&
                !MonetizationConfig.freeCategoryIds
                    .contains(item.card.category);
            return CardListTile(
              item: item,
              strings: strings,
              showCategoryName: true,
              locked: isLocked,
              onTap: () {
                if (isLocked) {
                  context.push('/paywall');
                  return;
                }
                showCardDetailSheet(
                  context: context,
                  card: item.card,
                  rating: item.rating,
                  strings: strings,
                );
              },
            );
          },
        );
      },
    );
  }
}
