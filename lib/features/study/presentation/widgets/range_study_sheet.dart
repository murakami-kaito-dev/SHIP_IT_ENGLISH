import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/shared/widgets/edge_widgets.dart';
import 'package:ship_it_english/shared/widgets/dial_picker.dart';

/// 範囲指定シートのモード。学習か、耳学（リスニング）か。
/// 中身（カテゴリ・範囲・状況・順序）は共通で、最終ボタンと遷移先だけが変わる。
enum RangeSheetMode { study, listen }

/// カテゴリ学習/耳学の設定シートを開く。
/// カテゴリ・学習状況・番号範囲・出題順を指定する（枚数上限なし）。
/// [fixedCategoryId] を渡すとカテゴリはそれに固定される（カテゴリ詳細から呼ぶ場合）。
/// [mode] が listen のとき、最終ボタンは「この条件で聴く」→ 耳学プレイヤーへ。
void showRangeStudySheet(
  BuildContext context, {
  String? fixedCategoryId,
  RangeSheetMode mode = RangeSheetMode.study,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _RangeStudySheet(fixedCategoryId: fixedCategoryId, mode: mode),
  );
}

/// 学習状況フィルタの選択肢（値はDBの last_rating / 'new'=未学習）
const _statusOptions = ['new', 'forgot', 'uncertain', 'remembered'];

class _RangeStudySheet extends ConsumerStatefulWidget {
  final String? fixedCategoryId;
  final RangeSheetMode mode;

  const _RangeStudySheet({this.fixedCategoryId, required this.mode});

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
    // モードで遷移先を出し分ける：学習=/study、耳学=/listen
    final path = widget.mode == RangeSheetMode.listen ? '/listen' : '/study';
    context.push('$path?$query');
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

                  // 範囲（最小〜最大を直接指定。ツマミの微調整をやめた）
                  _label(strings.rangeSelectRange),
                  const SizedBox(height: 10),
                  _RangeMinMaxSelector(
                    start: _range.start.round(),
                    end: _range.end.round(),
                    maxNumber: _maxNumber,
                    strings: strings,
                    onChanged: (v) => setState(() => _range = v),
                  ),
                  const SizedBox(height: 16),

                  // 出題順
                  _label(strings.rangeSelectOrder),
                  const SizedBox(height: 8),
                  EdgeChips<bool>(
                    items: [
                      EdgeChipItem(false, strings.rangeOrderAsc,
                          icon: Icons.sort),
                      EdgeChipItem(true, strings.rangeOrderRandom,
                          icon: Icons.shuffle),
                    ],
                    selected: _random,
                    onChanged: (sel) => setState(() => _random = sel),
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
                    mode: widget.mode,
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

/// 条件に一致する枚数を表示し、1枚以上あれば「学習」ボタンを有効にする。
///
/// 範囲を変えるたびに件数プロバイダー（config をキーにした family）が
/// 再取得され、ローディング中は値が null になる。素直に描くと件数テキストが
/// 消えてボタンが上下に動く（UIがうざったい）。そこで
/// - 件数行の高さを固定（テキストの有無で高さが変わらない）
/// - 直前の件数を保持して再取得中も表示し続ける
/// ことでレイアウトのガタつきをなくす。
class _StartSection extends ConsumerStatefulWidget {
  final CategoryStudyConfig config;
  final AppStrings strings;
  final RangeSheetMode mode;
  final VoidCallback onStart;

  const _StartSection({
    required this.config,
    required this.strings,
    required this.mode,
    required this.onStart,
  });

  @override
  ConsumerState<_StartSection> createState() => _StartSectionState();
}

class _StartSectionState extends ConsumerState<_StartSection> {
  int? _lastCount;

  @override
  Widget build(BuildContext context) {
    // 新しい件数が来たら保持する（再取得中も前回値を出し続けるため）
    ref.listen(categoryStudyCountProvider(widget.config), (_, next) {
      final v = next.asData?.value;
      if (v != null && v != _lastCount) {
        setState(() => _lastCount = v);
      }
    });
    final count =
        ref.watch(categoryStudyCountProvider(widget.config)).asData?.value ??
            _lastCount;
    final strings = widget.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 高さを固定して、件数の有無・変化でボタンが上下に動かないようにする
        SizedBox(
          height: 20,
          child: count == null
              ? null
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    count > 0
                        ? '$count${strings.rangeMatchCount}'
                        : strings.rangeNoMatch,
                    style: AppTheme.captionText.copyWith(
                      color:
                          count > 0 ? AppTheme.primary : AppTheme.ratingForgot,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: (count ?? 0) > 0 ? widget.onStart : null,
          icon: Icon(widget.mode == RangeSheetMode.listen
              ? Icons.headphones_rounded
              : Icons.play_arrow),
          label: Text(widget.mode == RangeSheetMode.listen
              ? strings.rangeStartListen
              : strings.rangeStart),
        ),
      ],
    );
  }
}

/// 番号範囲を「最小」「最大」それぞれのステッパー（上に入力欄・下に − / ＋）で指定。
/// 最小は最大を超えず、最大は総数[maxNumber]を超えない（相互にクランプ）。
/// 最小#・最大#を、学習枚数設定と同じ**ダイヤルピッカー**で選ぶ。
/// 常に「最小# ≦ 最大#」を維持：最小を上げて最大を超えたら最大も連動して上がり、
/// 最大を下げて最小を下回ったら最小も連動して下がる。
class _RangeMinMaxSelector extends StatefulWidget {
  final int start;
  final int end;
  final int maxNumber;
  final AppStrings strings;
  final ValueChanged<RangeValues> onChanged;

