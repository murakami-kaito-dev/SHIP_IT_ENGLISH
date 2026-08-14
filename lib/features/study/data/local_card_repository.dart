import 'package:ship_it_english/core/database/database_helper.dart';
import 'package:ship_it_english/features/study/data/card_repository.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

class LocalCardRepository implements CardRepository {
  final DatabaseHelper _db;

  LocalCardRepository(this._db);

  @override
  Future<List<TechCard>> getCardsForReview(
    DateTime asOf, {
    String? categoryId,
  }) async {
    final db = await _db.database;
    final asOfStr = asOf.toIso8601String();
    final categoryFilter = categoryId != null ? 'AND c.category = ?' : '';
    final maps = await db.rawQuery('''
      SELECT c.* FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE lp.next_review <= ? AND lp.status != 'new' $categoryFilter
      ORDER BY lp.next_review ASC
    ''', [asOfStr, if (categoryId != null) categoryId]);
    return maps.map((m) => TechCard.fromMap(m)).toList();
  }

  @override
  Future<List<TechCard>> getNewCards({
    required int limit,
    String? categoryId,
    Set<String>? allowedCategories,
  }) async {
    final db = await _db.database;
    final categoryFilter = categoryId != null ? 'AND c.category = ?' : '';
    final allowedFilter = allowedCategories != null
        ? 'AND c.category IN (${List.filled(allowedCategories.length, '?').join(',')})'
        : '';
    final maps = await db.rawQuery('''
      SELECT c.* FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE lp.status = 'new' $categoryFilter $allowedFilter
      ORDER BY c.difficulty ASC, c.created_at ASC
      LIMIT ?
    ''', [
      if (categoryId != null) categoryId,
      ...?allowedCategories,
      limit,
    ]);
    return maps.map((m) => TechCard.fromMap(m)).toList();
  }

  /// カテゴリ学習の WHERE 句と引数を組み立てる（取得と件数で共用）。
  ///
  /// [statuses] は学習状況の集合。`'new'`（＝未学習・last_rating が NULL）,
  /// `'forgot'`, `'uncertain'`, `'remembered'`。空なら全状況が対象。
  (String, List<Object?>) _categoryStudyWhere({
    required String categoryId,
    required int from,
    required int to,
    required Set<String> statuses,
  }) {
    final where = <String>['c.category = ?', 'c.card_number BETWEEN ? AND ?'];
    final args = <Object?>[categoryId, from, to];

    if (statuses.isNotEmpty) {
      final clauses = <String>[];
      final rated = statuses.where((s) => s != 'new').toList();
      if (rated.isNotEmpty) {
        clauses.add(
          'lp.last_rating IN (${List.filled(rated.length, '?').join(',')})',
        );
        args.addAll(rated);
      }
      if (statuses.contains('new')) {
        clauses.add('lp.last_rating IS NULL');
      }
      where.add('(${clauses.join(' OR ')})');
    }
    return (where.join(' AND '), args);
  }

  /// カテゴリ学習の対象カードを返す。
  /// カテゴリ内の通し番号 [from]〜[to]、[statuses] の学習状況で絞り、
  /// [random] が true ならランダム順、false なら番号の若い順で返す。
  /// 枚数の上限はなく、条件に一致する全カードが対象。
  Future<List<TechCard>> getCategoryStudyCards({
    required String categoryId,
    required int from,
    required int to,
    required Set<String> statuses,
    required bool random,
  }) async {
    final db = await _db.database;
    final (whereClause, args) = _categoryStudyWhere(
      categoryId: categoryId,
      from: from,
      to: to,
      statuses: statuses,
    );
    final order = random ? 'RANDOM()' : 'c.card_number ASC';
    final maps = await db.rawQuery('''
      SELECT c.* FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE $whereClause
      ORDER BY $order
    ''', args);
    return maps.map((m) => TechCard.fromMap(m)).toList();
  }

