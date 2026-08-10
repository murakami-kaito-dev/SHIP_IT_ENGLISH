import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';

/// 「1日の新規学習カード数」を 1〜[maxValue] の範囲で指定する再利用ウィジェット。
/// 設定タブ・オンボーディングの両方で使う（値は settingsProvider に永続化）。
///
/// 上部の3プリセット（マイペース/スタンダード/スピード学習）と下部のダイヤル
/// ピッカーが双方向に連動する。真実の源は `settingsProvider.newCardsPerDay` の
/// ただ1つ：プリセット押下→値更新→リスナーがピッカーを該当位置へスクロール、
/// ピッカー操作→値更新→該当プリセットが自動でアクティブになる。
class NewCardsSetting extends ConsumerStatefulWidget {
  final int maxValue;

  /// タイトル行を出すか（オンボーディングはページ側に見出しがあるので false）。
  final bool showHeading;

  const NewCardsSetting({
    super.key,
    this.maxValue = AppConstants.maxNewCardsSetting,
    this.showHeading = true,
  });

  @override
  ConsumerState<NewCardsSetting> createState() => _NewCardsSettingState();
}

class _NewCardsSettingState extends ConsumerState<NewCardsSetting> {
  static const _presetValues = [5, 10, 25];

  late final FixedExtentScrollController _controller;

  /// プログラムによるスクロール中は onSelectedItemChanged を無視して、
  /// プリセット→ピッカーの自動移動が値を二重更新／触覚を連打しないようにする。
  bool _programmatic = false;

  int get _min => AppConstants.minNewCardsPerDay;

  int get _effMax {
    final isPro = ref.read(isProProvider);
    final maxAllowed = math.max(_min, widget.maxValue);
    return isPro
        ? maxAllowed
        : math.min(maxAllowed, MonetizationConfig.freeMaxNewCardsPerDay);
  }

  @override
  void initState() {
    super.initState();
    final current = ref.read(settingsProvider).newCardsPerDay;
    final item = current.clamp(_min, _effMax) - _min;
    _controller = FixedExtentScrollController(initialItem: item);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 値を永続化する（範囲内へクランプ）。ピッカー・プリセットの共通経路。
  void _apply(int value) {
    ref
        .read(settingsProvider.notifier)
        .setNewCardsPerDay(value.clamp(_min, _effMax));
  }

  /// プリセット押下。無料プランで上限超過ならクランプしてパウォールへ。
  void _selectPreset(int value) {
    final isPro = ref.read(isProProvider);
    if (!isPro && value > MonetizationConfig.freeMaxNewCardsPerDay) {
      _apply(MonetizationConfig.freeMaxNewCardsPerDay);
      context.push('/paywall');
      return;
    }
    HapticFeedback.selectionClick();
    _apply(value);
  }

  /// 外部要因（プリセット押下・クランプ等）で値が変わったらピッカーを追従。
  void _syncWheel(int value) {
    if (!_controller.hasClients) return;
    final target = value.clamp(_min, _effMax) - _min;
    if (_controller.selectedItem == target) return;
    _programmatic = true;
    _controller
        .animateToItem(target,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic)
        .whenComplete(() => _programmatic = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isPro = ref.watch(isProProvider);
    final current = ref.watch(settingsProvider).newCardsPerDay;
    final effMax = _effMax;
    final count = effMax - _min + 1;

    // プリセット押下やクランプで値が動いたらダイヤルを該当位置へスクロール。
    ref.listen<int>(
      settingsProvider.select((s) => s.newCardsPerDay),
      (_, next) => _syncWheel(next),
    );

    final presetNames = <int, String>{
      5: strings.presetSteadyName,
      10: strings.presetStandardName,
      25: strings.presetSpeedName,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeading) ...[
          Text(
            strings.newStudyCardsHeading,
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
        ],
        // 上部: プリセットボタン（マイペース/スタンダード/スピード学習）
        Row(
          children: [
            for (var i = 0; i < _presetValues.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _PresetButton(
                  name: presetNames[_presetValues[i]]!,
                  value: _presetValues[i],
                  selected: current == _presetValues[i],
                  onTap: () => _selectPreset(_presetValues[i]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // 下部: ダイヤルピッカー（1〜effMax・1刻み・OS標準ライク）
        _DialPicker(
          controller: _controller,
          count: count,
          min: _min,
          onChanged: (value) {
            if (_programmatic) return;
            HapticFeedback.selectionClick();
            _apply(value);
          },
        ),
        if (!isPro) ...[
          const SizedBox(height: 8),
          Text(strings.proSliderHint, style: AppTheme.captionText),
        ],
      ],
    );
  }
}

/// 名前＋数値の2段プリセットボタン。選択中は primary 塗り、未選択は淡色。
class _PresetButton extends StatelessWidget {
  final String name;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.name,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppTheme.primary;
    return Material(
      color: selected ? AppTheme.primary : AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTheme.captionText.copyWith(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value',
                style: AppTheme.monoNumber.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS 標準ライクなダイヤルピッカー。中央の値が選択値。
class _DialPicker extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int count;
  final int min;
  final ValueChanged<int> onChanged;

  const _DialPicker({
    required this.controller,
    required this.count,
    required this.min,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: AppTheme.cardBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 44,
        diameterRatio: 1.25,
        squeeze: 1.05,
        useMagnifier: true,
        magnification: 1.12,
        // 中央のバンドを primary の淡色でハイライト（数字は透過して見える）。
        selectionOverlay: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSelectedItemChanged: (index) => onChanged(index + min),
        children: [
          for (var v = min; v < min + count; v++)
            Center(
              child: Text(
                '$v',
                style: AppTheme.monoNumber.copyWith(color: AppTheme.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
