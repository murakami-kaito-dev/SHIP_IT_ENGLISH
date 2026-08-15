import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/services/streak_manager.dart';
import 'package:ship_it_english/features/gamification/domain/badges.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/features/study/providers/units_providers.dart';

/// 獲得済みバッジ（id → 獲得日ISO8601）。prefs にJSONで永続化する。
class EarnedBadgesNotifier extends StateNotifier<Map<String, String>> {
  EarnedBadgesNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyEarnedBadges);
    if (raw == null) return;
    try {
      state = Map<String, String>.from(json.decode(raw) as Map);
    } catch (_) {
      // 壊れたJSONは無視（バッジは飾り。アプリを止めない）
    }
  }

  /// 現在値 [input] で新たに獲得したバッジを記録して返す（無ければ空）。
  Future<List<BadgeDef>> checkAndAward(BadgeInput input) async {
    final newly = newlyEarnedBadges(input, state.keys.toSet());
    if (newly.isEmpty) return const [];
    final now = DateTime.now().toIso8601String();
    state = {...state, for (final b in newly) b.id: now};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyEarnedBadges, json.encode(state));
    return newly;
  }
}

final earnedBadgesProvider =
    StateNotifierProvider<EarnedBadgesNotifier, Map<String, String>>(
  (ref) => EarnedBadgesNotifier(),
);

/// 現在の統計を集めてバッジ判定・新規獲得の記録を行う。
/// セッション完了・ユニットクリア後に呼ぶ（新規獲得があれば返り値で演出する）。
Future<List<BadgeDef>> checkAndAwardBadges(WidgetRef ref) async {
  final repo = ref.read(cardRepositoryProvider) as LocalCardRepository;
  final prefs = await SharedPreferences.getInstance();

  final counts = await repo.getStatusCounts();
  final studied = (counts['learning'] ?? 0) +
      (counts['review'] ?? 0) +
      (counts['mastered'] ?? 0);

  final input = BadgeInput(
    streak: await StreakManager().getStreakCount(),
    studied: studied,
    unitsCleared: ref.read(clearedUnitsProvider).length,
    perfectCount: prefs.getInt(AppConstants.keyPerfectSessions) ?? 0,
    level: ref.read(gamificationProvider).snapshot.level,
  );

  return ref.read(earnedBadgesProvider.notifier).checkAndAward(input);
}
