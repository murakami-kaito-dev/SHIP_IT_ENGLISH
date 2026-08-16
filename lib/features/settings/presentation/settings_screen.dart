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
import 'package:ship_it_english/core/providers/notification_permission_provider.dart';
import 'package:ship_it_english/core/providers/progress_refresh.dart';
import 'package:ship_it_english/core/services/backup_service.dart';
import 'package:ship_it_english/core/services/notification_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/home/providers/home_providers.dart';
import 'package:ship_it_english/features/settings/providers/settings_providers.dart';
import 'package:ship_it_english/features/study/data/local_card_repository.dart';
import 'package:ship_it_english/shared/widgets/edge_widgets.dart';
import 'package:ship_it_english/shared/widgets/new_cards_setting.dart';
import 'package:ship_it_english/shared/widgets/wheel_time_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// iOSの「設定 > このアプリ」を開く。
///
/// `app-settings:` は canLaunchUrl が false を返すことがあるため、判定せずに
/// そのまま launchUrl を呼ぶ（失敗は例外で拾う）。
Future<void> openSystemNotificationSettings(
  BuildContext context,
  WidgetRef ref,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final strings = ref.read(stringsProvider);
  try {
    final ok = await launchUrl(
      Uri.parse('app-settings:'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.notifOpenSettingsFailed)),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(strings.notifOpenSettingsFailed)),
    );
  }
}

/// OSの通知が切られているときに通知セクションの先頭へ出す警告バナー。
///
/// 通知欄ごと隠さないのは、「このアプリには通知機能が無い」という誤解を
/// 生むため。オフにしたのが自分であることと、直す手段を同時に示す。
class _SystemNotificationOffBanner extends ConsumerWidget {
  const _SystemNotificationOffBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ratingUncertain.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.ratingUncertain.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notifications_off_rounded,
                size: 20,
                color: AppTheme.ratingUncertain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.notifSystemOffTitle,
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.notifSystemOffBody,
                      style: AppTheme.captionText,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => openSystemNotificationSettings(context, ref),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(strings.notifOpenSettings),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// 親トグルに従属する行を、開閉アニメーション付きで出し入れする。
///
/// 灰色にして並べたままだと「オフの項目」に見えるだけで従属関係が伝わらない。
/// 畳んで消える動きにすることで「この行は上のトグルにぶら下がっている」と
/// 分かるようにしている。
class _CollapsibleSection extends StatelessWidget {
  final bool expanded;
  final Widget child;

