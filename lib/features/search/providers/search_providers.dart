import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

/// クエリ文字列に対する検索結果（2文字未満は空を返す）
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<CardWithStatus>, String>((ref, query) async {
  final trimmed = query.trim();
  if (trimmed.length < 2) return [];

  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;
  final results = await repo.searchCards(trimmed);
  return results
      .map(
        (r) => CardWithStatus(card: r.$1, rating: Rating.fromString(r.$2)),
      )
      .toList();
});
