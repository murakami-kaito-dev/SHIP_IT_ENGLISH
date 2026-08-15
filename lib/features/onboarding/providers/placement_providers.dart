import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';

/// 初期診断（かんたんレベル診断）に出す10枚。
/// 無料カテゴリから難易度をばらして決定的に選ぶ（やさしい4・ふつう3・むずかしい3）。
final placementCardsProvider =
    FutureProvider.autoDispose<List<TechCard>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  final categories = MonetizationConfig.freeCategoryIds.toList()..sort();
  final all = <TechCard>[];
  for (final c in categories) {
    all.addAll(await repo.getCardsByCategory(c));
  }
  all.sort((a, b) => a.id.compareTo(b.id));

  List<TechCard> take(int difficulty, int n) =>
      all.where((c) => c.difficulty == difficulty).take(n).toList();

  final picked = <TechCard>[...take(1, 4), ...take(2, 3), ...take(3, 3)];
  // 難易度の在庫が足りない場合の補完（通常は発生しない）
  for (final c in all) {
    if (picked.length >= 10) break;
    if (!picked.any((p) => p.id == c.id)) picked.add(c);
  }
  return picked;
});
