import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';

/// タップで1回、**押しっぱなしで加速して連続実行**するボタン。
/// ステッパーの − / ＋ に使う（ちまちま連打が不要）。
class HoldRepeatButton extends StatefulWidget {
  final IconData icon;

  /// null のとき無効（グレー・反応なし）。
  final VoidCallback? onTap;
  const HoldRepeatButton({super.key, required this.icon, required this.onTap});

  @override
  State<HoldRepeatButton> createState() => _HoldRepeatButtonState();
}

class _HoldRepeatButtonState extends State<HoldRepeatButton> {
  Timer? _timer;
  int _repeats = 0;

  void _fireOnce() {
    // 毎回 widget.onTap を読み直す（親の再ビルドで最新値に基づく処理になる）
    final cb = widget.onTap;
    if (cb == null) {
      _stop();
      return;
    }
    HapticFeedback.selectionClick();
    cb();
  }

  void _start() {
    if (widget.onTap == null) return;
    _fireOnce();
    _repeats = 0;
    _scheduleNext();
  }

  void _scheduleNext() {
    final ms = _repeats == 0 ? 400 : (260 - _repeats * 24).clamp(35, 260);
    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted || widget.onTap == null) {
        _stop();
        return;
      }
      _fireOnce();
      _repeats++;
      _scheduleNext();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => _start() : null,
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primaryLight : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(widget.icon,
            size: 22,
            color: enabled ? AppTheme.primary : AppTheme.textTertiary),
      ),
    );
  }
}

/// 数値ステッパー：**上に四角い数値入力欄（枠線なし）、下に − / ＋**。
/// − / ＋ は長押しで加速。直接入力も可能。値は親が保持し [onChanged] で受け取る。
class NumberStepper extends StatefulWidget {
  final String? label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const NumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.label,
  });

  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // フォーカスを外したら実際に採用された値へ揃える（範囲外入力の是正）
      if (!_focus.hasFocus) _controller.text = '${widget.value}';
    });
  }

  @override
  void didUpdateWidget(covariant NumberStepper old) {
    super.didUpdateWidget(old);
    // 外部要因（±・相互クランプ）で値が変わったら反映。入力中は触らない。
    if (!_focus.hasFocus && widget.value != old.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _emit(int v) => widget.onChanged(v.clamp(widget.min, widget.max));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!,
              textAlign: TextAlign.center,
              style: AppTheme.captionText
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
        ],
        // 四角い数値入力欄（枠線なし・淡色ベタ塗り）
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTheme.monoNumberLarge.copyWith(
              color: AppTheme.primary,
              fontSize: 22,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: (t) {
              final n = int.tryParse(t.trim());
              if (n != null) _emit(n);
            },
            onSubmitted: (_) => _focus.unfocus(),
            onTapOutside: (_) => _focus.unfocus(),
          ),
        ),
        const SizedBox(height: 8),
        // 下に − / ＋（長押し加速）
        Row(
          children: [
            Expanded(
              child: HoldRepeatButton(
                icon: Icons.remove_rounded,
                onTap: widget.value > widget.min
                    ? () => _emit(widget.value - 1)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HoldRepeatButton(
                icon: Icons.add_rounded,
                onTap: widget.value < widget.max
                    ? () => _emit(widget.value + 1)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
