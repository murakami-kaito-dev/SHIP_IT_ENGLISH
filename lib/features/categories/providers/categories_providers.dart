import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

class CategoryInfo {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String descriptionEn;
  final int totalCount;
  final int masteredCount;

  /// 一度でも学習したカード数（学習中・復習中・習得済みの合計）
  final int studiedCount;

  const CategoryInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.descriptionEn,
    required this.totalCount,
    required this.masteredCount,
    required this.studiedCount,
  });

  /// 進捗バーは学習着手率を示す（mastered は21日間隔到達が条件で反映が遅いため）
  double get percentage => totalCount > 0 ? studiedCount / totalCount : 0.0;
}

/// カテゴリ定義（カード定義に合わせた固定順序）
const categoryDefs = [
  {'id': 'code_review', 'name': 'Code Review', 'icon': '💬', 'description': 'コードレビューで使う表現', 'description_en': 'Phrases used in code reviews'},
  {'id': 'git_cicd', 'name': 'Git / CI/CD', 'icon': '🔧', 'description': 'GitやCI/CDで使う表現', 'description_en': 'Phrases for Git and CI/CD'},
  {'id': 'meetings', 'name': 'Meetings / Standup', 'icon': '📅', 'description': 'ミーティング・スタンドアップで使う表現', 'description_en': 'Phrases for meetings and standups'},
  {'id': 'slack', 'name': 'Slack Communication', 'icon': '💬', 'description': 'Slackで使う表現', 'description_en': 'Phrases for Slack and chat'},
  {'id': 'architecture', 'name': 'Architecture / Design', 'icon': '🏗️', 'description': 'アーキテクチャ・設計で使う表現', 'description_en': 'Phrases for architecture discussions'},
  {'id': 'incident', 'name': 'Incident Response', 'icon': '🚨', 'description': 'インシデント対応で使う表現', 'description_en': 'Phrases for incident response'},
  {'id': 'interview', 'name': 'Tech Interview', 'icon': '🎯', 'description': 'テック面接で使う表現', 'description_en': 'Phrases for tech interviews'},
  {'id': 'planning', 'name': 'Sprint Planning', 'icon': '📊', 'description': 'スプリントプランニング・見積もりで使う表現', 'description_en': 'Phrases for sprint planning and estimation'},
  {'id': 'career', 'name': '1on1 / Career', 'icon': '🌱', 'description': '1on1・評価面談・キャリア相談で使う表現', 'description_en': 'Phrases for 1:1s, reviews, and career talks'},
  {'id': 'remote_work', 'name': 'Remote / Async', 'icon': '🌏', 'description': 'リモートワーク・非同期コミュニケーションの表現', 'description_en': 'Phrases for remote and async work'},
  {'id': 'documentation', 'name': 'Docs / Writing', 'icon': '📝', 'description': 'ドキュメント作成・技術文書で使う表現', 'description_en': 'Phrases for documentation and technical writing'},
  {'id': 'security', 'name': 'Security & Compliance', 'icon': '🔐', 'description': 'セキュリティ・認証・アクセス制御で使う表現', 'description_en': 'Phrases used in security, authentication, and access control'},
  {'id': 'qa_testing', 'name': 'QA & Testing', 'icon': '🧪', 'description': 'テスト・QA・品質保証で使う表現', 'description_en': 'Phrases used in testing and quality assurance'},
  {'id': 'tech_debt', 'name': 'Refactoring & Tech Debt', 'icon': '🧹', 'description': 'リファクタリング・技術負債の解消で使う表現', 'description_en': 'Phrases used in refactoring and tackling technical debt'},
];

final categoriesProvider = FutureProvider<List<CategoryInfo>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;

  final masteredCounts = await repo.getCategoryProgress();
  final studiedCounts = await repo.getCategoryStudiedCounts();
  final totalCounts = await repo.getCategoryTotalCounts();

  return categoryDefs.map((def) {
    final id = def['id']!;
    return CategoryInfo(
      id: id,
      name: def['name']!,
      icon: def['icon']!,
      description: def['description']!,
      descriptionEn: def['description_en']!,
      totalCount: totalCounts[id] ?? 0,
      masteredCount: masteredCounts[id] ?? 0,
      studiedCount: studiedCounts[id] ?? 0,
    );
  }).toList();
});

