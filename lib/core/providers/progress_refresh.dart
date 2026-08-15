import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/features/categories/providers/categories_providers.dart';
import 'package:ship_it_english/features/history/providers/history_providers.dart';
import 'package:ship_it_english/features/home/providers/home_providers.dart';
import 'package:ship_it_english/features/search/providers/search_providers.dart';

/// 学習進捗が変化したあとに呼ぶ。
///
/// ホーム・カテゴリの集計プロバイダーは FutureProvider（autoDispose なし）で
/// 値をキャッシュするため、セッション完了後やカード評価後にこれを呼ばないと
/// 「習得済み 0/195」のような**古い表示が残る**。
///
/// あわせてカード一覧系（カテゴリ詳細・検索・フィルタ結果）も無効化する。
/// family プロバイダーは引数なしで invalidate すると**全インスタンス**が
/// 対象になるので、どの画面が背後で開いていても即座に再取得される。
/// これによりカード詳細シートで評価した瞬間に、裏の一覧の表示も切り替わる。
void invalidateProgressProviders(WidgetRef ref) {
  // 集計系
  ref.invalidate(dailySessionInfoProvider);
  ref.invalidate(overallProgressProvider);
  ref.invalidate(skillScoreProvider); // 技術英語カバレッジ
  ref.invalidate(weeklyStatsProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(studyDaysProvider); // 学習カレンダー

  // カード一覧系（開いている画面を即時更新するため）
  ref.invalidate(categoryCardsProvider);
  ref.invalidate(filteredCardsProvider);
  ref.invalidate(searchResultsProvider);
}
