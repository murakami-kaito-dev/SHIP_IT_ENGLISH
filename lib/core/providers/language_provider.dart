import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';

class LanguageModeNotifier extends StateNotifier<LanguageMode> {
  LanguageModeNotifier(super.initial);

  Future<void> setMode(LanguageMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguageMode, mode.value);
  }
}

/// main.dart で保存済みモードを読み込んで override される
final languageModeProvider =
    StateNotifierProvider<LanguageModeNotifier, LanguageMode>(
  (ref) => LanguageModeNotifier(LanguageMode.ja),
);

/// 現在の言語モードに対応するUI文言
final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.of(ref.watch(languageModeProvider)),
);
