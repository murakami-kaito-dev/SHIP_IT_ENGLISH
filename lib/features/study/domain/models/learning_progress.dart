import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

enum CardStatus {
  newCard('new'),
  learning('learning'),
  review('review'),
  mastered('mastered');

  final String value;
  const CardStatus(this.value);

  static CardStatus fromString(String value) {
    return CardStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CardStatus.newCard,
    );
  }
}

class LearningProgress {
  final String cardId;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReview;
  final DateTime? lastReviewed;
  final CardStatus status;

  /// 最後の自己評価（忘れた/曖昧/覚えてた）。未学習なら null。
  /// 画面のステータス表示はSRS内部状態ではなくこれを使い、
  /// 評価ボタンと同じ語彙に統一する。
  final Rating? lastRating;

  const LearningProgress({
    required this.cardId,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReview,
    required this.lastReviewed,
    required this.status,
    this.lastRating,
  });

  factory LearningProgress.initial(String cardId) {
    return LearningProgress(
      cardId: cardId,
      easeFactor: AppConstants.initialEaseFactor,
      intervalDays: 0,
      repetitions: 0,
      nextReview: DateTime.now(),
      lastReviewed: null,
      status: CardStatus.newCard,
    );
  }

  factory LearningProgress.fromMap(Map<String, dynamic> map) {
    return LearningProgress(
      cardId: map['card_id'] as String,
      easeFactor: (map['ease_factor'] as num).toDouble(),
      intervalDays: map['interval_days'] as int,
      repetitions: map['repetitions'] as int,
      nextReview: DateTime.parse(map['next_review'] as String),
      lastReviewed: map['last_reviewed'] != null
          ? DateTime.parse(map['last_reviewed'] as String)
          : null,
      status: CardStatus.fromString(map['status'] as String),
      lastRating: Rating.fromString(map['last_rating'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'card_id': cardId,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'repetitions': repetitions,
      'next_review': nextReview.toIso8601String(),
      'last_reviewed': lastReviewed?.toIso8601String(),
      'status': status.value,
      'last_rating': lastRating?.value,
    };
  }

  LearningProgress copyWith({
    String? cardId,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReview,
    DateTime? lastReviewed,
    CardStatus? status,
    Rating? lastRating,
  }) {
    return LearningProgress(
      cardId: cardId ?? this.cardId,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReview: nextReview ?? this.nextReview,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      status: status ?? this.status,
      lastRating: lastRating ?? this.lastRating,
    );
  }
}
