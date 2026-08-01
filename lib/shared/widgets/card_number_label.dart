import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';

/// 「💬 Code Review #3」形式のラベルを返す。
/// どのカテゴリの何番目のカードかを一目で分かるようにするためのもので、
/// 番号はカテゴリごとに1から振られている（cards.json の並び順）。
String cardNumberLabel(TechCard card) {
  final def = categoryDefs.firstWhere(
    (d) => d['id'] == card.category,
    orElse: () => const {'name': '', 'icon': ''},
  );
  final name = def['name'] ?? '';
  final icon = def['icon'] ?? '';
  return '$icon $name #${card.cardNumber}'.trim();
}

/// 番号だけを返す（一覧の行頭バッジ用）
String cardNumberShort(TechCard card) => '#${card.cardNumber}';
