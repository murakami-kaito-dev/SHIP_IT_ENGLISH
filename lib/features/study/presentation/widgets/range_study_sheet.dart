import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';

/// カテゴリ学習の設定シートを開く。
/// カテゴリ・学習状況・番号範囲・出題順を指定して学習する（枚数上限なし）。
/// [fixedCategoryId] を渡すとカテゴリはそれに固定される（カテゴリ詳細から呼ぶ場合）。
void showRangeStudySheet(
  BuildContext context, {
  String? fixedCategoryId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RangeStudySheet(fixedCategoryId: fixedCategoryId),
  );
}

/// 学習状況フィルタの選択肢（値はDBの last_rating / 'new'=未学習）
const _statusOptions = ['new', 'forgot', 'uncertain', 'remembered'];

class _RangeStudySheet extends ConsumerStatefulWidget {
  final String? fixedCategoryId;

  const _RangeStudySheet({this.fixedCategoryId});

  @override
  ConsumerState<_RangeStudySheet> createState() => _RangeStudySheetState();
}

class _RangeStudySheetState extends ConsumerState<_RangeStudySheet> {
  String? _categoryId;
  RangeValues _range = const RangeValues(1, 1);
  int _maxNumber = 1;
  final Set<String> _statuses = {}; // 空 = 全状況
  bool _random = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.fixedCategoryId;
  }

  void _selectCategory(String id, int total) {
    setState(() {
      _categoryId = id;
      _maxNumber = total;
      _range = RangeValues(1, total.toDouble());
    });
  }

  String _statusLabel(String s, AppStrings strings) => switch (s) {
        'new' => strings.statusNew,
        'forgot' => strings.ratingForgot,
        'uncertain' => strings.ratingUncertain,
        _ => strings.ratingRemembered,
      };

  Color _statusColor(String s) => switch (s) {
        'new' => AppTheme.textTertiary,
        'forgot' => AppTheme.ratingForgot,
        'uncertain' => AppTheme.ratingUncertain,
        _ => AppTheme.ratingRemembered,
      };

  void _start() {
    final from = _range.start.round();
    final to = _range.end.round();
    final params = <String, String>{
      'category': _categoryId!,
      'from': '$from',
      'to': '$to',
      if (_statuses.isNotEmpty) 'statuses': _statuses.join(','),
      'order': _random ? 'random' : 'asc',
    };
    final query =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    context.pop();
    context.push('/study?$query');
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isPro = ref.watch(isProProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => categoriesAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(
          height: 200,
          child: Center(
            child: Text(strings.genericError, style: AppTheme.bodyText),
          ),
        ),
        data: (categories) {
          final selectable = categories
              .where((c) =>
                  isPro || MonetizationConfig.freeCategoryIds.contains(c.id))
              .where((c) => c.totalCount > 0)
              .toList();

          // fixedCategory が渡された初回は範囲を初期化する
          if (_categoryId != null && _maxNumber == 1) {
            final cat = selectable.firstWhere(
              (c) => c.id == _categoryId,
              orElse: () =>
                  selectable.isNotEmpty ? selectable.first : categories.first,
            );
            _maxNumber = cat.totalCount;
            _range = RangeValues(1, cat.totalCount.toDouble());
          }

          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(strings.rangeStudyTitle, style: AppTheme.headingLarge),
                const SizedBox(height: 4),
                Text(strings.rangeStudySubtitle, style: AppTheme.captionText),
                const SizedBox(height: 20),

                // カテゴリ選択（固定でなければ）
                if (widget.fixedCategoryId == null) ...[
                  _label(strings.rangeSelectCategory),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cat in selectable)
                        ChoiceChip(
                          label: Text('${cat.icon} ${cat.name}'),
                          selected: _categoryId == cat.id,
                          onSelected: (_) =>
                              _selectCategory(cat.id, cat.totalCount),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                if (_categoryId != null) ...[
                  // 学習状況フィルタ（複数選択・未選択=全て）
                  _label(strings.rangeSelectStatus),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _statusOptions)
                        FilterChip(
                          label: Text(_statusLabel(s, strings)),
                          selected: _statuses.contains(s),
                          selectedColor: _statusColor(s).withOpacity(0.15),
                          checkmarkColor: _statusColor(s),
                          onSelected: (sel) => setState(() {
                            sel ? _statuses.add(s) : _statuses.remove(s);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 範囲
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label(strings.rangeSelectRange),
                      Text(
                        '#${_range.start.round()} 〜 #${_range.end.round()}',
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_maxNumber > 1)
                    RangeSlider(
                      values: _range,
                      min: 1,
                      max: _maxNumber.toDouble(),
                      divisions: _maxNumber - 1,
                      activeColor: AppTheme.primary,
                      labels: RangeLabels(
                        '${_range.start.round()}',
                        '${_range.end.round()}',
                      ),
                      onChanged: (v) => setState(() => _range = v),
                    ),
                  const SizedBox(height: 12),

                  // 出題順
                  _label(strings.rangeSelectOrder),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(strings.rangeOrderAsc),
                        icon: const Icon(Icons.sort, size: 18),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(strings.rangeOrderRandom),
                        icon: const Icon(Icons.shuffle, size: 18),
                      ),
                    ],
                    selected: {_random},
                    onSelectionChanged: (sel) =>
                        setState(() => _random = sel.first),
                  ),
                  const SizedBox(height: 20),

                  // 一致件数プレビュー + 開始
                  _StartSection(
                    config: CategoryStudyConfig(
                      categoryId: _categoryId!,
                      from: _range.start.round(),
                      to: _range.end.round(),
                      statuses: _statuses,
                    ),
                    strings: strings,
                    onStart: _start,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style:
            AppTheme.captionText.copyWith(fontWeight: FontWeight.w600),
      );
}

/// 条件に一致する枚数を表示し、1枚以上あれば「学習」ボタンを有効にする
class _StartSection extends ConsumerWidget {
  final CategoryStudyConfig config;
  final AppStrings strings;
  final VoidCallback onStart;

  const _StartSection({
    required this.config,
    required this.strings,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(categoryStudyCountProvider(config));
    final count = countAsync.asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (count != null)
          Text(
            count > 0
                ? '$count${strings.rangeMatchCount}'
                : strings.rangeNoMatch,
            style: AppTheme.captionText.copyWith(
              color: count > 0 ? AppTheme.primary : AppTheme.ratingForgot,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: (count ?? 0) > 0 ? onStart : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(strings.rangeStart),
        ),
      ],
    );
  }
}
