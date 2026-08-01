import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/search/providers/search_providers.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';
import 'package:ship_it_english/shared/widgets/card_detail_sheet.dart';
import 'package:ship_it_english/shared/widgets/card_list_tile.dart';

/// 全カード横断のフレーズ検索画面。
/// Pro限定カテゴリのカードは無料プランではロック表示（タップでパウォール）。
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isPro = ref.watch(isProProvider);
    final results = ref.watch(searchResultsProvider(_query));

    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: strings.searchHint,
            hintStyle:
                AppTheme.bodyText.copyWith(color: AppTheme.textTertiary),
            border: InputBorder.none,
          ),
          style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(strings.genericError, style: AppTheme.bodyText),
        ),
        data: (cards) {
          if (_query.trim().length >= 2 && cards.isEmpty) {
            return Center(
              child: Text(strings.searchEmpty, style: AppTheme.bodyText),
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
        ),
      ),
    );
  }
}
