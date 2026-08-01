import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';

/// 学習履歴カレンダー用: 学習した日付ごとの学習枚数
/// （'yyyy-MM-dd' → cards_studied）。0枚の日は含まない。
final studyDaysProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;
  return repo.getAllStudyDays();
});
