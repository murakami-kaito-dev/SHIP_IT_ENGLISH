import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/services/notification_service.dart';

/// 今日のセッションで学習する範囲。
/// - [newOnly]    新規カードのみ
/// - [reviewOnly] 復習（期限が来たカード）のみ
/// - [both]       新規＋復習（既定）
enum StudyScope {
  newOnly('new'),
  reviewOnly('review'),
  both('both');

  final String value;
  const StudyScope(this.value);

  static StudyScope fromString(String? v) =>
      StudyScope.values.firstWhere((s) => s.value == v, orElse: () => StudyScope.both);
}

class SettingsState {
  final int newCardsPerDay;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final StudyScope studyScope;

  const SettingsState({
    required this.newCardsPerDay,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.studyScope,
  });

  SettingsState copyWith({
    int? newCardsPerDay,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    StudyScope? studyScope,
  }) {
    return SettingsState(
      newCardsPerDay: newCardsPerDay ?? this.newCardsPerDay,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      studyScope: studyScope ?? this.studyScope,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
    : super(
        const SettingsState(
          newCardsPerDay: AppConstants.defaultNewCardsPerDay,
          reminderEnabled: true,
          reminderHour: AppConstants.defaultReminderHour,
          reminderMinute: AppConstants.defaultReminderMinute,
          studyScope: StudyScope.both,
        ),
      ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      newCardsPerDay:
          prefs.getInt(AppConstants.keyNewCardsPerDay) ??
          AppConstants.defaultNewCardsPerDay,
      reminderEnabled:
          prefs.getBool(AppConstants.keyReminderEnabled) ?? true,
      reminderHour:
          prefs.getInt(AppConstants.keyReminderHour) ??
          AppConstants.defaultReminderHour,
      reminderMinute:
          prefs.getInt(AppConstants.keyReminderMinute) ??
          AppConstants.defaultReminderMinute,
      studyScope:
          StudyScope.fromString(prefs.getString(AppConstants.keyStudyScope)),
    );
  }

  Future<void> setStudyScope(StudyScope scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyStudyScope, scope.value);
    state = state.copyWith(studyScope: scope);
  }

  Future<void> setNewCardsPerDay(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyNewCardsPerDay, value);
    state = state.copyWith(newCardsPerDay: value);
  }

  Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyReminderEnabled, value);
    state = state.copyWith(reminderEnabled: value);
    await NotificationService().scheduleDailyReminder();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyReminderHour, hour);
    await prefs.setInt(AppConstants.keyReminderMinute, minute);
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    await NotificationService().scheduleDailyReminder();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
      return SettingsNotifier();
    });
