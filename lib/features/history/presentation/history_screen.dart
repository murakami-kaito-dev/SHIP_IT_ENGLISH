import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';
import 'package:ship_it_english/features/history/providers/history_providers.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';

/// 学習履歴カレンダー。日曜始まりの月カレンダーで、学習した日を色付き表示する。
/// 月を前後に送れる。外部パッケージは使わず自前グリッドで描画。
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _visibleMonth; // その月の1日
  DateTime? _selectedDate; // カレンダーで選択中の日（日別枚数の表示用）

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      // 表示していない月の選択は紛らわしいので解除する
      _selectedDate = null;
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      // 同じ日を再タップしたら選択解除
      _selectedDate =
          (_selectedDate != null && _selectedDate!.toDateString() == date.toDateString())
              ? null
              : date;
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _visibleMonth.year == now.year && _visibleMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final daysAsync = ref.watch(studyDaysProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(strings.historyTitle)),
        body: daysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(strings.genericError, style: AppTheme.bodyText)),
        data: (studyDays) {
          final totalDays = studyDays.length;
          final monthCount = _countInMonth(studyDays, _visibleMonth);
          final monthCards = _cardsInMonth(studyDays, _visibleMonth);
          final totalCards =
              studyDays.values.fold<int>(0, (sum, n) => sum + n);

          return SingleChildScrollView(
            padding: AppTheme.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MonthHeader(
                  month: _visibleMonth,
                  strings: strings,
                  onPrev: () => _shiftMonth(-1),
                  // 未来の月には進めない
                  onNext: _isCurrentMonth ? null : () => _shiftMonth(1),
                ),
                const SizedBox(height: 12),
                _CalendarGrid(
                  month: _visibleMonth,
                  studyDays: studyDays,
                  strings: strings,
                  selectedDate: _selectedDate,
                  onSelectDate: _selectDate,
                ),
                const SizedBox(height: 12),
                _SelectedDayDetail(
                  strings: strings,
                  selectedDate: _selectedDate,
                  studyDays: studyDays,
                ),
                const SizedBox(height: 20),
                _SummaryRow(
                  strings: strings,
                  monthDays: monthCount,
                  monthCards: monthCards,
                  totalDays: totalDays,
                  totalCards: totalCards,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: AppTheme.primary, label: strings.historyStudied, strings: strings),
                    const SizedBox(width: 20),
                    _LegendDot(
                        color: AppTheme.surfaceBorder,
                        label: strings.historyNotStudied,
                        strings: strings),
                  ],
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  int _countInMonth(Map<String, int> studyDays, DateTime month) {
    final prefix =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-';
    return studyDays.keys.where((d) => d.startsWith(prefix)).length;
  }

  /// その月に学習した「枚数」の合計（学習日数ではなくカード枚数）。
  int _cardsInMonth(Map<String, int> studyDays, DateTime month) {
    final prefix =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-';
    var sum = 0;
    studyDays.forEach((day, count) {
      if (day.startsWith(prefix)) sum += count;
    });
    return sum;
  }
}

/// 選択した日に学習した枚数を表示するパネル。未選択のときは操作ヒントを出す。
class _SelectedDayDetail extends StatelessWidget {
  final AppStrings strings;
  final DateTime? selectedDate;
  final Map<String, int> studyDays;

  const _SelectedDayDetail({
    required this.strings,
    required this.selectedDate,
    required this.studyDays,
  });

  @override
  Widget build(BuildContext context) {
    final date = selectedDate;
    if (date == null) {
      // 未選択: タップで日別枚数が見られることを案内
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_rounded,
              size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              strings.historyTapDayHint,
              style: AppTheme.captionText,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final count = studyDays[date.toDateString()] ?? 0;
    final studied = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Icon(
            studied ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 20,
            color: studied ? AppTheme.primary : AppTheme.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(strings.monthDayLabel(date), style: AppTheme.bodyText),
          ),
          Text(
            studied
                ? strings.historyDayCards(count)
                : strings.historyNoStudyThatDay,
            style: AppTheme.monoNumber.copyWith(
              color: studied ? AppTheme.primary : AppTheme.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final AppStrings strings;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthHeader({
    required this.month,
    required this.strings,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Text(
          strings.monthLabel(month),
          style: AppTheme.headingMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          // 未来の月へは進めない（onNext が null なら無効化）
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, int> studyDays;
  final AppStrings strings;
  final DateTime? selectedDate;
  final void Function(DateTime date) onSelectDate;

  const _CalendarGrid({
    required this.month,
    required this.studyDays,
    required this.strings,
    required this.selectedDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final isJa = strings.mode == LanguageMode.ja;
    final weekdayLabels = isJa
        ? const ['日', '月', '火', '水', '木', '金', '土']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    // 月の1日の曜日（日曜=0 になるよう調整。DateTime.weekday は 月=1..日=7）
    final firstWeekdayFromSunday = month.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now().toDateOnly();

    // グリッドのセル（先頭に空白、その後 1..daysInMonth）
    final cells = <Widget>[];
    for (var i = 0; i < firstWeekdayFromSunday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final key = date.toDateString();
      final studiedCount = studyDays[key];
      final studied = studiedCount != null && studiedCount > 0;
      final isToday = date == today;
      final isSelected =
          selectedDate != null && selectedDate!.toDateString() == key;
      cells.add(_DayCell(
        day: day,
        studied: studied,
        isToday: isToday,
        isSelected: isSelected,
        onTap: () => onSelectDate(date),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          // 曜日ヘッダー
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      weekdayLabels[i],
                      style: AppTheme.captionText.copyWith(
                        fontWeight: FontWeight.w600,
                        color: i == 0
                            ? AppTheme.ratingForgot
                            : (i == 6
                                ? AppTheme.primary
                                : AppTheme.textTertiary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool studied;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.studied,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 選択中は太めの primary 枠、今日は streakFire 枠で区別する
    final Border? border = isSelected
        ? Border.all(color: AppTheme.primaryDark, width: 2.5)
        : (isToday ? Border.all(color: AppTheme.streakFire, width: 2) : null);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: studied ? AppTheme.primaryGradient : null,
          color: studied ? null : AppTheme.background,
          shape: BoxShape.circle,
          border: border,
          boxShadow: studied
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 12,
            fontWeight: studied || isToday ? FontWeight.w700 : FontWeight.w500,
            color: studied ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final AppStrings strings;
  final int monthDays;
  final int monthCards;
  final int totalDays;
  final int totalCards;

  const _SummaryRow({
    required this.strings,
    required this.monthDays,
    required this.monthCards,
    required this.totalDays,
    required this.totalCards,
  });

  @override
  Widget build(BuildContext context) {
    // 学習「日数」と学習「枚数」の両方を、今月／累計で表示する
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(value: '$monthDays', label: strings.historyThisMonth),
            _Stat(value: '$totalDays', label: strings.historyTotalDays),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(value: '$monthCards', label: strings.historyThisMonthCards),
            _Stat(value: '$totalCards', label: strings.historyTotalCards),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.monoNumberLarge.copyWith(color: AppTheme.primary),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.captionText),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final AppStrings strings;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.captionText),
      ],
    );
  }
}
