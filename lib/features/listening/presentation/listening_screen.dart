import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/listening/domain/listening_state.dart';
import 'package:ship_it_english/features/listening/providers/listening_providers.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';
import 'package:ship_it_english/shared/widgets/card_number_label.dart';

/// 耳学（リスニング）プレイヤー。指定条件のカードを1枚=4行の順で自動再生する。
/// 学習（SRS評価）とは独立しており、ストリーク・XPには影響しない。
///
/// 画面は縦スクロール1枚：最初の画面いっぱいが再生画面で、**下にスクロールすると
/// 続きとして「次に再生」キュー**が現れる（別画面ではなく画面の続き）。
class ListeningScreen extends ConsumerStatefulWidget {
  final ListenConfig config;
  const ListeningScreen({super.key, required this.config});

  @override
  ConsumerState<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends ConsumerState<ListeningScreen> {
  bool _loaded = false;
  final _scrollController = ScrollController();
  double _viewportH = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 下の「次に再生」キューへスクロールして見せる（ハンドルのタップ用）。
  void _revealQueue() {
    if (!_scrollController.hasClients) return;
    final target = _viewportH > 0
        ? _viewportH
        : _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final cardsAsync = ref.watch(listeningCardsProvider(widget.config));
    final st = ref.watch(listeningControllerProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('🎧 ${strings.listenTitle}'),
        ),
        body: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(strings.loadError, style: AppTheme.bodyText),
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return Center(
                child: Text(strings.rangeNoMatch, style: AppTheme.bodyText),
              );
            }
            if (!_loaded) {
              _loaded = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(listeningControllerProvider.notifier)
                    .load(cards, strings.mode);
              });
            }
            if (st.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildScroll(context, st, strings);
          },
        ),
      ),
    );
  }

  Widget _buildScroll(
      BuildContext context, ListeningState st, AppStrings strings) {
    final controller = ref.read(listeningControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportH = constraints.maxHeight;
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 1枚目の画面いっぱい＝再生画面
            SliverToBoxAdapter(
              child: SizedBox(
                height: _viewportH,
                child: _PlayerBody(
                  st: st,
                  strings: strings,
                  controller: controller,
                  onRevealQueue: _revealQueue,
                ),
              ),
            ),
            // 続きとして下に「次に再生」キュー
            SliverToBoxAdapter(child: _QueueHeader(st: st, strings: strings)),
            SliverReorderableList(
              itemCount: st.queue.length,
              onReorder: controller.reorder,
              itemBuilder: (context, i) =>
                  _queueTile(context, st, controller, i),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }

  Widget _queueTile(BuildContext context, ListeningState st,
      ListeningController controller, int i) {
    final card = st.queue[i];
    final isCurrent = i == st.index;
    final title =
        st.mode == LanguageMode.ja ? card.phrase : card.translation;
    final subtitle =
        st.mode == LanguageMode.ja ? card.translation : card.phrase;
    return Material(
      key: ValueKey(card.id),
      color: Colors.transparent,
      child: ListTile(
        onTap: () => controller.jumpTo(i),
        leading: isCurrent
            ? const Icon(Icons.graphic_eq_rounded, color: AppTheme.primary)
            : Text(
                cardNumberShort(card),
                style:
                    AppTheme.monoLabel.copyWith(color: AppTheme.textTertiary),
              ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyText.copyWith(
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            color: isCurrent ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.captionText,
        ),
        trailing: ReorderableDragStartListener(
          index: i,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child:
                Icon(Icons.drag_handle_rounded, color: AppTheme.textTertiary),
          ),
        ),
      ),
    );
  }
}

/// 再生画面（1枚目の画面いっぱい）。
class _PlayerBody extends StatelessWidget {
  final ListeningState st;
  final AppStrings strings;
  final ListeningController controller;
  final VoidCallback onRevealQueue;
  const _PlayerBody({
    required this.st,
    required this.strings,
    required this.controller,
    required this.onRevealQueue,
  });

  @override
  Widget build(BuildContext context) {
    final card = st.current!;
    final lines = speechLinesFor(card, st.mode);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                st.finished ? strings.listenFinished : strings.listenNowPlaying,
                style: AppTheme.captionText.copyWith(
                  color: st.finished ? AppTheme.ratingRemembered : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                strings.listenProgress(st.index + 1, st.queue.length),
                style: AppTheme.monoLabel.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: _NowCard(card: card, lines: lines, activeLine: st.line),
            ),
          ),
          const SizedBox(height: 12),
          // 全体シークバー（つまみをドラッグでその位置のカードから再生）
          _SeekBar(
            index: st.index,
            total: st.queue.length,
            onSeek: controller.jumpTo,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RepeatToggle(
                on: st.repeat,
                label: strings.listenRepeat,
                onTap: controller.toggleRepeat,
              ),
              _SpeedSelector(speed: st.speed, onSelect: controller.setSpeed),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 34,
                color: AppTheme.textSecondary,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: controller.previous,
              ),
              const SizedBox(width: 12),
              _PlayButton(
                playing: st.isPlaying,
                finished: st.finished,
                onTap: () {
                  if (st.finished) {
                    controller.jumpTo(0);
                  } else {
                    controller.togglePlay();
                  }
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                iconSize: 34,
                color: AppTheme.textSecondary,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: controller.next,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 下にスクロール（または タップ）で「次に再生」キューへ
          _RevealHandle(
            label: strings.listenUpNext,
            count: st.queue.length,
            onTap: onRevealQueue,
          ),
        ],
      ),
    );
  }
}

