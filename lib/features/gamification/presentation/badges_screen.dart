import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/domain/badges.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';
import 'package:ship_it_english/features/gamification/providers/gamification_providers.dart';
import 'package:ship_it_english/features/gamification/providers/badges_providers.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';

/// バッジ（実績）一覧画面。獲得済みはカラー＋獲得日、未獲得はグレー＋条件。
/// 「次のバッジまであと少し」を見せて中長期の継続動機を作る。
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final mode = ref.watch(languageModeProvider);
    final earned = ref.watch(earnedBadgesProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.badgesTitle),
              const SizedBox(width: 10),
              Text(
                '${earned.length} / ${allBadges.length}',
                style: AppTheme.monoNumber.copyWith(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // 現在の称号とダッキーの進化姿（レベルアップの意味づけを見せる場所）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Consumer(builder: (context, ref, _) {
                final level = ref.watch(gamificationProvider).snapshot.level;
                final rank = rankForLevel(level);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.cardDecoration,
                  child: Row(
                    children: [
                      DuckMascot(size: 52, mood: DuckMood.happy, rank: rank),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.rankName(rank),
                            style: AppTheme.bodyText
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text('LV $level', style: AppTheme.monoLabel),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
            Expanded(
              child: GridView.builder(
          padding: AppTheme.screenPadding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: allBadges.length,
          itemBuilder: (context, i) {
            final badge = allBadges[i];
            final earnedDate = earned[badge.id];
            return _BadgeTile(
              badge: badge,
              earnedDate: earnedDate,
              mode: mode,
            );
          },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDef badge;
  final String? earnedDate;
  final LanguageMode mode;

  const _BadgeTile({
    required this.badge,
    required this.earnedDate,
    required this.mode,
  });

  bool get _earned => earnedDate != null;

  @override
  Widget build(BuildContext context) {
    final date = _earned ? DateTime.tryParse(earnedDate!) : null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _earned
              ? AppTheme.primary.withOpacity(0.55)
              : AppTheme.surfaceBorder,
          width: _earned ? 1.5 : 1,
        ),
        boxShadow: _earned ? AppTheme.cardShadow : null,
      ),
      child: Opacity(
        opacity: _earned ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              badge.name(mode),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.captionText.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _earned && date != null
                  ? DateFormat('yyyy/MM/dd').format(date)
                  : badge.desc(mode),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.captionText.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

/// 新規バッジ獲得のお祝いモーダル（elasticOut＋一覧）。
Future<void> showNewBadgesModal(
  BuildContext context, {
  required List<BadgeDef> badges,
  required AppStrings strings,
  required LanguageMode mode,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'new-badges',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, _, __) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) {
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeIn,
      );
      return ScaleTransition(
        scale: scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.heroShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.newBadgeTitle,
                  style: AppTheme.bodyText
                      .copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 14),
                for (final b in badges) ...[
                  Row(
                    children: [
                      Text(b.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name(mode),
                              style: AppTheme.bodyText
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(b.desc(mode), style: AppTheme.captionText),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.continueButton),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