/// カード + 最終評価のペア（カテゴリ詳細・検索・フィルタで共用）。
/// [rating] が null なら未学習。
class CardWithStatus {
  final TechCard card;
  final Rating? rating;

  const CardWithStatus({required this.card, required this.rating});
}

/// 指定カテゴリの全カードを最終評価付きで返す（カテゴリ内番号順）
final categoryCardsProvider = FutureProvider.autoDispose
    .family<List<CardWithStatus>, String>((ref, categoryId) async {
  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;

  final cards = await repo.getCardsByCategory(categoryId);
  final ratings = await repo.getRatingsByCategory(categoryId);

  final sorted = [...cards]
    ..sort((a, b) => a.cardNumber.compareTo(b.cardNumber));

  return sorted
      .map(
        (c) => CardWithStatus(
          card: c,
          rating: Rating.fromString(ratings[c.id]),
        ),
      )
      .toList();
});

/// カテゴリタブのフィルタ条件。
/// - [categories]: 空なら全カテゴリ。複数選択は OR
/// - [ratings]: 空なら全状況。複数選択は OR（null要素 = 未学習）
/// - 両方指定時は AND
class CardFilter {
  final Set<String> categories;
  final Set<Rating?> ratings;

  const CardFilter({this.categories = const {}, this.ratings = const {}});

  bool get isActive => categories.isNotEmpty || ratings.isNotEmpty;

  CardFilter toggleCategory(String id) {
    final next = {...categories};
    next.contains(id) ? next.remove(id) : next.add(id);
    return CardFilter(categories: next, ratings: ratings);
  }

  CardFilter toggleRating(Rating? rating) {
    final next = {...ratings};
    next.contains(rating) ? next.remove(rating) : next.add(rating);
    return CardFilter(categories: categories, ratings: next);
  }

  CardFilter cleared() => const CardFilter();

  @override
  bool operator ==(Object other) =>
      other is CardFilter &&
      setEquals(other.categories, categories) &&
      setEquals(other.ratings, ratings);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(categories),
        Object.hashAllUnordered(ratings),
      );
}

final cardFilterProvider =
    StateProvider<CardFilter>((ref) => const CardFilter());

/// カテゴリ学習の設定（設定シートの状態＝件数プレビューのキー）。
/// statuses: 'new','forgot','uncertain','remembered'（空なら全状況）
class CategoryStudyConfig {
  final String categoryId;
  final int from;
  final int to;
  final Set<String> statuses;

  const CategoryStudyConfig({
    required this.categoryId,
    required this.from,
    required this.to,
    required this.statuses,
  });

  @override
  bool operator ==(Object other) =>
      other is CategoryStudyConfig &&
      other.categoryId == categoryId &&
      other.from == from &&
      other.to == to &&
      setEquals(other.statuses, statuses);

  @override
  int get hashCode =>
      Object.hash(categoryId, from, to, Object.hashAllUnordered(statuses));
}

/// カテゴリ学習の条件に一致するカード枚数（設定シートのプレビュー用）
final categoryStudyCountProvider = FutureProvider.autoDispose
    .family<int, CategoryStudyConfig>((ref, config) async {
  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;
  return repo.countCategoryStudyCards(
    categoryId: config.categoryId,
    from: config.from,
    to: config.to,
    statuses: config.statuses,
  );
});

/// フィルタ条件に一致するカード一覧（カテゴリタブでフィルタ適用時に表示）
final filteredCardsProvider =
    FutureProvider.autoDispose<List<CardWithStatus>>((ref) async {
  final filter = ref.watch(cardFilterProvider);
  if (!filter.isActive) return [];

  final repo = ref.watch(cardRepositoryProvider) as LocalCardRepository;
  final results = await repo.filterCards(
    categories: filter.categories,
    ratings: filter.ratings.map((r) => r?.value).toSet(),
  );

  return results
      .map(
        (r) => CardWithStatus(card: r.$1, rating: Rating.fromString(r.$2)),
      )
      .toList();
});