/// 全体の再生位置を表すシークバー。つまみをドラッグしてその位置のカードへ移動。
class _SeekBar extends StatefulWidget {
  final int index;
  final int total;
  final ValueChanged<int> onSeek;
  const _SeekBar(
      {required this.index, required this.total, required this.onSeek});

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag; // ドラッグ中の一時値（離すまで再生位置は動かさない）

  @override
  Widget build(BuildContext context) {
    final total = widget.total;
    final maxV = (total - 1).toDouble();
    final value =
        (_drag ?? widget.index.toDouble()).clamp(0.0, maxV < 0 ? 0.0 : maxV);
    final shown = value.round() + 1;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.surfaceBorder,
            thumbColor: AppTheme.primary,
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 16),
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: maxV <= 0 ? 1 : maxV,
            divisions: total > 1 ? total - 1 : null,
            onChanged: total > 1
                ? (v) => setState(() => _drag = v)
                : null,
            onChangeEnd: (v) {
              widget.onSeek(v.round());
              setState(() => _drag = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$shown', style: AppTheme.monoLabel),
              Text('$total', style: AppTheme.monoLabel),
            ],
          ),
        ),
      ],
    );
  }
}

class _QueueHeader extends StatelessWidget {
  final ListeningState st;
  final AppStrings strings;
  const _QueueHeader({required this.st, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.queue_music_rounded,
              size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(strings.listenUpNext, style: AppTheme.headingMedium),
          const Spacer(),
          Text(
            strings.listenProgress(st.index + 1, st.queue.length),
            style: AppTheme.captionText,
          ),
        ],
      ),
    );
  }
}

/// 再生中のカード（カテゴリ番号＋4行）。再生中の行を強調表示する。
class _NowCard extends StatelessWidget {
  final TechCard card;
  final List<SpeechLine> lines;
  final int activeLine;
  const _NowCard(
      {required this.card, required this.lines, required this.activeLine});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardNumberLabel(card).toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 11,
              letterSpacing: 1,
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < lines.length; i++)
            _LineRow(line: lines[i], active: i == activeLine),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final SpeechLine line;
  final bool active;
  const _LineRow({required this.line, required this.active});

  @override
  Widget build(BuildContext context) {
    final isEn = line.locale == 'en-US';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white.withOpacity(0.22) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: Colors.white.withOpacity(0.55), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              isEn ? 'EN' : 'JP',
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              line.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.white,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          if (active) ...[
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child:
                  Icon(Icons.graphic_eq_rounded, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool playing;
  final bool finished;
  final VoidCallback onTap;
  const _PlayButton(
      {required this.playing, required this.finished, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = finished
        ? Icons.replay_rounded
        : (playing ? Icons.pause_rounded : Icons.play_arrow_rounded);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppTheme.buttonShadow,
        ),
        child: Icon(icon, size: 36, color: Colors.white),
      ),
    );
  }
}

class _RepeatToggle extends StatelessWidget {
  final bool on;
  final String label;
  final VoidCallback onTap;
  const _RepeatToggle(
      {required this.on, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: on ? AppTheme.primary : AppTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded,
                size: 16,
                color: on ? AppTheme.primary : AppTheme.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.captionText.copyWith(
                color: on ? AppTheme.primary : AppTheme.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onSelect;
  const _SpeedSelector({required this.speed, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in kListenSpeeds)
            GestureDetector(
              onTap: () => onSelect(s),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: s == speed ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${s % 1 == 0 ? s.toStringAsFixed(1) : s}×',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s == speed ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 「次に再生」へスクロールを誘導する下部ハンドル（︾ ＋件数）。
class _RevealHandle extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  const _RevealHandle(
      {required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ($count)',
              style: AppTheme.captionText.copyWith(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 22, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
