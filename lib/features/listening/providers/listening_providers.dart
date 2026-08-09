import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/services/tts_service.dart';
import 'package:ship_it_english/features/listening/domain/listening_state.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';

/// 耳学の対象カードを取得する条件（学習の範囲指定と同じ項目＋ランダム）。
class ListenConfig {
  final String categoryId;
  final int from;
  final int to;
  final Set<String> statuses; // 空=全状況
  final bool random;

  const ListenConfig({
    required this.categoryId,
    required this.from,
    required this.to,
    required this.statuses,
    required this.random,
  });

  @override
  bool operator ==(Object other) =>
      other is ListenConfig &&
      other.categoryId == categoryId &&
      other.from == from &&
      other.to == to &&
      other.random == random &&
      setEquals(other.statuses, statuses);

  @override
  int get hashCode => Object.hash(
      categoryId, from, to, random, Object.hashAllUnordered(statuses));
}

/// 条件に一致するカードを取得（学習の範囲指定と同じクエリを流用）。
final listeningCardsProvider = FutureProvider.autoDispose
    .family<List<TechCard>, ListenConfig>((ref, config) async {
  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;
  return repo.getCategoryStudyCards(
    categoryId: config.categoryId,
    from: config.from,
    to: config.to,
    statuses: config.statuses,
    random: config.random,
  );
});

/// 行間・カード間の「間（ま）」。
const _lineGap = Duration(milliseconds: 400);
const _cardGap = Duration(milliseconds: 800);

/// 耳学プレイヤーの再生を駆動する。SRS/ストリーク/XPには一切影響しない。
class ListeningController extends StateNotifier<ListeningState> {
  final TtsService _tts;

  /// 再生シーケンスの世代。停止/スキップ/並べ替えで無効化して古いループを止める。
  int _runToken = 0;

  ListeningController(this._tts) : super(ListeningState.initial) {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final speed = prefs.getDouble(AppConstants.keyListenSpeed) ?? 1.0;
    final repeat = prefs.getBool(AppConstants.keyListenRepeat) ?? false;
    state = state.copyWith(
      speed: kListenSpeeds.contains(speed) ? speed : 1.0,
      repeat: repeat,
    );
  }

  /// カード集合をセットして先頭から自動再生する。
  void load(List<TechCard> cards, LanguageMode mode) {
    _runToken++;
    state = state.copyWith(
      queue: List<TechCard>.from(cards),
      index: 0,
      line: 0,
      finished: false,
      mode: mode,
      isPlaying: false,
    );
    if (cards.isNotEmpty) play();
  }

  void play() {
    if (state.isEmpty || state.isPlaying) return;
    state = state.copyWith(isPlaying: true, finished: false);
    final token = ++_runToken;
    unawaited(_runLoop(token));
  }

  void pause() {
    _runToken++; // 進行中のループを無効化
    state = state.copyWith(isPlaying: false);
    unawaited(_tts.stop());
  }

  void togglePlay() => state.isPlaying ? pause() : play();

  void next() => _seek(state.index + 1, autoplay: state.isPlaying);
  void previous() => _seek(state.index - 1, autoplay: state.isPlaying);

  /// キュー内の特定カードへ移動して再生する。
  void jumpTo(int index) => _seek(index, autoplay: true);

  void _seek(int target, {required bool autoplay}) {
    if (state.isEmpty) return;
    final clamped = target.clamp(0, state.queue.length - 1);
    _runToken++;
    unawaited(_tts.stop());
    state = state.copyWith(
        index: clamped, line: 0, finished: false, isPlaying: false);
    if (autoplay) play();
  }

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
    _persist();
    // 現在の行はそのまま。次の行から新しい速度が反映される。
  }

  void toggleRepeat() {
    state = state.copyWith(repeat: !state.repeat);
    _persist();
  }

  /// 「次に再生」キューの並べ替え（再生中のカードは追従して再生を継続）。
  void reorder(int oldIndex, int newIndex) {
    final list = List<TechCard>.from(state.queue);
    if (newIndex > oldIndex) newIndex -= 1;
    final currentId = state.current?.id;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final newIdx =
        currentId == null ? state.index : list.indexWhere((c) => c.id == currentId);
    state = state.copyWith(queue: list, index: newIdx < 0 ? state.index : newIdx);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyListenSpeed, state.speed);
    await prefs.setBool(AppConstants.keyListenRepeat, state.repeat);
  }

  Future<void> _runLoop(int token) async {
    while (token == _runToken && state.isPlaying) {
      final card = state.current;
      if (card == null) return;
      final lines = speechLinesFor(card, state.mode);

      // 現在の行から最後まで読み上げる
      for (var li = state.line; li < lines.length; li++) {
        if (token != _runToken || !state.isPlaying) return;
        state = state.copyWith(line: li);
        await _tts.speakAndWait(lines[li].text, lines[li].locale,
            rate: state.speed);
        if (token != _runToken || !state.isPlaying) return;
        if (li < lines.length - 1) {
          await _gap(_lineGap, token);
          if (token != _runToken || !state.isPlaying) return;
        }
      }

      // 次のカードへ
      final isLast = state.index >= state.queue.length - 1;
      if (isLast) {
        if (state.repeat) {
          await _gap(_cardGap, token);
          if (token != _runToken || !state.isPlaying) return;
          state = state.copyWith(index: 0, line: 0);
        } else {
          state = state.copyWith(isPlaying: false, finished: true, line: 0);
          return;
        }
      } else {
        await _gap(_cardGap, token);
        if (token != _runToken || !state.isPlaying) return;
        state = state.copyWith(index: state.index + 1, line: 0);
      }
    }
  }

  /// キャンセル可能な待機（token が変わったら即座に抜ける）。
  Future<void> _gap(Duration d, int token) async {
    const step = Duration(milliseconds: 50);
    var elapsed = Duration.zero;
    while (elapsed < d) {
      if (token != _runToken || !state.isPlaying) return;
      await Future<void>.delayed(step);
      elapsed += step;
    }
  }

  @override
  void dispose() {
    _runToken++;
    unawaited(_tts.stop());
    super.dispose();
  }
}

final listeningControllerProvider = StateNotifierProvider.autoDispose<
    ListeningController, ListeningState>((ref) {
  return ListeningController(TtsService());
});
