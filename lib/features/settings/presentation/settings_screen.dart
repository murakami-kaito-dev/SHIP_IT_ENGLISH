import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/database/seed_data.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/providers/progress_refresh.dart';
import 'package:ship_it_english/core/services/backup_service.dart';
import 'package:ship_it_english/core/services/notification_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final strings = ref.watch(stringsProvider);
    final mode = ref.watch(languageModeProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          _SectionHeader(strings.sectionLanguage),
          // 表示言語 / 学習モード
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(strings.languageLabel, style: AppTheme.bodyText),
                ),
                SegmentedButton<LanguageMode>(
                  segments: const [
                    ButtonSegment(
                      value: LanguageMode.ja,
                      label: Text('日本語'),
                    ),
                    ButtonSegment(
                      value: LanguageMode.en,
                      label: Text('English'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(languageModeProvider.notifier)
                        .setMode(selection.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ShipIt Pro（サブスク有効時のみ表示）
          if (MonetizationConfig.subscriptionEnabled) ...[
            _SectionHeader(strings.proSection),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius:
                    BorderRadius.circular(AppTheme.cardBorderRadius),
                border: AppTheme.cardBorder,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      isPro
                          ? Icons.verified
                          : Icons.workspace_premium_outlined,
                      color: isPro
                          ? AppTheme.ratingRemembered
                          : AppTheme.ratingUncertain,
                    ),
                    title: Text(
                      isPro ? strings.proStatusActive : strings.proStatusFree,
                      style: AppTheme.bodyText,
                    ),
                    trailing: isPro
                        ? null
                        : Text(
                            strings.upgradeToPro,
                            style: AppTheme.bodyText.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    onTap: isPro ? null : () => context.push('/paywall'),
                  ),
                  // 購読中はプラン変更・解約の導線を必ず出す
                  // （App Store Review Guideline 3.1.2 の要件）
                  if (isPro) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.manage_accounts_outlined,
                          color: AppTheme.textSecondary),
                      title: Text(strings.manageSubscription,
                          style: AppTheme.bodyText),
                      subtitle: Text(strings.manageSubscriptionDesc,
                          style: AppTheme.captionText),
                      trailing: const Icon(Icons.open_in_new,
                          size: 16, color: AppTheme.textTertiary),
                      onTap: () => _openUrl(
                          MonetizationConfig.manageSubscriptionsUrl),
                    ),
                  ],
                  // 復元はパウォールに入らなくても実行できる必要がある
                  // （再インストール直後は全カテゴリがロックされて詰むため）
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore,
                        color: AppTheme.textSecondary),
                    title: Text(strings.restorePurchases,
                        style: AppTheme.bodyText),
                    subtitle: Text(strings.restorePurchasesDesc,
                        style: AppTheme.captionText),
                    onTap: () => _restorePurchases(context, ref, strings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 「1日の新規カード数」設定はホーム画面の「今日のセッション」内に移動した
          // （新規の枚数表示のすぐ近くで調整できるようにするため）
          _SectionHeader(strings.sectionNotification),

          // リマインダー通知
          Container(
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(strings.dailyReminder, style: AppTheme.bodyText),
                  value: settings.reminderEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (v) async {
                    if (v) {
                      final granted =
                          await NotificationService().requestPermission();
                      if (!granted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.notifPermissionRequired),
                          ),
                        );
                        return;
                      }
                    }
                    await notifier.setReminderEnabled(v);
                  },
                ),
                if (settings.reminderEnabled)
                  ListTile(
                    title: Text(strings.reminderTime, style: AppTheme.bodyText),
                    trailing: Text(
                      '${settings.reminderHour.toString().padLeft(2, '0')}:'
                      '${settings.reminderMinute.toString().padLeft(2, '0')}',
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: settings.reminderHour,
                          minute: settings.reminderMinute,
                        ),
                      );
                      if (time != null) {
                        await notifier.setReminderTime(time.hour, time.minute);
                      }
                    },
                  )
                else
                  ListTile(
                    title: Text(
                      strings.reminderTime,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    trailing: Text(
                      '${settings.reminderHour.toString().padLeft(2, '0')}:'
                      '${settings.reminderMinute.toString().padLeft(2, '0')}',
                      style: AppTheme.captionText,
                    ),
                    enabled: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(strings.sectionData),

          // バックアップ / 復元 / リセット
          Container(
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                // 学習履歴は端末内にしか無いので、機種変更前の書き出し手段を用意する
                ListTile(
                  leading: const Icon(Icons.ios_share,
                      color: AppTheme.textSecondary),
                  title:
                      Text(strings.backupExport, style: AppTheme.bodyText),
                  subtitle: Text(strings.backupExportDesc,
                      style: AppTheme.captionText),
                  onTap: () => _exportBackup(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined,
                      color: AppTheme.textSecondary),
                  title:
                      Text(strings.backupImport, style: AppTheme.bodyText),
                  subtitle: Text(strings.backupImportDesc,
                      style: AppTheme.captionText),
                  onTap: () => _importBackup(context, ref, strings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    strings.resetData,
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(
                    strings.resetDataSubtitle,
                    style: AppTheme.captionText,
                  ),
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'ShipIt English v${AppConstants.appVersion}',
              style: AppTheme.captionText,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 設定画面からの購入復元。
  /// 復元が成功すると entitlementProvider が true になるので、それを見て
  /// 成功/該当なしを出し分ける。
  Future<void> _restorePurchases(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(purchaseServiceProvider).restore();

    // 復元結果は purchaseStream 経由で非同期に届くため少し待つ
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;

    final isPro = ref.read(entitlementProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isPro ? strings.restoreSuccess : strings.restoreNotFound,
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await BackupService(db).exportAndShare();
  }

  /// バックアップの復元。上書きになるので必ず確認を挟む。
  Future<void> _importBackup(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.backupImportConfirmTitle),
        content: Text(strings.backupImportConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.backupImport),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    try {
      final count = await BackupService(db).importFromFile();
      if (count == null) return; // ファイル選択をキャンセル

      invalidateProgressProviders(ref);
      messenger.showSnackBar(
        SnackBar(content: Text(strings.cardsCount(count))),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.backupImportFailed)),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.resetConfirmTitle),
        content: Text(strings.resetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              strings.resetAction,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final repo = ref.read(cardRepositoryProvider) as LocalCardRepository;
    await repo.resetAllData();

    // 再シード
    final db = ref.read(databaseProvider);
    await SeedData(db).seed();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.resetDone)),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTheme.captionText.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
