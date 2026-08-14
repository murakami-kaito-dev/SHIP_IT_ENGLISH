import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/services/notification_service.dart';
import 'package:ship_it_english/core/utils/date_utils.dart';

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

  /// ストリーク危機通知（未学習の日だけ23:00）のオン/オフ。
  /// 定時リマインダー [reminderEnabled] とは独立。片方だけ残す選択ができる。
  final bool streakReminderEnabled;
  final StudyScope studyScope;

  const SettingsState({
    required this.newCardsPerDay,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.streakReminderEnabled,
    required this.studyScope,
  });

  SettingsState copyWith({
    int? newCardsPerDay,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? streakReminderEnabled,
    StudyScope? studyScope,
  }) {
    return SettingsState(
      newCardsPerDay: newCardsPerDay ?? this.newCardsPerDay,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      streakReminderEnabled:
          streakReminderEnabled ?? this.streakReminderEnabled,
      studyScope: studyScope ?? this.studyScope,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref)
    : super(
        const SettingsState(
          newCardsPerDay: AppConstants.defaultNewCardsPerDay,
          reminderEnabled: true,
          reminderHour: AppConstants.defaultReminderHour,
          reminderMinute: AppConstants.defaultReminderMinute,
          streakReminderEnabled: true,
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
      streakReminderEnabled:
          prefs.getBool(AppConstants.keyStreakReminderEnabled) ?? true,
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

  /// ストリーク危機通知のオン/オフ。
  ///
  /// オフ時は [NotificationService.scheduleStreakReminders] が7日分をまとめて
  /// キャンセルする。積んである予約を消さないと、切ったあとも最長7日間鳴り続ける。
  Future<void> setStreakReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyStreakReminderEnabled, value);
    state = state.copyWith(streakReminderEnabled: value);

    final service = NotificationService();
    await service.scheduleStreakReminders();

    // 再オンにすると今日の23:00分も積み直されるため、学習済みの日は
    // その場で当日分を消す（main.dart の起動時処理と同じ扱いにする）。
    if (value) {
      final studiedToday = await _ref
          .read(cardRepositoryProvider)
          .hasStudiedToday(DateTime.now().toDateString());
      if (studiedToday) {
        await service.cancelStreakReminderForToday();
      }
    }
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
      return SettingsNotifier(ref);
    });
