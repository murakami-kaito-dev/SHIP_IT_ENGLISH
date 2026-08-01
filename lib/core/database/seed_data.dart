import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/database/database_helper.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:sqflite/sqflite.dart';

class SeedData {
  final DatabaseHelper _db;

  SeedData(this._db);

  Future<void> seed() async {
    final prefs = await SharedPreferences.getInstance();
    final currentSeedVersion = prefs.getString(AppConstants.keySeedVersion);

    String jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/data/cards.json');
    } catch (e) {
      // JSONパースエラー: アプリ起動は継続
      assert(() {
        // ignore: avoid_print
        print('[SeedData] Failed to load cards.json: $e');
        return true;
      }());
      return;
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[SeedData] Failed to parse cards.json: $e');
        return true;
      }());
      return;
    }

    final jsonVersion = data['version'] as String? ?? '0.0.0';

    if (currentSeedVersion == jsonVersion) return;

    final db = await _db.database;
    final cards = data['cards'] as List<dynamic>? ?? [];
    final categories = data['categories'] as List<dynamic>? ?? [];

    // 有効なカテゴリIDのセット
    final validCategoryIds = categories
        .map((c) => (c as Map<String, dynamic>)['id'] as String)
        .toSet();

    final now = DateTime.now().toIso8601String();
    int inserted = 0;

    // カテゴリごとの通し番号（JSONの並び順で1から採番）
    final numberByCategory = <String, int>{};

    // JSONに載っている有効なカードID。これに含まれないカードは
    // 「JSONから削除された」とみなして掃除する（下記）
    final jsonCardIds = <String>{};

    await db.transaction((txn) async {
      for (final raw in cards) {
        if (raw is! Map<String, dynamic>) continue;

        // バリデーション: 必須フィールド
        final id = raw['id'] as String?;
        final phrase = raw['phrase'] as String?;
        final translation = raw['translation'] as String?;
        final example = raw['example'] as String?;
        final exampleTranslation = raw['example_translation'] as String?;
        final context = raw['context'] as String?;
        final category = raw['category'] as String?;

        if (id == null ||
            phrase == null ||
            translation == null ||
            example == null ||
            exampleTranslation == null ||
            context == null ||
            category == null) {
          continue;
        }

        // カテゴリ未登録ならスキップ
        if (!validCategoryIds.contains(category)) {
          assert(() {
            // ignore: avoid_print
            print('[SeedData] Unknown category: $category, skipping card $id');
            return true;
          }());
          continue;
        }

        // difficulty 範囲外はデフォルト1
        final rawDiff = raw['difficulty'];
        final difficulty =
            (rawDiff is int && rawDiff >= 1 && rawDiff <= 3) ? rawDiff : 1;

        jsonCardIds.add(id);

        final cardNumber = (numberByCategory[category] ?? 0) + 1;
        numberByCategory[category] = cardNumber;

        await txn.insert(
          'cards',
          {
            'id': id,
            'phrase': phrase,
            'translation': translation,
            'example': example,
            'example_translation': exampleTranslation,
            'context': context,
            'context_en': raw['context_en'] as String? ?? '',
            'category': category,
            'difficulty': difficulty,
            'created_at': now,
            'card_number': cardNumber,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // learning_progress は INSERT OR IGNORE（既存の学習進捗は保持）
        await txn.insert(
          'learning_progress',
          LearningProgress.initial(id).toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        inserted++;
      }

      // JSONから削除されたカードをDBからも消す。
      // cards.json が唯一の正としてDBを追従させるため、重複除去や
      // カード削除が確実に反映されるようにする（残しておくと幽霊カードになる）。
      if (jsonCardIds.isNotEmpty) {
        final existing = await txn.query('cards', columns: ['id']);
        final staleIds = existing
            .map((r) => r['id'] as String)
            .where((id) => !jsonCardIds.contains(id))
            .toList();
        for (final id in staleIds) {
          await txn.delete('cards', where: 'id = ?', whereArgs: [id]);
          await txn.delete('learning_progress',
              where: 'card_id = ?', whereArgs: [id]);
        }
        if (staleIds.isNotEmpty) {
          assert(() {
            // ignore: avoid_print
            print('[SeedData] Removed ${staleIds.length} stale cards');
            return true;
          }());
        }
      }
    });

    await prefs.setString(AppConstants.keySeedVersion, jsonVersion);

    assert(() {
      // ignore: avoid_print
      print('[SeedData] Seeded $inserted cards (version $jsonVersion)');
      return true;
    }());
  }
}
