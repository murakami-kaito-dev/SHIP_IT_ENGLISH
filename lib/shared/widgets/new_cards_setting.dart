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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label ?? strings.newCardsOnHome,
                  style: AppTheme.bodyText),
            ),
            const SizedBox(width: 12),
            _NewCardsStepper(maxValue: maxValue),
          ],
        ),
        const SizedBox(height: 10),
        _NewCardsPresets(maxValue: maxValue, strings: strings),
        if (!isPro) ...[
          const SizedBox(height: 8),
          Text(strings.proSliderHint, style: AppTheme.captionText),
        ],
      ],
    );
  }
}

/// 新規カード数を「− [直接入力] ＋」で 1〜[maxValue] の範囲で指定するステッパー。
class _NewCardsStepper extends ConsumerStatefulWidget {
  final int maxValue;

  const _NewCardsStepper({required this.maxValue});

  @override
  ConsumerState<_NewCardsStepper> createState() => _NewCardsStepperState();
}

class _NewCardsStepperState extends ConsumerState<_NewCardsStepper> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: '${ref.read(settingsProvider).newCardsPerDay}');
    _focus.addListener(() {
      if (!_focus.hasFocus) _commitText();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  int get _min => AppConstants.minNewCardsPerDay;
  int get _max => math.max(_min, widget.maxValue);

  void _syncText(int value) {
    final text = '$value';
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  /// 値を確定する。範囲外はクランプし、無料プランの上限超過はパウォールへ誘導。
  void _apply(int value) {
    final notifier = ref.read(settingsProvider.notifier);
    final isPro = ref.read(isProProvider);
    var target = value.clamp(_min, _max);

    if (!isPro && target > MonetizationConfig.freeMaxNewCardsPerDay) {
      target = MonetizationConfig.freeMaxNewCardsPerDay;
      notifier.setNewCardsPerDay(target);
      _syncText(target);
      context.push('/paywall');
      return;
    }
    notifier.setNewCardsPerDay(target);
    _syncText(target);
  }

  /// 入力するそばから即確定（範囲内にクランプ。入力中はテキストを書き換えない）。
  void _liveApply(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return;
    final clamped = parsed.clamp(_min, _max);
    ref.read(settingsProvider.notifier).setNewCardsPerDay(clamped);
  }

  void _commitText() {
    final parsed = int.tryParse(_controller.text.trim());
    _apply(parsed ?? ref.read(settingsProvider).newCardsPerDay);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(settingsProvider).newCardsPerDay;
    if (!_focus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focus.hasFocus) _syncText(current);
      });
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          onTap: current > _min ? () => _apply(current - 1) : null,
        ),
        SizedBox(
          width: 64,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTheme.monoNumber.copyWith(color: AppTheme.primary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(),
            ),
            onChanged: _liveApply,
            onSubmitted: (_) => _commitText(),
            onTapOutside: (_) => _focus.unfocus(),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          onTap: current < _max ? () => _apply(current + 1) : null,
        ),
      ],
    );
  }
}

/// ステッパーの ± ボタン（丸型・無効時はグレー）
class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppTheme.primaryLight : AppTheme.background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon,
              size: 20,
              color: enabled ? AppTheme.primary : AppTheme.textTertiary),
        ),
      ),
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
