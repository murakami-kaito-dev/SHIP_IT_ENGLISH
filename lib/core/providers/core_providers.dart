import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/database/database_helper.dart';
import 'package:ship_it_english/features/study/data/card_repository.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/features/study/domain/srs_engine.dart';

final databaseProvider = Provider<DatabaseHelper>((ref) {
  throw UnimplementedError('Override in main.dart ProviderScope');
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalCardRepository(db);
});

final srsEngineProvider = Provider<SrsEngine>((ref) => SrsEngine());
