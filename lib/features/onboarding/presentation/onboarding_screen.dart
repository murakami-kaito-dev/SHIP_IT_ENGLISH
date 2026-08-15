import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/core/providers/core_providers.dart';
import 'package:ship_it_english/features/onboarding/providers/placement_providers.dart';
import 'package:ship_it_english/features/study/domain/skill_score.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';
import 'package:ship_it_english/shared/widgets/new_cards_setting.dart';

/// 初回起動時のオンボーディング。
/// 1ページ目で学習モード（日本語話者/英語話者）を選び、
/// 2〜3ページ目で選択した言語で使い方を説明する。
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  /// 初期診断で「知ってる」と選んだカードID。
  final Set<String> _knownIds = {};

  /// 二重タップで診断の反映が重複しないためのガード。
  bool _applying = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _selectMode(LanguageMode mode) async {
    await ref.read(languageModeProvider.notifier).setMode(mode);
    _next();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    if (mounted) context.go('/');
  }

  /// 初期診断の「知ってる」を学習進捗に反映してから完了する。
  /// 知っているカードは復習状態（7日後）としてSRSに乗り、新規キューを飛ばす。
  Future<void> _applyPlacementAndFinish() async {
    if (_applying) return;
    _applying = true;
    try {
      final repo = ref.read(cardRepositoryProvider);
      final now = DateTime.now();
      for (final id in _knownIds) {
        await repo.saveProgress(placementKnownProgress(id, now));
      }
    } catch (_) {
      // 診断の反映に失敗してもオンボーディングは完了させる（学習で追いつける）
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(languageModeProvider);
    final isJa = mode == LanguageMode.ja;

    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildLanguagePage(),
                  _buildHowToPage(isJa),
                  _buildSrsPage(isJa),
                  _buildNewCardsPage(isJa),
                  _buildPlacementPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _page == i
                          ? AppTheme.primary
                          : AppTheme.surfaceBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // === Page 1: 言語モード選択（選択前なのでバイリンガル表記） ===
  Widget _buildLanguagePage() {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🚢', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'ShipIt English',
            style: AppTheme.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'あなたに合ったモードを選んでください\nChoose your mode',
            style: AppTheme.bodyText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _ModeCard(
            emoji: '🇯🇵',
            title: '日本語',
            subtitle: '現場で使う技術英語を学びたい',
            onTap: () => _selectMode(LanguageMode.ja),
          ),
          const SizedBox(height: 16),
          _ModeCard(
            emoji: '🇺🇸',
            title: 'English',
            subtitle: 'I want to learn workplace Japanese for engineers',
            onTap: () => _selectMode(LanguageMode.en),
          ),
        ],
      ),
    );
  }

  // === Page 2: 学習の仕方 ===
  Widget _buildHowToPage(bool isJa) {
    return _InfoPage(
      emoji: '👆',
      title: isJa ? 'タップしてめくる' : 'Tap to flip',
      items: isJa
          ? const [
              ('🃏', 'カードをタップすると答えが表示されます'),
              ('🎯', '「忘れた・曖昧・覚えてた」の3段階で自己評価します'),
              ('👉', '左右スワイプでも評価できます（左=忘れた / 右=覚えてた）'),
              ('🔊', 'スピーカーアイコンで発音を聞けます'),
            ]
          : const [
              ('🃏', 'Tap a card to reveal the answer'),
              ('🎯', 'Rate yourself: Forgot / Unsure / Got it'),
              ('👉', 'You can also swipe (left = forgot / right = got it)'),
              ('🔊', 'Tap the speaker icon to hear the pronunciation'),
            ],
      buttonLabel: isJa ? '次へ' : 'Next',
      onPressed: _next,
    );
  }

  // === Page 3: SRSの説明 ===
  Widget _buildSrsPage(bool isJa) {
    return _InfoPage(
      emoji: '🧠',
      title: isJa ? '科学的な間隔反復（SRS）' : 'Spaced repetition (SRS)',
      items: isJa
          ? const [
              ('📅', '毎日「復習カード + 新規カード」が自動で出題されます'),
              ('📈', '覚えているカードは出題間隔がどんどん延びます'),
              ('🔥', '毎日続けるとストリーク（連続記録）が伸びます'),
              ('⏱', '1日たった5〜10分でOK'),
            ]
          : const [
              ('📅', 'Every day you get due reviews + a few new cards'),
              ('📈', 'Cards you know well appear less and less often'),
              ('🔥', 'Study daily to grow your streak'),
              ('⏱', 'Just 5-10 minutes a day'),
            ],
      buttonLabel: isJa ? '次へ' : 'Next',
      onPressed: _next,
    );
  }

  // === Page 4: 1日の新規カード数（1〜100・あとで設定タブで変更可） ===
  Widget _buildNewCardsPage(bool isJa) {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🎯',
              style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(isJa ? '1日の新規学習カード数' : 'New study cards per day',
              style: AppTheme.headingLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            isJa
                ? '毎日いくつ新しいカードを学ぶか決めましょう（1〜100枚）。あとで設定タブから変更できます。'
                : 'Choose how many new cards to learn each day (1–100). You can change this later in Settings.',
            style: AppTheme.bodyText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const NewCardsSetting(
              maxValue: AppConstants.maxNewCardsSetting,
              showHeading: false,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _next,
            child: Text(isJa ? '次へ' : 'Next'),
          ),
        ],
      ),
    );
  }

  // === Page 5: かんたんレベル診断（知っているフレーズを選ぶ → 開始位置に反映） ===
  Widget _buildPlacementPage() {
    final strings = ref.watch(stringsProvider);
    final cardsAsync = ref.watch(placementCardsProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('📍',
              style: TextStyle(fontSize: 44), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(strings.placementTitle,
              style: AppTheme.headingLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(strings.placementBody,
              style: AppTheme.captionText, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Expanded(
            child: cardsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (cards) => ListView.separated(
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final card = cards[i];
                  final known = _knownIds.contains(card.id);
                  return Material(
                    color: known
                        ? AppTheme.primaryLight
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => setState(() {
                        known
                            ? _knownIds.remove(card.id)
                            : _knownIds.add(card.id);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: known
                                ? AppTheme.primary
                                : AppTheme.surfaceBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              known
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 20,
                              color: known
                                  ? AppTheme.primary
                                  : AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.phrase,
                                    style: AppTheme.bodyText.copyWith(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(card.translation,
                                      style: AppTheme.captionText),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _applyPlacementAndFinish,
            child: Text(strings.placementStart),
          ),
          TextButton(
            onPressed: _finish,
            child: Text(strings.placementSkip,
                style: AppTheme.captionText),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppTheme.cardBorderRadius);
    return Material(
      color: AppTheme.surface,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          padding: AppTheme.cardPadding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: AppTheme.cardBorder,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.headingMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.captionText),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  final String emoji;
  final String title;
  final List<(String, String)> items;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _InfoPage({
    required this.emoji,
    required this.title,
    required this.items,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(emoji,
              style: const TextStyle(fontSize: 56), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.headingLarge, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.$2, style: AppTheme.bodyText),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
