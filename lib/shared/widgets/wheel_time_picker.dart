import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// 時・分の2連ホイールで時刻を選ぶボトムシートを開く。
///
/// Material の [showTimePicker]（アナログ時計の文字盤）は、24時間制だと内周と
/// 外周に数字が二重に並び「今どちらを選んでいるのか」が読み取りにくい。数字を
/// 縦に回すホイールなら現在値が常に中央の1つに定まるため、そちらに置き換える。
///
/// 見た目は [DialPicker]（学習枚数・リスニング範囲）と同じ数値・同じ
/// ハイライト帯に揃えてあり、アプリ内でダイヤル操作の印象が一貫する。
///
/// キャンセル時は null を返す。
Future<TimeOfDay?> showWheelTimePicker({
  required BuildContext context,
  required AppStrings strings,
  required int initialHour,
  required int initialMinute,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _WheelTimePickerSheet(
      strings: strings,
      initialHour: initialHour,
      initialMinute: initialMinute,
    ),
  );
}

class _WheelTimePickerSheet extends StatefulWidget {
  final AppStrings strings;
  final int initialHour;
  final int initialMinute;

  const _WheelTimePickerSheet({
    required this.strings,
    required this.initialHour,
    required this.initialMinute,
  });

  @override
  State<_WheelTimePickerSheet> createState() => _WheelTimePickerSheetState();
}

class _WheelTimePickerSheetState extends State<_WheelTimePickerSheet> {
  late final FixedExtentScrollController _hourCtrl =
      FixedExtentScrollController(initialItem: widget.initialHour);
  late final FixedExtentScrollController _minuteCtrl =
      FixedExtentScrollController(initialItem: widget.initialMinute);

  late int _hour = widget.initialHour;
  late int _minute = widget.initialMinute;

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    strings.cancel,
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    strings.reminderTime,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    TimeOfDay(hour: _hour, minute: _minute),
                  ),
                  child: Text(
                    strings.pickerConfirm,
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 見出しは「時」「分」を列の上に置く。数字に付けると英語モードで
            // 不自然になる（"08時" ↔ "08Hour"）ため、列見出しに逃がしている。
            Row(
              children: [
                Expanded(child: _columnLabel(strings.hourLabel)),
                const SizedBox(width: 24),
                Expanded(child: _columnLabel(strings.minuteLabel)),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 176,
              child: Stack(
                children: [
                  // 選択中の行を示す帯。2つのホイールにまたがって1本置くことで
                  // 「時と分で1つの時刻」であることが見た目で分かる。
                  Center(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _wheel(
                          controller: _hourCtrl,
                          count: 24,
                          selected: _hour,
                          onChanged: (v) => setState(() => _hour = v),
                        ),
                      ),
                      Text(
                        ':',
                        style: AppTheme.monoNumberLarge.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: _wheel(
                          controller: _minuteCtrl,
                          count: 60,
                          selected: _minute,
                          onChanged: (v) => setState(() => _minute = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _columnLabel(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.captionText,
      );

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 44,
      diameterRatio: 1.25,
      squeeze: 1.05,
      useMagnifier: true,
      magnification: 1.12,
      // ハイライト帯は Stack 側で2列にまたがって描くのでここでは出さない。
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: (index) {
        HapticFeedback.selectionClick();
        onChanged(index);
      },
      children: [
        for (var v = 0; v < count; v++)
          Center(
            child: Text(
              v.toString().padLeft(2, '0'),
              style: AppTheme.monoNumber.copyWith(
                color: v == selected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
