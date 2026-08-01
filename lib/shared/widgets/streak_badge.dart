import 'package:flutter/material.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

class StreakBadge extends StatelessWidget {
  final int count;
  final AppStrings strings;

  /// タップ時のコールバック（学習カレンダーを開くなど）。null ならタップ不可。
  final VoidCallback? onTap;

  const StreakBadge({
    super.key,
    required this.count,
    required this.strings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          color: count > 0 ? AppTheme.streakFire : AppTheme.streakInactive,
          size: 26,
        ),
        const SizedBox(width: 5),
        Text(
          strings.streak(count),
          style: AppTheme.monoNumber.copyWith(
            fontSize: 17,
            color: count > 0 ? AppTheme.streakFire : AppTheme.textTertiary,
          ),
        ),
        // タップできることを示すカレンダーアイコン
        if (onTap != null) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.calendar_month_outlined,
            size: 18,
            color: AppTheme.textTertiary,
          ),
        ],
      ],
    );

    return Semantics(
      label: '$count day streak',
      button: onTap != null,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: content,
              ),
            ),
    );
  }
}
