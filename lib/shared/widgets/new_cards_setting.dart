import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';
import 'package:ship_it_english/shared/widgets/number_stepper.dart';

/// 「1日の新規カード数」を 1〜[maxValue] の範囲で指定する再利用ウィジェット。
/// 設定タブ・オンボーディングの両方で使う（値は settingsProvider に永続化）。
/// [label] を渡すとタイトル行を表示する。
class NewCardsSetting extends ConsumerWidget {
  final int maxValue;
  final String? label;

  const NewCardsSetting({
    super.key,
    this.maxValue = AppConstants.maxNewCardsSetting,
    this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isPro = ref.watch(isProProvider);
    final current = ref.watch(settingsProvider).newCardsPerDay;

    const min = AppConstants.minNewCardsPerDay;
    final maxAllowed = math.max(min, maxValue);
    // 無料プランは上限を絞る（サブスク無効時は isPro=true なので実質 maxAllowed）
    final effMax = isPro
        ? maxAllowed
        : math.min(maxAllowed, MonetizationConfig.freeMaxNewCardsPerDay);

    void apply(int v) {
      ref
          .read(settingsProvider.notifier)
          .setNewCardsPerDay(v.clamp(min, effMax));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label ?? strings.newCardsOnHome, style: AppTheme.bodyText),
        const SizedBox(height: 12),
        // 入力欄が上・−/＋が下（長押し加速）
        SizedBox(
          width: 150,
          child: NumberStepper(
            value: current,
            min: min,
            max: effMax,
            onChanged: apply,
          ),
        ),
        const SizedBox(height: 14),
        _NewCardsPresets(maxValue: maxValue, strings: strings),
        if (!isPro) ...[
          const SizedBox(height: 8),
          Text(strings.proSliderHint, style: AppTheme.captionText),
        ],
      ],
    );
  }
}

/// よく使う枚数をワンタップで選べるプリセット。末尾に「最大」。
class _NewCardsPresets extends ConsumerWidget {
  final int maxValue;
  final AppStrings strings;

  const _NewCardsPresets({required this.maxValue, required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider).newCardsPerDay;
    final isPro = ref.watch(isProProvider);

    void select(int value) {
      final target = value.clamp(AppConstants.minNewCardsPerDay, maxValue);
      if (!isPro && target > MonetizationConfig.freeMaxNewCardsPerDay) {
        ref
            .read(settingsProvider.notifier)
            .setNewCardsPerDay(MonetizationConfig.freeMaxNewCardsPerDay);
        context.push('/paywall');
        return;
      }
      ref.read(settingsProvider.notifier).setNewCardsPerDay(target);
    }

    final presets = [5, 10, 25, 50, 100].where((v) => v < maxValue).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in presets)
          _PresetChip(
            label: '$v',
            selected: current == v,
            onTap: () => select(v),
          ),
        _PresetChip(
          label: '${strings.newCardsMaxLabel} ($maxValue)',
          selected: current >= maxValue,
          onTap: () => select(maxValue),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: AppTheme.monoLabel.copyWith(
              color: selected ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
