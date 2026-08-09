import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/providers/progress_refresh.dart';
import 'package:ship_it_english/core/services/tts_service.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/study/domain/models/card_model.dart';
import 'package:ship_it_english/features/study/domain/models/learning_progress.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';
import 'package:ship_it_english/shared/widgets/card_number_label.dart';

/// カード詳細のボトムシート（カテゴリ詳細・検索から共用）。
/// 学習状況をその場で変更でき、変更は即座に裏の一覧にも反映される
/// （`invalidateProgressProviders` が一覧プロバイダーを無効化するため、
/// 呼び出し元で戻り値を扱う必要はない）。
Future<void> showCardDetailSheet({
  required BuildContext context,
  required TechCard card,
  required Rating? rating,
  required AppStrings strings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CardDetailSheet(card: card, initialRating: rating),
  );
}

class _CardDetailSheet extends ConsumerStatefulWidget {
  final TechCard card;
  final Rating? initialRating;

  const _CardDetailSheet({required this.card, required this.initialRating});

  @override
  ConsumerState<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends ConsumerState<_CardDetailSheet> {
  late Rating? _rating = widget.initialRating;
  bool _saving = false;

  /// 詳細画面から評価する。学習セッションと同じ SRS エンジンを通すので、
  /// 次回の出題タイミングにも正しく反映される。
  Future<void> _rate(Rating rating) async {
    if (_saving) return;
    setState(() => _saving = true);

    final repo = ref.read(cardRepositoryProvider);
    final srs = ref.read(srsEngineProvider);

    final current = await repo.getProgress(widget.card.id) ??
        LearningProgress.initial(widget.card.id);
    final updated = srs.processReview(current: current, rating: rating);
    await repo.saveProgress(updated);

    _applyUpdate(updated.lastRating);
  }

  /// 未学習に戻す（誤タップの取り消し用）。
  /// SRSの状態（ease_factor・間隔・回数）ごと初期化するので、
  /// 次回は新規カードとして出題される。
  Future<void> _reset() async {
    if (_saving) return;
    setState(() => _saving = true);

    final repo = ref.read(cardRepositoryProvider);
    await repo.saveProgress(LearningProgress.initial(widget.card.id));

    _applyUpdate(null);
  }

  void _applyUpdate(Rating? rating) {
    if (!mounted) return;
    setState(() {
      _rating = rating;
      _saving = false;
    });

    // 集計とカード一覧を再取得させ、裏の一覧にも即座に反映する
    invalidateProgressProviders(ref);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final card = widget.card;
    final isJa = strings.mode == LanguageMode.ja;
    final usage = isJa
        ? card.context
        : (card.contextEn.isNotEmpty ? card.contextEn : card.context);
    // 学習対象言語（読み上げ対象）: jaモード=英語 / enモード=日本語
    final speakTarget = isJa ? card.phrase : card.translation;
    final speakExample = isJa ? card.example : card.exampleTranslation;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // カテゴリ内の通し番号（例: 💬 Code Review #3）
            Text(
              cardNumberLabel(card),
              style: AppTheme.captionText.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('"${card.phrase}"', style: AppTheme.phraseText),
                ),
                CardStatusChip(rating: _rating, strings: strings),
                // jaモード（学習対象＝英語フレーズ）ではここに読み上げ
                if (isJa) ...[
                  const SizedBox(width: 4),
                  _SpeakerButton(
                    onTap: () =>
                        TtsService().speakTarget(speakTarget, strings.mode),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child:
                      Text(card.translation, style: AppTheme.translationText),
                ),
                // enモード（学習対象＝日本語訳）ではここに読み上げ
                if (!isJa)
                  _SpeakerButton(
                    onTap: () =>
                        TtsService().speakTarget(speakTarget, strings.mode),
                  ),
              ],
            ),
            const Divider(height: 32),
            Text(
              strings.exampleLabel,
              style: AppTheme.captionText.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            // 例文も学習カードと同様に読み上げできるようにする
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '"${card.example}"',
                    style:
                        AppTheme.bodyText.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                // jaモード（学習対象＝英語例文）ではここに読み上げ
                if (isJa)
                  _SpeakerButton(
                    onTap: () =>
                        TtsService().speakTarget(speakExample, strings.mode),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child:
                      Text(card.exampleTranslation, style: AppTheme.bodyText),
                ),
                // enモード（学習対象＝日本語例文）ではここに読み上げ
                if (!isJa)
                  _SpeakerButton(
                    onTap: () =>
                        TtsService().speakTarget(speakExample, strings.mode),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              strings.usageLabel,
              style: AppTheme.captionText.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(usage, style: AppTheme.bodyText),

            // === 学習状況の変更 ===
            const Divider(height: 32),
            Text(
              strings.updateStatusLabel,
              style: AppTheme.captionText.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _RateButton(
                    label: strings.ratingForgot,
                    icon: Icons.close,
                    color: AppTheme.ratingForgot,
                    enabled: !_saving,
                    selected: _rating == Rating.forgot,
                    onTap: () => _rate(Rating.forgot),
                  ),
                ),
                const SizedBox(width: AppTheme.ratingButtonSpacing),
                Expanded(
                  child: _RateButton(
                    label: strings.ratingUncertain,
                    icon: Icons.remove,
                    color: AppTheme.ratingUncertain,
                    enabled: !_saving,
                    selected: _rating == Rating.uncertain,
                    onTap: () => _rate(Rating.uncertain),
                  ),
                ),
                const SizedBox(width: AppTheme.ratingButtonSpacing),
                Expanded(
                  child: _RateButton(
                    label: strings.ratingRemembered,
                    icon: Icons.check_circle_outline,
                    color: AppTheme.ratingRemembered,
                    enabled: !_saving,
                    selected: _rating == Rating.remembered,
                    onTap: () => _rate(Rating.remembered),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 誤タップの取り消し用。押すと未学習の状態に戻る
            SizedBox(
              width: double.infinity,
              child: _RateButton(
                label: strings.resetToNotStudied,
                icon: Icons.undo,
                color: AppTheme.textTertiary,
                enabled: !_saving && _rating != null,
                selected: _rating == null,
                onTap: _reset,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 読み上げボタン（フレーズ・例文で共用）
class _SpeakerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SpeakerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Play audio',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.volume_up_outlined,
            size: 22,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;

  /// 現在の学習状況と一致しているか（塗りつぶしで示す）
  final bool selected;
  final VoidCallback onTap;

  const _RateButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        BorderRadius.circular(AppTheme.ratingButtonBorderRadius);
    final foreground = selected ? Colors.white : color;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: selected ? color : color.withOpacity(0.12),
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: enabled ? onTap : null,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.buttonText
                        .copyWith(color: foreground, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 学習状況のチップ表示（一覧・詳細シートで共用）。
/// 評価ボタンと同じ語彙（忘れた/曖昧/覚えてた）で表示し、
/// 未評価のカードだけ「未学習」とする。
class CardStatusChip extends StatelessWidget {
  final Rating? rating;
  final AppStrings strings;

  const CardStatusChip({super.key, required this.rating, required this.strings});

  (String, Color) get _display => switch (rating) {
        null => (strings.statusNew, AppTheme.textTertiary),
        Rating.forgot => (strings.ratingForgot, AppTheme.ratingForgot),
        Rating.uncertain =>
          (strings.ratingUncertain, AppTheme.ratingUncertain),
        Rating.remembered =>
          (strings.ratingRemembered, AppTheme.ratingRemembered),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _display;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.captionText.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
