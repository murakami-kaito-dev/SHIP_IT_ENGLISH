import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

class RatingButtons extends StatelessWidget {
  final AppStrings strings;
  final void Function(Rating rating) onRate;

  /// 各評価を選んだ場合の「次の復習までの待ち時間」。
  /// null（カード未めくり等でSRS状態が未取得）のときは間隔を出さない。
  final Map<Rating, Duration>? intervals;

  const RatingButtons({
    super.key,
    required this.strings,
    required this.onRate,
    this.intervals,
  });

  String? _sub(Rating r) {
    final d = intervals?[r];
    return d == null ? null : strings.nextReviewIn(d);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _RatingButton(
              label: strings.ratingForgot,
              subtitle: _sub(Rating.forgot),
              icon: Icons.close,
              color: AppTheme.ratingForgot,
              semanticsLabel: '${strings.ratingForgot} - forgot',
              onTap: () => onRate(Rating.forgot),
            ),
          ),
          const SizedBox(width: AppTheme.ratingButtonSpacing),
          Expanded(
            child: _RatingButton(
              label: strings.ratingUncertain,
              subtitle: _sub(Rating.uncertain),
              icon: Icons.remove,
              color: AppTheme.ratingUncertain,
              semanticsLabel: '${strings.ratingUncertain} - uncertain',
              onTap: () => onRate(Rating.uncertain),
            ),
          ),
          const SizedBox(width: AppTheme.ratingButtonSpacing),
          Expanded(
            flex: 2,
            child: _RatingButton(
              label: strings.ratingRemembered,
              subtitle: _sub(Rating.remembered),
              icon: Icons.check_circle_outline,
              color: AppTheme.ratingRemembered,
              semanticsLabel: '${strings.ratingRemembered} - remembered',
              onTap: () => onRate(Rating.remembered),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String semanticsLabel;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        BorderRadius.circular(AppTheme.ratingButtonBorderRadius);
    return Semantics(
      label: subtitle == null ? semanticsLabel : '$semanticsLabel ($subtitle)',
      button: true,
      child: Material(
        color: color.withOpacity(0.12),
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            height: AppTheme.ratingButtonHeight,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.buttonText
                            .copyWith(color: color, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                // 次の復習までの間隔（例: 「10分」「1日」「3日」）
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
