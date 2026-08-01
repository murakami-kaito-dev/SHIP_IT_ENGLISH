class TechCard {
  final String id;
  final String phrase;
  final String translation;
  final String example;
  final String exampleTranslation;
  final String context;

  /// 英語話者モード用の使用場面説明（英語）。旧データでは空文字
  final String contextEn;
  final String category;
  final int difficulty;
  final DateTime createdAt;

  /// カテゴリ内の通し番号（1始まり）。「Code Review #3」のように表示する
  final int cardNumber;

  const TechCard({
    required this.id,
    required this.phrase,
    required this.translation,
    required this.example,
    required this.exampleTranslation,
    required this.context,
    this.contextEn = '',
    required this.category,
    required this.difficulty,
    required this.createdAt,
    this.cardNumber = 0,
  });

  factory TechCard.fromMap(Map<String, dynamic> map) {
    return TechCard(
      id: map['id'] as String,
      phrase: map['phrase'] as String,
      translation: map['translation'] as String,
      example: map['example'] as String,
      exampleTranslation: map['example_translation'] as String,
      context: map['context'] as String,
      contextEn: map['context_en'] as String? ?? '',
      category: map['category'] as String,
      difficulty: map['difficulty'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      cardNumber: map['card_number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phrase': phrase,
      'translation': translation,
      'example': example,
      'example_translation': exampleTranslation,
      'context': context,
      'context_en': contextEn,
      'category': category,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'card_number': cardNumber,
    };
  }
}
