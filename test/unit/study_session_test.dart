import 'package:flutter_test/flutter_test.dart';
import 'package:ship_it_english/features/study/data/card_repository.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:ship_it_english/features/study/domain/srs_engine.dart';
import 'package:ship_it_english/features/study/providers/study_providers.dart';

/// loadSession / rateCard で使うメソッドだけ持つ最小のフェイク。
/// getProgress は常に「未学習」を返し、saveProgress は結果を溜めておく。
class _FakeRepo implements CardRepository {
  final List<TechCard> reviewCards;
  final List<TechCard> newCards;
  final Map<String, LearningProgress> saved = {};

  _FakeRepo({this.reviewCards = const [], this.newCards = const []});

  @override
  Future<List<TechCard>> getCardsForReview(DateTime asOf,
          {String? categoryId}) async =>
      reviewCards;

  @override
  Future<List<TechCard>> getNewCards(
          {required int limit,
          String? categoryId,
          Set<String>? allowedCategories}) async =>
      newCards.take(limit).toList();

  @override
  Future<LearningProgress?> getProgress(String cardId) async => saved[cardId];

  @override
  Future<void> saveProgress(LearningProgress progress) async {
    saved[progress.cardId] = progress;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

TechCard _card(String id) => TechCard(
      id: id,
      phrase: 'phrase $id',
      translation: 'trans $id',
      example: 'ex $id',
      exampleTranslation: 'exja $id',
      context: 'ctx $id',
      category: 'code_review',
      difficulty: 1,
      createdAt: DateTime(2026, 1, 1),
    );

/// カードを1枚 flip して評価する
Future<void> _flipAndRate(
    StudySessionNotifier notifier, Rating rating) async {
  await notifier.flipCard();
  await notifier.rateCard(rating);
}

void main() {
  group('学習セッションは設定枚数で完了する', () {
    test('新規5枚を「覚えてた」で評価するとphase=completed・currentCard=null', () async {
      final repo = _FakeRepo(
        newCards: List.generate(5, (i) => _card('new_$i')),
      );
      final notifier = StudySessionNotifier(repo, SrsEngine());
      await notifier.loadSession(maxNewCards: 5);

      expect(notifier.state.totalUniqueCount, 5);
      expect(notifier.state.phase, StudyPhase.studying);

      // 5枚評価しきる（安全のため上限を付けて無限ループを検出）
      var guard = 0;
      while (notifier.state.phase != StudyPhase.completed && guard < 50) {
        await _flipAndRate(notifier, Rating.remembered);
        guard++;
      }

      expect(notifier.state.phase, StudyPhase.completed,
          reason: 'セッションは有限回で完了しなければならない（無限ループ防止）');
      expect(notifier.state.queue, isEmpty);
      expect(notifier.state.currentCard, isNull,
          reason: '完了時は currentCard を null にして再表示を防ぐ');
      expect(notifier.state.completedUniqueCount, 5);
      expect(guard, 5, reason: 'ちょうど5回の評価で終わるべき');
    });

    test('復習3枚+新規2枚も全部評価すると完了する', () async {
      final repo = _FakeRepo(
        reviewCards: List.generate(3, (i) => _card('rev_$i')),
        newCards: List.generate(2, (i) => _card('new_$i')),
      );
      final notifier = StudySessionNotifier(repo, SrsEngine());
      await notifier.loadSession(maxNewCards: 5);

      expect(notifier.state.totalUniqueCount, 5);

      var guard = 0;
      while (notifier.state.phase != StudyPhase.completed && guard < 50) {
        await _flipAndRate(notifier, Rating.remembered);
        guard++;
      }

      expect(notifier.state.phase, StudyPhase.completed);
      expect(notifier.state.currentCard, isNull);
      expect(notifier.state.completedUniqueCount, 5);
    });

    test('「忘れた」は最大2回まで再出題され、その後は完了する', () async {
      final repo = _FakeRepo(newCards: [_card('new_0')]);
      final notifier = StudySessionNotifier(repo, SrsEngine());
      await notifier.loadSession(maxNewCards: 1);

      // ずっと「忘れた」でも、再出題は上限2回なので必ず終わる
      var guard = 0;
      while (notifier.state.phase != StudyPhase.completed && guard < 50) {
        await _flipAndRate(notifier, Rating.forgot);
        guard++;
      }

      expect(notifier.state.phase, StudyPhase.completed);
      expect(notifier.state.currentCard, isNull);
      // 初回 + 再出題2回 = 3回で終わる
      expect(guard, 3);
    });
  });
}
