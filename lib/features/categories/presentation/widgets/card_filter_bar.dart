import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

/// カテゴリタブ上部のフィルタバー。
/// カテゴリ（複数選択=OR）と学習状況（複数選択=OR）を組み合わせ、
/// 両方指定した場合は AND 条件で絞り込む。
class CardFilterBar extends ConsumerWidget {
  const CardFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final filter = ref.watch(cardFilterProvider);
    final notifier = ref.read(cardFilterProvider.notifier);
    final isJa = strings.mode == LanguageMode.ja;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded,
                    size: 15, color: AppTheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                strings.filterTitle,
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // 選択数バッジ（何件絞り込み中かひと目で分かる）
              if (filter.isActive) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filter.ratings.length + filter.categories.length}',
                    style: AppTheme.monoLabel.copyWith(color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => notifier.state = filter.cleared(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded,
                            size: 13, color: AppTheme.primary),
                        const SizedBox(width: 2),
                        Text(
                          strings.filterClear,
                          style: AppTheme.captionText.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // 学習状況（忘れた / 曖昧 / 覚えてた / 未学習）
          _FilterRow(
            label: strings.filterStatus,
            children: [
              _Chip(
                label: strings.ratingForgot,
                color: AppTheme.ratingForgot,
                selected: filter.ratings.contains(Rating.forgot),
                onTap: () =>
                    notifier.state = filter.toggleRating(Rating.forgot),
              ),
              _Chip(
                label: strings.ratingUncertain,
                color: AppTheme.ratingUncertain,
                selected: filter.ratings.contains(Rating.uncertain),
                onTap: () =>
                    notifier.state = filter.toggleRating(Rating.uncertain),
              ),
              _Chip(
                label: strings.ratingRemembered,
                color: AppTheme.ratingRemembered,
                selected: filter.ratings.contains(Rating.remembered),
                onTap: () =>
                    notifier.state = filter.toggleRating(Rating.remembered),
              ),
              _Chip(
                label: strings.statusNew,
                color: AppTheme.textTertiary,
                selected: filter.ratings.contains(null),
                onTap: () => notifier.state = filter.toggleRating(null),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // カテゴリ
          _FilterRow(
            label: strings.filterCategory,
            children: [
              for (final def in categoryDefs)
                _Chip(
                  label: '${def['icon']} ${def['name']}',
                  color: AppTheme.primary,
                  selected: filter.categories.contains(def['id']),
                  onTap: () =>
                      notifier.state = filter.toggleCategory(def['id']!),
                ),
            ],
          ),
          if (!isJa) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _FilterRow({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.monoLabel.copyWith(
            fontSize: 10,
            color: AppTheme.textTertiary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Center(child: children[i]),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        // 未選択＝そのチップ色をごく薄く敷いた淡色ソフト（枠線なし）
        // 選択＝ブランド/評価カラーのソリッド＋チェック＋やわらかいグロー
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.10),
            borderRadius: radius,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTheme.captionText.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
