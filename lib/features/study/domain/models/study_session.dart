/// 自己評価。DB（learning_progress.last_rating）にも保存するため
/// 永続化用の文字列表現を持つ。
enum Rating {
  forgot('forgot'),
  uncertain('uncertain'),
  remembered('remembered');

  final String value;
  const Rating(this.value);

  static Rating? fromString(String? value) {
    if (value == null) return null;
    for (final r in Rating.values) {
      if (r.value == value) return r;
    }
    return null;
  }
}

class StudySession {
  final DateTime startedAt;
  final List<CardResult> results;

  StudySession({
    required this.startedAt,
    List<CardResult>? results,
  }) : results = results ?? [];

  int get totalCards => results.length;

  int get correctCards =>
      results.where((r) => r.rating == Rating.remembered).length;

  int get uncertainCards =>
      results.where((r) => r.rating == Rating.uncertain).length;

  int get forgotCards => results.where((r) => r.rating == Rating.forgot).length;

  Duration get duration => DateTime.now().difference(startedAt);

  double get accuracy =>
      totalCards > 0 ? (correctCards + uncertainCards) / totalCards : 0.0;
}

class CardResult {
  final String cardId;
  final Rating rating;
  final DateTime answeredAt;
  final bool isRetry;

  const CardResult({
    required this.cardId,
    required this.rating,
    required this.answeredAt,
    required this.isRetry,
  });
}

class DailyStats {
  final String date;
  final int cardsStudied;
  final int cardsCorrect;
  final int newCards;
  final int reviewCards;
  final int studyTimeSeconds;

  const DailyStats({
    required this.date,
    required this.cardsStudied,
    required this.cardsCorrect,
    required this.newCards,
    required this.reviewCards,
    required this.studyTimeSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'cards_studied': cardsStudied,
      'cards_correct': cardsCorrect,
      'new_cards': newCards,
      'review_cards': reviewCards,
      'study_time_seconds': studyTimeSeconds,
    };
  }
}

/// パーフェクトセッション判定（純関数・テスト可能）。
/// 「全カードを1回で『覚えてた』で終えた」＝ results のすべてが remembered
/// （forgot があれば再出題が混ざり、uncertain は完璧ではない）。
/// ユニットテスト（卒業テスト）は対象外、最低枚数未満も対象外。
bool isPerfectSession({
  required List<CardResult> results,
  required int uniqueCount,
  required bool unitTest,
  required int minCards,
}) {
  if (unitTest) return false;
  if (uniqueCount < minCards) return false;
  if (results.isEmpty) return false;
  return results.every((r) => r.rating == Rating.remembered);
}
