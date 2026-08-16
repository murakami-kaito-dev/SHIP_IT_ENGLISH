import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/features/study/domain/units.dart';
import 'package:ship_it_english/features/study/presentation/widgets/range_study_sheet.dart';
import 'package:ship_it_english/features/study/providers/units_providers.dart';
import 'package:ship_it_english/shared/widgets/edge_widgets.dart';
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
            // 先頭にユニット（約20枚ごとの関門＋卒業テスト）セクションを置く
            itemCount: cards.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _UnitsSection(
                  categoryId: categoryId,
                  cards: cards,
                  strings: strings,
                  isPro: isPro,
                );
              }
              final item = cards[index - 1];
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
      bottomNavigationBar: _BottomBar(
        categoryId: categoryId,
        strings: strings,
        isPro: isPro,
      ),
      ),
    );
  }
}

/// 下部の「学習/聴く」バー（既存のUIを部品化しただけ）。
class _BottomBar extends StatelessWidget {
  final String categoryId;
  final AppStrings strings;
  final bool isPro;

  const _BottomBar({
    required this.categoryId,
    required this.strings,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          // このカテゴリを、範囲・状況・順序を指定して「学習」または「耳学（聴く）」する。
          // どちらも同じ範囲指定シートを開き、モードだけを引き継ぐ。
          // （Pro限定機能。無料プランはパウォールへ）
          child: Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: strings.studyAction,
                  icon: isPro ? Icons.play_arrow_rounded : Icons.lock_outline,
                  onPressed: () => isPro
                      ? showRangeStudySheet(context,
                          fixedCategoryId: categoryId)
                      : context.push('/paywall'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EdgeButton(
                  label: strings.listenAction,
                  icon: isPro ? Icons.headphones_rounded : Icons.lock_outline,
                  onPressed: () => isPro
                      ? showRangeStudySheet(context,
                          fixedCategoryId: categoryId,
                          mode: RangeSheetMode.listen)
                      : context.push('/paywall'),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// ユニット（約20枚ごとの関門）セクション。
/// 各ユニットの学習状況と卒業テストへの導線、クリア済みバッジを横スクロールで出す。
class _UnitsSection extends ConsumerWidget {
  final String categoryId;
  final List<CardWithStatus> cards;
  final AppStrings strings;
  final bool isPro;

  const _UnitsSection({
    required this.categoryId,
    required this.cards,
    required this.strings,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = unitsForCount(cards.length);
    if (units.isEmpty) return const SizedBox.shrink();
    final cleared = ref.watch(clearedUnitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, size: 18, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                strings.unitsSectionTitle,
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${units.where((u) => cleared.contains(unitKey(categoryId, u.index))).length} / ${units.length}',
                style: AppTheme.monoLabel,
              ),
            ],
          ),
        ),
        SizedBox(
          // タイルの下エッジ影（+3px）がビューポートで見切れないよう、
          // 影ぶんの余白を高さと下パディングで確保する
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: units.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final unit = units[i];
              final isCleared =
                  cleared.contains(unitKey(categoryId, unit.index));
              // 範囲内で一度でも評価されたカード数（学習着手）
              final studied = cards
                  .where((c) =>
                      c.card.cardNumber >= unit.from &&
                      c.card.cardNumber <= unit.to &&
                      c.rating != null)
                  .length;
              return _UnitTile(
                unit: unit,
                studied: studied,
                cleared: isCleared,
                strings: strings,
                onTest: () => isPro
                    ? context.push(
                        '/study?category=$categoryId&from=${unit.from}&to=${unit.to}&mode=unit&unit=${unit.index}')
                    : context.push('/paywall'),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// ユニット1枚のタイル（番号・範囲・学習数・挑戦ボタン or クリアバッジ）。
class _UnitTile extends StatelessWidget {
  final StudyUnit unit;
  final int studied;
  final bool cleared;
  final AppStrings strings;
  final VoidCallback onTest;

  const _UnitTile({
    required this.unit,
    required this.studied,
    required this.cleared,
    required this.strings,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final accent = cleared ? AppTheme.ratingRemembered : AppTheme.primary;
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cleared
              ? AppTheme.ratingRemembered.withOpacity(0.6)
              : AppTheme.surfaceBorder,
          width: cleared ? 1.6 : 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.unitLabel(unit.index),
                  style: AppTheme.captionText.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cleared)
                const Icon(Icons.emoji_events_rounded,
                    size: 18, color: AppTheme.ratingRemembered),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            strings.unitRangeLabel(unit.from, unit.to),
            style: AppTheme.monoLabel,
          ),
          const SizedBox(height: 4),
          Text(
            strings.unitStudiedOf(studied, unit.cardCount),
            style: AppTheme.captionText.copyWith(fontSize: 11),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: cleared
                ? EdgeButton(
                    label: strings.unitClearedChip,
                    onPressed: onTest,
                    height: 30,
                    fontSize: 12,
                    foreground: accent,
                  )
                : EdgePressable(
                    onTap: onTest,
                    fill: AppTheme.primary,
                    edgeColor: AppTheme.primaryDark,
                    radius: 11,
                    child: SizedBox(
                      height: 27.5,
                      child: Center(
                        child: Text(strings.unitTestButton,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
