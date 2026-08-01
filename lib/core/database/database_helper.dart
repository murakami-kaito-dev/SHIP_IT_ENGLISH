import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const int _databaseVersion = 3;
  static const String _databaseName = 'shipit_english.db';

  Database? _database;

  Future<Database> initialize() async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> get database async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards (
        id            TEXT PRIMARY KEY,
        phrase        TEXT NOT NULL,
        translation   TEXT NOT NULL,
        example       TEXT NOT NULL,
        example_translation TEXT NOT NULL,
        context       TEXT NOT NULL,
        category      TEXT NOT NULL,
        difficulty    INTEGER NOT NULL DEFAULT 1,
        created_at    TEXT NOT NULL,
        context_en    TEXT NOT NULL DEFAULT '',
        card_number   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE learning_progress (
        card_id       TEXT PRIMARY KEY REFERENCES cards(id),
        ease_factor   REAL NOT NULL DEFAULT 2.5,
        interval_days INTEGER NOT NULL DEFAULT 0,
        repetitions   INTEGER NOT NULL DEFAULT 0,
        next_review   TEXT NOT NULL,
        last_reviewed TEXT,
        status        TEXT NOT NULL DEFAULT 'new',
        last_rating   TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats (
        date          TEXT PRIMARY KEY,
        cards_studied INTEGER NOT NULL DEFAULT 0,
        cards_correct INTEGER NOT NULL DEFAULT 0,
        new_cards     INTEGER NOT NULL DEFAULT 0,
        review_cards  INTEGER NOT NULL DEFAULT 0,
        study_time_seconds INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_learning_next_review ON learning_progress(next_review)',
    );
    await db.execute(
      'CREATE INDEX idx_learning_status ON learning_progress(status)',
    );
    await db.execute(
      'CREATE INDEX idx_cards_category ON cards(category)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: 英語話者モード用の使用場面説明（cards.json の context_en）
      await db.execute(
        "ALTER TABLE cards ADD COLUMN context_en TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 3) {
      // v3-1: カテゴリ内の通し番号（画面に「Code Review #3」と出すため）
      await db.execute(
        'ALTER TABLE cards ADD COLUMN card_number INTEGER NOT NULL DEFAULT 0',
      );
      // v3-2: 最後の自己評価（忘れた/曖昧/覚えてた）。
      // 表示ステータスをSRS内部状態ではなく評価語彙で統一するために保持する
      await db.execute(
        'ALTER TABLE learning_progress ADD COLUMN last_rating TEXT',
      );
      // 既存データの移行: SRS状態から妥当な評価を推定する
      await db.execute('''
        UPDATE learning_progress SET last_rating = CASE
          WHEN status = 'learning' THEN 'forgot'
          WHEN status = 'mastered' THEN 'remembered'
          WHEN status = 'review'   THEN 'uncertain'
          ELSE NULL
        END
      ''');
    }
  }
}
