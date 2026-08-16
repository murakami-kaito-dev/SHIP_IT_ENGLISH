import 'dart:math' as math;

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
import 'package:ship_it_english/shared/widgets/dial_picker.dart';

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

  /// 今日すでに学習した新規カード数。null以外を渡すと、上限を変えたときの
  /// 「今日への影響」（今日すでに◯枚学習 → 今日はあと◯枚）をライブ表示する。
  /// 設定タブでのみ使う（オンボーディングは学習前なので不要）。
  final int? todayStudiedNew;

  const NewCardsSetting({
    super.key,
    this.maxValue = AppConstants.maxNewCardsSetting,
    this.showHeading = true,
    this.todayStudiedNew,
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
        // 下部: ダイヤルピッカー（1〜effMax・1刻み・OS標準ライク。共通 DialPicker）
        DialPicker(
          controller: _controller,
          count: count,
          min: _min,
          onChanged: (value) {
            if (_programmatic) return;
            HapticFeedback.selectionClick();
            _apply(value);
          },
        ),
        // 上限を変えた瞬間に「今日あと何枚学べるか」が分かるライブ表示（1c）。
        // 例: 5枚学習後に上限を2へ下げる → 「今日はあと0枚」と即座に見える。
        if (widget.todayStudiedNew != null) ...[
          const SizedBox(height: 8),
          Text(
            strings.newCardsTodayImpact(
              widget.todayStudiedNew!,
              (current - widget.todayStudiedNew!).clamp(0, current),
            ),
            style: AppTheme.captionText.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 名前は幅に合わせて自動縮小し、必ず全文が1行で収まるようにする
              // （「スタンダード」「スピード学習」が省略されないように）。
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTheme.captionText.copyWith(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

