import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

/// 学習データのバックアップ / 復元。
///
/// 学習履歴は端末内の SQLite にしか存在しないため、機種変更やアプリ削除で
/// 消えてしまう。JSON に書き出して共有シート経由で保存できるようにし、
/// 新しい端末で読み込めるようにする。
///
/// 書き出す対象は**ユーザー固有のデータのみ**（学習進捗・日別統計・
/// ストリーク・設定）。カード本体は cards.json から再生成されるので含めない。
class BackupService {
  final DatabaseHelper _db;

  BackupService(this._db);

  static const int _formatVersion = 1;

  /// バックアップJSONを生成する
  Future<Map<String, dynamic>> buildBackup() async {
    final db = await _db.database;
    final prefs = await SharedPreferences.getInstance();

    final progress = await db.query('learning_progress');
    final stats = await db.query('daily_stats');

    return {
      'format_version': _formatVersion,
      'app_version': AppConstants.appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'learning_progress': progress,
      'daily_stats': stats,
      'preferences': {
        AppConstants.keyStreakCount:
            prefs.getInt(AppConstants.keyStreakCount) ?? 0,
        AppConstants.keyLastStudyDate:
            prefs.getString(AppConstants.keyLastStudyDate),
        AppConstants.keyNewCardsPerDay:
            prefs.getInt(AppConstants.keyNewCardsPerDay),
        AppConstants.keyLanguageMode:
            prefs.getString(AppConstants.keyLanguageMode),
      },
    };
  }

  /// バックアップファイルを書き出して共有シートを開く。
  /// 保存先の選択（ファイルApp・AirDrop・メール等）はユーザーに委ねる。
  Future<void> exportAndShare() async {
    final backup = await buildBackup();
    final json = const JsonEncoder.withIndent('  ').convert(backup);

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(RegExp(r'[:\-]'), '');
    final file = File('${dir.path}/shipit_english_backup_$stamp.json');
    await file.writeAsString(json);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'ShipIt English backup',
      ),
    );
  }

  /// ユーザーにJSONファイルを選ばせて復元する。
  /// 復元は**上書き**（同じカードの進捗は置き換わる）。
  /// 戻り値は復元した学習進捗の件数。キャンセル時は null。
  Future<int?> importFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;

    final raw = await File(path).readAsString();
    final data = json.decode(raw) as Map<String, dynamic>;

    final version = data['format_version'] as int?;
    if (version == null || version > _formatVersion) {
      throw const FormatException('unsupported backup format');
    }

    return restore(data);
  }

  /// バックアップの中身をDB/設定に書き戻す
  Future<int> restore(Map<String, dynamic> data) async {
    final db = await _db.database;
    final prefs = await SharedPreferences.getInstance();

    final progress = (data['learning_progress'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final stats =
        (data['daily_stats'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    await db.transaction((txn) async {
      for (final row in progress) {
        // 現在のカードに存在しない card_id は無視される（外部キー相当の整合性）
        await txn.insert(
          'learning_progress',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in stats) {
        await txn.insert(
          'daily_stats',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    final p = data['preferences'] as Map<String, dynamic>? ?? {};
    final streak = p[AppConstants.keyStreakCount];
    if (streak is int) {
      await prefs.setInt(AppConstants.keyStreakCount, streak);
    }
    final lastStudy = p[AppConstants.keyLastStudyDate];
    if (lastStudy is String) {
      await prefs.setString(AppConstants.keyLastStudyDate, lastStudy);
    }
    final perDay = p[AppConstants.keyNewCardsPerDay];
    if (perDay is int) {
      await prefs.setInt(AppConstants.keyNewCardsPerDay, perDay);
    }
    final lang = p[AppConstants.keyLanguageMode];
    if (lang is String) {
      await prefs.setString(AppConstants.keyLanguageMode, lang);
    }

    debugPrint('[BackupService] restored ${progress.length} progress rows');
    return progress.length;
  }
}
