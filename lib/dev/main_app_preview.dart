import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/app.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/database/database_helper.dart';
import 'package:ship_it_english/core/database/seed_data.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';

/// 【開発専用】本体アプリを「通知の許可要求なし・オンボーディング省略」で起動する
/// エントリポイント。シミュレータでの見た目確認用（OSの許可アラートは simctl から
/// タップできず、目視検証をブロックするため）。本番の起動フローは main.dart。
///
///   flutter run -t lib/dev/main_app_preview.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  await dbHelper.initialize();
  await SeedData(dbHelper).seed();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(AppConstants.keyOnboardingDone, true);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(dbHelper),
        languageModeProvider.overrideWith(
          (ref) => LanguageModeNotifier(LanguageMode.ja),
        ),
      ],
      child: const ShipItEnglishApp(showOnboarding: false),
    ),
  );
}