  const _RangeMinMaxSelector({
    required this.start,
    required this.end,
    required this.maxNumber,
    required this.strings,
    required this.onChanged,
  });

  @override
  State<_RangeMinMaxSelector> createState() => _RangeMinMaxSelectorState();
}

class _RangeMinMaxSelectorState extends State<_RangeMinMaxSelector> {
  late final FixedExtentScrollController _minCtrl =
      FixedExtentScrollController(initialItem: _idx(widget.start));
  late final FixedExtentScrollController _maxCtrl =
      FixedExtentScrollController(initialItem: _idx(widget.end));

  // 左右それぞれの「プログラム移動中」フラグ。片側を連動させても反対側の
  // ユーザー操作はブロックしない（共有フラグにするとフリング中に連動が伝わらず
  // 最小#＞最大# が成立してしまうため、左右で独立させる）。
  bool _syncingMin = false;
  bool _syncingMax = false;

  int get _max => math.max(1, widget.maxNumber);
  int _idx(int v) => v.clamp(1, _max) - 1;

  @override
  void didUpdateWidget(covariant _RangeMinMaxSelector old) {
    super.didUpdateWidget(old);
    // カテゴリ変更（総数変化）: 次フレームで両ホイールを新しい範囲へ再配置
    if (widget.maxNumber != old.maxNumber) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpMin(widget.start);
        _jumpMax(widget.end);
      });
      return;
    }
    // 外部要因で値が変わったらホイールを合わせる（ユーザー操作起因は既に一致）
    if (widget.start != old.start) _jumpMin(widget.start);
    if (widget.end != old.end) _jumpMax(widget.end);
  }

  /// 反対側ホイールを即座に合わせる（連動）。ジャンプ中はその側の onChanged を
  /// 無視して通知1回による無限ループを防ぐ。既に同じ位置なら何もしない。
  void _jumpMin(int v) {
    if (!_minCtrl.hasClients || _minCtrl.selectedItem == _idx(v)) return;
    _syncingMin = true;
    _minCtrl.jumpToItem(_idx(v));
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncingMin = false);
  }

  void _jumpMax(int v) {
    if (!_maxCtrl.hasClients || _maxCtrl.selectedItem == _idx(v)) return;
    _syncingMax = true;
    _maxCtrl.jumpToItem(_idx(v));
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncingMax = false);
  }

  void _onMin(int v) {
    if (_syncingMin) return;
    HapticFeedback.selectionClick();
    // 最小が最大を超えたら、最大を最小まで即連動（最小#≦最大# を必ず維持）
    if (v > widget.end) {
      _jumpMax(v);
      widget.onChanged(RangeValues(v.toDouble(), v.toDouble()));
    } else {
      widget.onChanged(RangeValues(v.toDouble(), widget.end.toDouble()));
    }
  }

  void _onMax(int v) {
    if (_syncingMax) return;
    HapticFeedback.selectionClick();
    // 最大が最小を下回ったら、最小を最大まで即連動
    if (v < widget.start) {
      _jumpMin(v);
      widget.onChanged(RangeValues(v.toDouble(), v.toDouble()));
    } else {
      widget.onChanged(RangeValues(widget.start.toDouble(), v.toDouble()));
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final count = _max;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _labeled('${s.rangeMin} #', _minCtrl, count, _onMin)),
        Padding(
          padding: const EdgeInsets.only(top: 34, left: 8, right: 8),
          child: Text('〜',
              style: AppTheme.bodyText.copyWith(color: AppTheme.textTertiary)),
        ),
        Expanded(child: _labeled('${s.rangeMax} #', _maxCtrl, count, _onMax)),
      ],
    );
  }

  Widget _labeled(String label, FixedExtentScrollController ctrl, int count,
      ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTheme.captionText.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DialPicker(controller: ctrl, count: count, min: 1, onChanged: onChanged),
      ],
    );
  }
}