  const _CollapsibleSection({required this.expanded, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: expanded ? 1.0 : 0.0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: expanded ? 1.0 : 0.0,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 「通知時刻」行。親（毎日のリマインダー）の子であることを、
/// 左の余白・縦のつなぎ線・一段落とした文字色で示す。
class _ReminderTimeRow extends ConsumerWidget {
  final int hour;
  final int minute;
  final VoidCallback onTap;

  const _ReminderTimeRow({
    required this.hour,
    required this.minute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final time = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 16, 14),
          child: Row(
            children: [
              // 親からぶら下がっていることを示す縦線
              Container(
                width: 2,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  strings.reminderTime,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                time,
                style: AppTheme.monoNumber.copyWith(color: AppTheme.primary),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final strings = ref.watch(stringsProvider);
    final mode = ref.watch(languageModeProvider);
    final isPro = ref.watch(isProProvider);
    // OSの通知許可。app.dart がフォアグラウンド復帰のたびに更新するので、
    // 設定アプリでオンにして戻ってくれば即座にバナーが消える。
    final systemNotifEnabled = ref.watch(notificationPermissionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          _SectionHeader(strings.sectionLanguage),
          // 学習モード（言語を切り替えると「学ぶ言語」が変わることを明示）
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.languageLabel,
                        style: AppTheme.bodyText
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    EdgeChips<LanguageMode>(
                      expanded: false,
                      items: const [
                        EdgeChipItem(LanguageMode.ja, '日本語'),
                        EdgeChipItem(LanguageMode.en, 'English'),
                      ],
                      selected: mode,
                      onChanged: (selection) {
                        ref
                            .read(languageModeProvider.notifier)
                            .setMode(selection);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 選択中のモードで「何を学ぶか」を説明（ただ表示が変わるだけではない）
                Text(
                  strings.languageModeDescription,
                  style: AppTheme.captionText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 学習：新規カードの1日上限（1〜上限）＋クイズ出題トグル
          _SectionHeader(strings.sectionStudy),
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: NewCardsSetting(
              maxValue: AppConstants.maxNewCardsSetting,
              // 「今日への影響」をライブ表示するため、今日の新規学習数を渡す
              todayStudiedNew: ref
                  .watch(dailySessionInfoProvider)
                  .asData
                  ?.value
                  .newCardsStudiedToday,
            ),
          ),
          const SizedBox(height: 12),
          // 復習のクイズ形式出題（既定オン。フリップだけで復習したい人向け）
          Container(
            decoration: AppTheme.cardDecoration,
            child: SwitchListTile(
              title: Text(strings.quizToggleTitle, style: AppTheme.bodyText),
              subtitle: Text(strings.quizToggleDesc,
                  style: AppTheme.captionText),
              value: settings.quizEnabled,
              activeColor: AppTheme.primary,
              onChanged: (v) => notifier.setQuizEnabled(v),
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

          // OSの通知許可が切られている間は、トグルを触っても1通も届かない。
          // 「オンなのに鳴らない」を避けるため、警告と復帰導線を先頭に出し、
          // 下のトグル群は非活性にする（値は保持したまま灰色で見せる。
          // OSをオンに戻したときに以前の設定がそのまま復活するようにするため）。
          if (!systemNotifEnabled) ...[
            const _SystemNotificationOffBanner(),
            const SizedBox(height: 12),
          ],

          // リマインダー通知
          Container(
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    strings.dailyReminder,
                    style: AppTheme.bodyText.copyWith(
                      color: systemNotifEnabled ? null : AppTheme.textTertiary,
                    ),
                  ),
                  value: settings.reminderEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: systemNotifEnabled
                      ? (v) async {
                          if (v && !await _ensurePermission(context, ref)) {
                            return;
                          }
                          await notifier.setReminderEnabled(v);
                        }
                      : null,
                ),
                // 通知時刻はリマインダーの「子」。オフのときは畳んで消し、
                // オンのときだけ現れることで従属関係を動きで伝える
                // （並べて灰色表示だと対等な2項目に見えてしまう）。
                _CollapsibleSection(
                  expanded: settings.reminderEnabled && systemNotifEnabled,
                  child: _ReminderTimeRow(
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute,
                    onTap: () async {
                      final time = await showWheelTimePicker(
                        context: context,
                        strings: strings,
                        initialHour: settings.reminderHour,
                        initialMinute: settings.reminderMinute,
                      );
                      if (time != null) {
                        await notifier.setReminderTime(time.hour, time.minute);
                      }
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // ストリーク危機通知。定時リマインダーとは独立に切り替えられる
                // （毎朝の通知は不要でも、途切れそうな日だけは欲しい層がいる）。
                SwitchListTile(
                  title: Text(
                    strings.streakReminder,
                    style: AppTheme.bodyText.copyWith(
                      color: systemNotifEnabled ? null : AppTheme.textTertiary,
                    ),
                  ),
                  subtitle: Text(
                    strings.streakReminderDesc,
                    style: AppTheme.captionText,
                  ),
                  value: settings.streakReminderEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: systemNotifEnabled
                      ? (v) async {
                          if (v && !await _ensurePermission(context, ref)) {
                            return;
                          }
                          await notifier.setStreakReminderEnabled(v);
                        }
                      : null,
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

  /// 通知トグルをオンにする前にOSの許可を確保する。
  ///
  /// iOS は一度拒否されると `requestPermissions()` がダイアログを出さずに即
  /// false を返す。そのまま「許可が必要です」と出しても直す方法がなく袋小路に
  /// なるので、要求済みの場合は設定アプリへの導線を出す。
  Future<bool> _ensurePermission(BuildContext context, WidgetRef ref) async {
    final service = NotificationService();
    if (await service.isSystemNotificationEnabled()) return true;

    final alreadyAsked = await service.hasRequestedPermission();

    if (!alreadyAsked) {
      final granted = await service.requestPermission();
      await ref.read(notificationPermissionProvider.notifier).refresh();
      if (granted) return true;
      if (context.mounted) {
        final strings = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.notifPermissionRequired)),
        );
      }
      return false;
    }

    if (context.mounted) {
      await _confirmOpenSystemSettings(context, ref);
    }
    return false;
  }

  /// 「OSの通知がオフです → 設定を開きますか？」の確認ダイアログ。
  Future<void> _confirmOpenSystemSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final strings = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.notifSystemOffTitle),
        content: Text(strings.notifSystemOffBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.notifOpenSettings),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await openSystemNotificationSettings(context, ref);
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
