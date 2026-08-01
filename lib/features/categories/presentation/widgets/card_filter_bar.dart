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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
              const Icon(Icons.tune, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                strings.filterTitle,
                style: AppTheme.captionText.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              if (filter.isActive)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => notifier.state = filter.cleared(),
                  child: Text(
                    strings.filterClear,
                    style: AppTheme.captionText
                        .copyWith(color: AppTheme.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

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
          const SizedBox(height: 6),

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
          style: AppTheme.captionText.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) => children[i],
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
    final borderRadius = BorderRadius.circular(16);
    return Material(
      color: selected ? color.withOpacity(0.15) : AppTheme.background,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: selected ? color : AppTheme.surfaceBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 13, color: color),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: AppTheme.captionText.copyWith(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
