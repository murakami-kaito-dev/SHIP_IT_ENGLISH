import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

abstract class CardRepository {
  Future<List<TechCard>> getCardsForReview(DateTime asOf, {String? categoryId});

  /// [allowedCategories] を指定すると、そのカテゴリのカードのみ返す
  /// （無料プランのゲート用。null なら制限なし）
  Future<List<TechCard>> getNewCards({
    required int limit,
    String? categoryId,
    Set<String>? allowedCategories,
  });
  Future<List<TechCard>> getAllCards();
  Future<List<TechCard>> getCardsByCategory(String categoryId);
  Future<TechCard?> getCard(String id);
  Future<void> upsertCard(TechCard card);
  Future<LearningProgress?> getProgress(String cardId);
  Future<void> saveProgress(LearningProgress progress);
  Future<Map<String, int>> getCategoryProgress();
  Future<int> getTotalMasteredCount();
  Future<int> getTotalCardCount();
  Future<void> saveDailyStats(DailyStats stats);
  Future<void> resetAllData();
}
