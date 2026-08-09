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
class ListeningScreen extends ConsumerStatefulWidget {
  final ListenConfig config;
  const ListeningScreen({super.key, required this.config});

  @override
  ConsumerState<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends ConsumerState<ListeningScreen> {
  bool _loaded = false;

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
            // 取得できたカードを一度だけコントローラーに渡して自動再生を開始
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
            return _buildPlayer(context, st, strings);
          },
        ),
      ),
    );
  }

  Widget _buildPlayer(
      BuildContext context, ListeningState st, AppStrings strings) {
    final controller = ref.read(listeningControllerProvider.notifier);
    final card = st.current!;
    final lines = speechLinesFor(card, st.mode);

    return Stack(
      children: [
        // メインのプレイヤー（下部のキューシートに隠れないよう余白を確保）
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            children: [
              // 進捗
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
              // 現在のカード（4行・再生中の行をハイライト）
              Expanded(
                child: SingleChildScrollView(
                  child: _NowCard(card: card, lines: lines, activeLine: st.line),
                ),
              ),
              const SizedBox(height: 12),
              // 速度・繰り返し
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RepeatToggle(
                    on: st.repeat,
                    label: strings.listenRepeat,
                    onTap: controller.toggleRepeat,
                  ),
                  _SpeedSelector(
                    speed: st.speed,
                    onSelect: controller.setSpeed,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 再生コントロール
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
            ],
          ),
        ),
        // 「次に再生」キュー（上スワイプで展開・ドラッグで並べ替え）
        _QueueSheet(state: st, strings: strings, controller: controller),
      ],
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
              child: Icon(Icons.graphic_eq_rounded, size: 16, color: Colors.white),
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
          border: Border.all(
              color: on ? AppTheme.primary : AppTheme.surfaceBorder),
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

/// 「次に再生」キュー。上スワイプで展開し、右のハンドルをドラッグで並べ替える。
class _QueueSheet extends StatelessWidget {
  final ListeningState state;
  final AppStrings strings;
  final ListeningController controller;
  const _QueueSheet(
      {required this.state, required this.strings, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.14,
      minChildSize: 0.14,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.queue_music_rounded,
                        size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(strings.listenUpNext, style: AppTheme.headingMedium),
                    const Spacer(),
                    Text(
                      strings.listenProgress(
                          state.index + 1, state.queue.length),
                      style: AppTheme.captionText,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: state.queue.length,
                  onReorder: controller.reorder,
                  itemBuilder: (context, i) {
                    final card = state.queue[i];
                    final isCurrent = i == state.index;
                    // jaモード=英語を主表示 / enモード=日本語を主表示
                    final title = state.mode == LanguageMode.ja
                        ? card.phrase
                        : card.translation;
                    final subtitle = state.mode == LanguageMode.ja
                        ? card.translation
                        : card.phrase;
                    return Material(
                      key: ValueKey(card.id),
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => controller.jumpTo(i),
                        leading: isCurrent
                            ? const Icon(Icons.graphic_eq_rounded,
                                color: AppTheme.primary)
                            : Text(
                                cardNumberShort(card),
                                style: AppTheme.monoLabel
                                    .copyWith(color: AppTheme.textTertiary),
                              ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyText.copyWith(
                            fontWeight:
                                isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color:
                                isCurrent ? AppTheme.primary : AppTheme.textPrimary,
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
                            child: Icon(Icons.drag_handle_rounded,
                                color: AppTheme.textTertiary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
