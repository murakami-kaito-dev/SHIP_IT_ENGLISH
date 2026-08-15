import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/features/study/domain/units.dart';

/// クリア済みユニットの集合（要素は `categoryId:unitIndex`）。
/// prefs に文字列リストで永続化する。
class ClearedUnitsNotifier extends StateNotifier<Set<String>> {
  ClearedUnitsNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(AppConstants.keyClearedUnits) ?? const [];
    state = list.toSet();
  }

  bool isCleared(String categoryId, int unitIndex) =>
      state.contains(unitKey(categoryId, unitIndex));

  Future<void> markCleared(String categoryId, int unitIndex) async {
    final key = unitKey(categoryId, unitIndex);
    if (state.contains(key)) return;
    state = {...state, key};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.keyClearedUnits, state.toList());
  }
}

final clearedUnitsProvider =
    StateNotifierProvider<ClearedUnitsNotifier, Set<String>>(
  (ref) => ClearedUnitsNotifier(),
);