  /// カテゴリ学習の条件に一致するカード枚数（設定シートのプレビュー用）
  Future<int> countCategoryStudyCards({
    required String categoryId,
    required int from,
    required int to,
    required Set<String> statuses,
  }) async {
    final db = await _db.database;
    final (whereClause, args) = _categoryStudyWhere(
      categoryId: categoryId,
      from: from,
      to: to,
      statuses: statuses,
    );
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE $whereClause
    ''', args);
    return result.first['count'] as int? ?? 0;
  }

  @override
  Future<List<TechCard>> getAllCards() async {
    final db = await _db.database;
    final maps = await db.query('cards', orderBy: 'created_at ASC');
    return maps.map((m) => TechCard.fromMap(m)).toList();
  }

  @override
  Future<List<TechCard>> getCardsByCategory(String categoryId) async {
    final db = await _db.database;
    final maps = await db.query(
      'cards',
      where: 'category = ?',
      whereArgs: [categoryId],
      orderBy: 'difficulty ASC',
    );
    return maps.map((m) => TechCard.fromMap(m)).toList();
  }

  @override
  Future<TechCard?> getCard(String id) async {
    final db = await _db.database;
    final maps = await db.query('cards', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TechCard.fromMap(maps.first);
  }

  @override
  Future<void> upsertCard(TechCard card) async {
    final db = await _db.database;
    await db.insert(
      'cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<LearningProgress?> getProgress(String cardId) async {
    final db = await _db.database;
    final maps = await db.query(
      'learning_progress',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    if (maps.isEmpty) return null;
    return LearningProgress.fromMap(maps.first);
  }

  @override
  Future<void> saveProgress(LearningProgress progress) async {
    final db = await _db.database;
    await db.insert(
      'learning_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, int>> getCategoryProgress() async {
    final db = await _db.database;
    // カテゴリごとのmastered数を返す
    final maps = await db.rawQuery('''
      SELECT c.category, COUNT(*) as mastered_count
      FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE lp.status = 'mastered'
      GROUP BY c.category
    ''');

    final result = <String, int>{};
    for (final m in maps) {
      result[m['category'] as String] = m['mastered_count'] as int;
    }
    return result;
  }

  @override
  Future<int> getTotalMasteredCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM learning_progress WHERE status = 'mastered'",
    );
    return result.first['count'] as int? ?? 0;
  }

  /// 一度でも学習したカード数（status != 'new'）。
  /// mastered は21日間隔到達が条件で数週間かかるため、
  /// 日々の進捗表示にはこちらを使う。
  Future<int> getStudiedCardCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM learning_progress WHERE status != 'new'",
    );
    return result.first['count'] as int? ?? 0;
  }

  /// カテゴリごとの「学習開始済み」カード数（status != 'new'）
  Future<Map<String, int>> getCategoryStudiedCounts() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT c.category, COUNT(*) as studied_count
      FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE lp.status != 'new'
      GROUP BY c.category
    ''');
    final result = <String, int>{};
    for (final m in maps) {
      result[m['category'] as String] = m['studied_count'] as int;
    }
    return result;
  }

  @override
  Future<int> getTotalCardCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM cards');
    return result.first['count'] as int? ?? 0;
  }

  @override
  Future<void> saveDailyStats(DailyStats stats) async {
    final db = await _db.database;
    // 既存レコードがあれば加算する
    final existing = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [stats.date],
    );

    if (existing.isEmpty) {
      await db.insert('daily_stats', stats.toMap());
    } else {
      final current = existing.first;
      await db.update(
        'daily_stats',
        {
          'cards_studied':
              (current['cards_studied'] as int) + stats.cardsStudied,
          'cards_correct':
              (current['cards_correct'] as int) + stats.cardsCorrect,
          'new_cards': (current['new_cards'] as int) + stats.newCards,
          'review_cards': (current['review_cards'] as int) + stats.reviewCards,
          'study_time_seconds':
              (current['study_time_seconds'] as int) + stats.studyTimeSeconds,
        },
        where: 'date = ?',
        whereArgs: [stats.date],
      );
    }
  }

  /// 今日学習したカードの総枚数（daily_stats.cards_studied）。
  /// デイリー目標（ストリークの炎の強発光）判定に使う。
  Future<int> getCardsStudiedToday(String todayStr) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_stats',
      columns: ['cards_studied'],
      where: 'date = ?',
      whereArgs: [todayStr],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['cards_studied'] as int?) ?? 0;
  }

  /// 今日すでに学習した「新規カード」の枚数（daily_stats.new_cards）。
  /// 1日の新規カード枠を消化するために使う（途中でやめて再開しても、
  /// その日に入れた新規カードの分だけ残り枠が減る）。
  Future<int> getNewCardsStudiedToday(String todayStr) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_stats',
      columns: ['new_cards'],
      where: 'date = ?',
      whereArgs: [todayStr],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['new_cards'] as int?) ?? 0;
  }

  @override
  Future<void> resetAllData() async {
    final db = await _db.database;
    await db.delete('learning_progress');
    await db.delete('daily_stats');
    // cardsテーブルはシードデータを残す（learning_progressのみリセット）
  }

  /// カテゴリ別の全カード数を返す
  Future<Map<String, int>> getCategoryTotalCounts() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT category, COUNT(*) as total
      FROM cards
      GROUP BY category
    ''');
    final result = <String, int>{};
    for (final m in maps) {
      result[m['category'] as String] = m['total'] as int;
    }
    return result;
  }

  /// ease_factorが低い順に指定枚数取得（復習対象）
  Future<List<TechCard>> getWeakCards({required int limit}) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT c.* FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE lp.status = 'mastered'
      ORDER BY lp.ease_factor ASC
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => TechCard.fromMap(m)).toList();
  }

  /// カテゴリ内の各カードの最終評価を返す（card_id → last_rating文字列/null）
  Future<Map<String, String?>> getRatingsByCategory(String categoryId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT lp.card_id, lp.last_rating
      FROM learning_progress lp
      INNER JOIN cards c ON c.id = lp.card_id
      WHERE c.category = ?
    ''', [categoryId]);
    final result = <String, String?>{};
    for (final m in maps) {
      result[m['card_id'] as String] = m['last_rating'] as String?;
    }
    return result;
  }

  /// 「もう一度復習」用のカード。
  ///
  /// **その日のうちに学習したカードだけ**を苦手な順（ease_factor 昇順）で返す。
  /// 過去に学習しただけのカードは含めない。
  /// SRSの次回予定日は見ない（「曖昧」でも next_review は翌日になるため、
  /// 予定日基準だと当日中にもう一度復習できない）。
  Future<List<TechCard>> getPracticeCards({
    required int limit,
    required String todayStr,
    Set<String>? allowedCategories,
  }) async {
    final db = await _db.database;
    final allowedFilter = allowedCategories != null
        ? 'AND c.category IN (${List.filled(allowedCategories.length, '?').join(',')})'
        : '';
    final maps = await db.rawQuery('''
      SELECT c.* FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE date(lp.last_reviewed) = ?
        $allowedFilter
      ORDER BY lp.ease_factor ASC, c.card_number ASC
      LIMIT ?
    ''', [todayStr, ...?allowedCategories, limit]);
    return maps.map((m) => TechCard.fromMap(m)).toList();
  }

  /// 「もう一度復習」の対象枚数（その日に学習したカード数）
  Future<int> getPracticeCardsCount({
    required String todayStr,
    Set<String>? allowedCategories,
  }) async {
    final db = await _db.database;
    final allowedFilter = allowedCategories != null
        ? 'AND c.category IN (${List.filled(allowedCategories.length, '?').join(',')})'
        : '';
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE date(lp.last_reviewed) = ?
        $allowedFilter
    ''', [todayStr, ...?allowedCategories]);
    return result.first['count'] as int? ?? 0;
  }

  /// フレーズ・和訳・例文を対象にした部分一致検索（最終評価付き）
  Future<List<(TechCard, String?)>> searchCards(String query) async {
    final db = await _db.database;
    final pattern = '%$query%';
    final maps = await db.rawQuery('''
      SELECT c.*, lp.last_rating as lp_rating FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      WHERE c.phrase LIKE ? OR c.translation LIKE ? OR c.example LIKE ?
      ORDER BY c.category ASC, c.card_number ASC
      LIMIT 50
    ''', [pattern, pattern, pattern]);
    return maps
        .map((m) => (TechCard.fromMap(m), m['lp_rating'] as String?))
        .toList();
  }

  /// カテゴリ（OR）× 最終評価（OR）でカードを絞り込む。
  /// 両方指定された場合は AND 条件。空セット/null は「条件なし」。
  ///
  /// [ratings] に `null` を含めると「未学習」を対象に含める。
  Future<List<(TechCard, String?)>> filterCards({
    Set<String>? categories,
    Set<String?>? ratings,
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];

    if (categories != null && categories.isNotEmpty) {
      where.add(
        'c.category IN (${List.filled(categories.length, '?').join(',')})',
      );
      args.addAll(categories);
    }

    if (ratings != null && ratings.isNotEmpty) {
      final concrete = ratings.whereType<String>().toList();
      final clauses = <String>[];
      if (concrete.isNotEmpty) {
        clauses.add(
          'lp.last_rating IN (${List.filled(concrete.length, '?').join(',')})',
        );
        args.addAll(concrete);
      }
      if (ratings.contains(null)) {
        clauses.add('lp.last_rating IS NULL');
      }
      where.add('(${clauses.join(' OR ')})');
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final maps = await db.rawQuery('''
      SELECT c.*, lp.last_rating as lp_rating FROM cards c
      INNER JOIN learning_progress lp ON c.id = lp.card_id
      $whereClause
      ORDER BY c.category ASC, c.card_number ASC
    ''', args);
    return maps
        .map((m) => (TechCard.fromMap(m), m['lp_rating'] as String?))
        .toList();
  }

  /// 学習した全日付の枚数を返す（date文字列 'yyyy-MM-dd' → cards_studied）。
  /// 学習履歴カレンダー用。cards_studied が 0 の日は学習日に含めない。
  Future<Map<String, int>> getAllStudyDays() async {
    final db = await _db.database;
    final maps = await db.query(
      'daily_stats',
      columns: ['date', 'cards_studied'],
      where: 'cards_studied > 0',
    );
    final result = <String, int>{};
    for (final m in maps) {
      result[m['date'] as String] = m['cards_studied'] as int? ?? 0;
    }
    return result;
  }

  /// 直近の日別学習枚数を返す（date文字列 'yyyy-MM-dd' → cards_studied）
  Future<Map<String, int>> getRecentStudyCounts({required int days}) async {
    final db = await _db.database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: days - 1))
        .toIso8601String()
        .substring(0, 10);
    final maps = await db.query(
      'daily_stats',
      columns: ['date', 'cards_studied'],
      where: 'date >= ?',
      whereArgs: [cutoff],
    );
    final result = <String, int>{};
    for (final m in maps) {
      result[m['date'] as String] = m['cards_studied'] as int? ?? 0;
    }
    return result;
  }

  /// 本日の学習済みカードが存在するか
  @override
  Future<bool> hasStudiedToday(String todayStr) async {
    final db = await _db.database;
    final result = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [todayStr],
    );
    if (result.isEmpty) return false;
    return (result.first['cards_studied'] as int? ?? 0) > 0;
  }

  /// 新規カード数を返す（[allowedCategories] 指定時はそのカテゴリのみ集計）
  Future<int> getNewCardsCount({Set<String>? allowedCategories}) async {
    final db = await _db.database;
    final allowedFilter = allowedCategories != null
        ? 'AND c.category IN (${List.filled(allowedCategories.length, '?').join(',')})'
        : '';
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM learning_progress lp
      INNER JOIN cards c ON c.id = lp.card_id
      WHERE lp.status = 'new' $allowedFilter
    ''', [...?allowedCategories]);
    return result.first['count'] as int? ?? 0;
  }

  /// 本日の復習対象カード数
  Future<int> getReviewCardsCount(DateTime asOf) async {
    final db = await _db.database;
    final asOfStr = asOf.toIso8601String();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM learning_progress
      WHERE next_review <= ? AND status != 'new'
    ''', [asOfStr]);
    return result.first['count'] as int? ?? 0;
  }
}
