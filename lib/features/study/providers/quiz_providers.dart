import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/quiz.dart';

/// クイズの誤答（ダミー選択肢）用カードを同カテゴリから3枚取得する。
/// cardId シードの決定的シャッフルなので、同じカードには常に同じ誤答が付く
/// （リビルドで選択肢が入れ替わってちらつかない）。
final quizDistractorsProvider = FutureProvider.autoDispose
    .family<List<TechCard>, ({String cardId, String category})>(
        (ref, key) async {
  final repo = ref.watch(cardRepositoryProvider);
  final cards = await repo.getCardsByCategory(key.category);
  final others = cards.where((c) => c.id != key.cardId).toList()
    ..shuffle(Random(key.cardId.hashCode));
  return others.take(QuizConfig.distractorCount).toList();
});
