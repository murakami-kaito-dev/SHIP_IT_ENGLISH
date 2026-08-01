import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';
import 'package:url_launcher/url_launcher.dart';

/// ShipIt Pro のパウォール（購入画面）。
/// subscriptionEnabled = false の間はどこからも遷移されない（保険として
/// 無効時に開かれた場合は「準備中」を表示する）。
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  _PaywallStrings get _t =>
      _PaywallStrings.of(ref.read(languageModeProvider));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    final service = ref.read(purchaseServiceProvider);
    service.onError = (msg) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _error = msg;
        });
      }
    };
    await service.init();

    if (!await service.isAvailable()) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _t.storeUnavailable;
        });
      }
      return;
    }

    final products = await service.loadProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _loading = false;
        if (products.isEmpty) _error = _t.storeUnavailable;
      });
    }
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() {
      _purchasing = true;
      _error = null;
    });
    await ref.read(purchaseServiceProvider).buy(product);
    // 結果は purchaseStream → entitlementProvider 経由で反映される
    if (mounted) setState(() => _purchasing = false);
  }

  Future<void> _restore() async {
    setState(() => _error = null);
    await ref.read(purchaseServiceProvider).restore();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;

    // 購入/復元が成功したら完了表示して閉じる
    ref.listen<bool>(entitlementProvider, (prev, next) {
      if (next && context.canPop()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.purchaseSuccess)),
        );
        context.pop();
      }
    });

    if (!MonetizationConfig.subscriptionEnabled) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(t.notAvailable, style: AppTheme.bodyText)),
      );
    }

    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🚢', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(t.title,
                  style: AppTheme.headingLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(t.subtitle,
                  style: AppTheme.bodyText, textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Pro特典リスト
              Container(
                padding: AppTheme.cardPadding,
                decoration: AppTheme.cardDecoration,
                child: Column(
                  children: [
                    for (final feature in t.features)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppTheme.ratingRemembered, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child:
                                  Text(feature, style: AppTheme.bodyText),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // プラン
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                for (final product in _products) ...[
                  _PlanCard(
                    product: product,
                    strings: t,
                    highlighted:
                        product.id == MonetizationConfig.yearlyProductId,
                    onTap: _purchasing ? null : () => _buy(product),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: AppTheme.captionText
                      .copyWith(color: AppTheme.ratingForgot),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),

              TextButton(
                onPressed: _restore,
                child: Text(t.restore),
              ),
              const SizedBox(height: 8),
              Text(
                t.autoRenewNote,
                style: AppTheme.captionText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () =>
                        _openUrl(MonetizationConfig.termsOfUseUrl),
                    child: Text(t.terms, style: AppTheme.captionText),
                  ),
                  TextButton(
                    onPressed: () =>
                        _openUrl(MonetizationConfig.privacyPolicyUrl),
                    child: Text(t.privacy, style: AppTheme.captionText),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ProductDetails product;
  final _PaywallStrings strings;
  final bool highlighted;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.product,
    required this.strings,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isYearly = product.id == MonetizationConfig.yearlyProductId;
    final borderRadius = BorderRadius.circular(AppTheme.cardBorderRadius);

    return Material(
      color: highlighted ? AppTheme.primaryLight : AppTheme.surface,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: highlighted ? AppTheme.primary : AppTheme.surfaceBorder,
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isYearly ? strings.yearlyPlan : strings.monthlyPlan,
                      style: AppTheme.headingMedium,
                    ),
                    if (isYearly)
                      Text(strings.trialNote, style: AppTheme.captionText),
                  ],
                ),
              ),
              Text(
                product.price,
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// パウォール専用の文言（オンボーディングと同様、この画面でしか使わないため
/// AppStrings ではなくローカル定義にしている）
class _PaywallStrings {
  final String title;
  final String subtitle;
  final List<String> features;
  final String yearlyPlan;
  final String monthlyPlan;
  final String trialNote;
  final String restore;
  final String purchaseSuccess;
  final String storeUnavailable;
  final String autoRenewNote;
  final String terms;
  final String privacy;
  final String notAvailable;

  const _PaywallStrings({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.yearlyPlan,
    required this.monthlyPlan,
    required this.trialNote,
    required this.restore,
    required this.purchaseSuccess,
    required this.storeUnavailable,
    required this.autoRenewNote,
    required this.terms,
    required this.privacy,
    required this.notAvailable,
  });

  static const ja = _PaywallStrings(
    title: 'ShipIt Pro',
    subtitle: 'すべてのカテゴリと機能を解放して\n学習を加速しましょう',
    features: [
      '全11カテゴリ・全カードを解放（面接・障害対応・キャリア・リモート等）',
      '新規カードを1日20枚まで学習',
      'カテゴリ集中学習（面接前の追い込みに）',
      '今後追加されるカードパック・新機能もすべて利用可能',
    ],
    yearlyPlan: '年額プラン',
    monthlyPlan: '月額プラン',
    trialNote: '7日間の無料トライアル付き',
    restore: '購入を復元',
    purchaseSuccess: 'ShipIt Pro へようこそ！🎉',
    storeUnavailable: 'ストアに接続できませんでした。時間をおいて再度お試しください。',
    autoRenewNote: 'サブスクリプションは自動更新されます。'
        '期間終了の24時間前までに App Store の設定から解約しない限り、自動的に更新されます。',
    terms: '利用規約',
    privacy: 'プライバシーポリシー',
    notAvailable: 'この機能は現在準備中です',
  );

  static const en = _PaywallStrings(
    title: 'ShipIt Pro',
    subtitle: 'Unlock every category and feature\nto accelerate your learning',
    features: [
      'All 11 categories and cards (Interview, Incident, Career, Remote...)',
      'Up to 20 new cards per day',
      'Category-focused study sessions',
      'All future card packs and features included',
    ],
    yearlyPlan: 'Yearly',
    monthlyPlan: 'Monthly',
    trialNote: 'Includes 7-day free trial',
    restore: 'Restore Purchases',
    purchaseSuccess: 'Welcome to ShipIt Pro! 🎉',
    storeUnavailable:
        'Could not connect to the store. Please try again later.',
    autoRenewNote: 'Subscriptions renew automatically unless canceled in your '
        'App Store settings at least 24 hours before the end of the period.',
    terms: 'Terms of Use',
    privacy: 'Privacy Policy',
    notAvailable: 'This feature is not available yet',
  );

  static _PaywallStrings of(LanguageMode mode) =>
      mode == LanguageMode.ja ? ja : en;
}
